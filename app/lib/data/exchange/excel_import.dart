/// 从 Excel 导入商品与费用。
///
/// 语义（与 docs/plan/0006-excel.md 一致）：
/// - `id` 有值且本地存在 → 更新该记录
/// - `id` 有值但本地没有 → 按这个 id 新增（相当于别的设备导来的数据）
/// - `id` 为空 → 生成新 UUID
///
/// 容错：**先把整张表校验完，收集所有错误；只要有一条错就一行都不写库。**
/// 半截导入比不导入更糟——用户不知道哪些进去了、哪些没进去。
library;

import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/money.dart';
import '../db/app_database.dart';
import '../repo/item_repository.dart';
import 'excel_rows.dart';

/// 一行上的一个错误。
class ExcelRowError {
  const ExcelRowError({
    required this.sheet,
    required this.row,
    required this.message,
  });

  /// sheet 名（商品 / 费用明细）。
  final String sheet;

  /// 面向用户的 Excel 行号（从 1 开始，表头是第 1 行）。
  final int row;
  final String message;

  @override
  String toString() => '$sheet 第 $row 行：$message';
}

/// 解析结果。`errors` 为空才允许 [ExcelImportService.apply]。
class ExcelPreview {
  const ExcelPreview({
    required this.items,
    required this.expenses,
    required this.errors,
  });

  final List<ItemDraft> items;

  /// key = 商品 id，value = 该商品的费用草稿（全量替换语义）。
  final Map<String, List<ExpenseDraft>> expenses;
  final List<ExcelRowError> errors;

  bool get ok => errors.isEmpty;

  int get itemCount => items.length;

  int get expenseCount =>
      expenses.values.fold(0, (sum, list) => sum + list.length);

  /// 给确认弹窗用的一句话。
  String describe() => '将写入 $itemCount 件商品、$expenseCount 条费用';

  /// 给报错弹窗用：最多列前 20 条，剩下的折成「还有 N 条」。
  String describeErrors() {
    const max = 20;
    final buffer = StringBuffer();
    for (final error in errors.take(max)) {
      buffer.writeln('· $error');
    }
    if (errors.length > max) {
      buffer.writeln('· …… 还有 ${errors.length - max} 条');
    }
    return buffer.toString();
  }
}

class ExcelImportService {
  ExcelImportService({
    required AppDatabase db,
    required ItemRepository repository,
    Uuid uuid = const Uuid(),
  }) : _db = db,
       _repo = repository,
       _uuid = uuid;

  final AppDatabase _db;
  final ItemRepository _repo;
  final Uuid _uuid;

  final DateFormat _out = DateFormat(ExcelSchema.datePattern);

  /// 解析但不写库。用户要先看到「将写入多少、有没有错」再决定。
  Future<ExcelPreview> parse(Uint8List bytes) async {
    final workbook = Excel.decodeBytes(bytes);

    final itemSheet = _pickSheet(workbook, ExcelSchema.sheetItems);
    final errors = <ExcelRowError>[];

    if (itemSheet == null) {
      return ExcelPreview(
        items: const [],
        expenses: const {},
        errors: const [
          ExcelRowError(
            sheet: ExcelSchema.sheetItems,
            row: 1,
            message: '找不到「${ExcelSchema.sheetItems}」这张表',
          ),
        ],
      );
    }

    final itemIndex = _headerIndex(itemSheet, ExcelSchema.itemHeaders);
    // _headerIndex 对缺失列填的是 -1（不是 null），判断得看哨兵，
    // 否则这个「表头缺名称列」的分支永远走不到。
    final titleColumn = itemIndex[ExcelSchema.title] ?? -1;
    if (titleColumn < 0) {
      return ExcelPreview(
        items: const [],
        expenses: const {},
        errors: const [
          ExcelRowError(
            sheet: ExcelSchema.sheetItems,
            row: 1,
            message: '表头里缺少「${ExcelSchema.title}」列，无法确定哪一行是哪件商品',
          ),
        ],
      );
    }

    final existingIds = await _existingItemIds();
    final drafts = <ItemDraft>[];
    final idByRow = <int, String>{};
    final seenIds = <String>{};

    final rows = itemSheet.rows;
    // 第 0 行是表头，从第 1 行开始才是数据。
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (_isBlank(row)) continue;
      final excelRow = r + 1; // 给人看的行号

      final title = _cell(row, itemIndex[ExcelSchema.title]).trim();
      if (title.isEmpty) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetItems,
            row: excelRow,
            message: '「${ExcelSchema.title}」不能为空',
          ),
        );
        continue;
      }

      final rawId = _cell(row, itemIndex[ExcelSchema.id]).trim();
      final id = rawId.isEmpty ? _uuid.v4() : rawId;
      if (!seenIds.add(id)) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetItems,
            row: excelRow,
            message: 'id「$id」在表里出现了两次',
          ),
        );
      }
      idByRow[excelRow] = id;

      final buyCents = _parseCents(
        _cell(row, itemIndex[ExcelSchema.buyPrice]),
        errors,
        excelRow,
        ExcelSchema.buyPrice,
      );
      final sellCents = _parseCentsOrNull(
        _cell(row, itemIndex[ExcelSchema.sellPrice]),
        errors,
        excelRow,
        ExcelSchema.sellPrice,
      );

      final rawStatus = _cell(row, itemIndex[ExcelSchema.status]).trim();
      final status = rawStatus.isEmpty
          ? ItemStatus.inStock
          : ExcelSchema.statusFromLabel(rawStatus);
      if (status == null) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetItems,
            row: excelRow,
            message:
                '状态「$rawStatus」不认识（可用：'
                '${ItemStatus.values.map((e) => e.label).join(' / ')}）',
          ),
        );
        continue;
      }

      if (status.isRealized && sellCents == null) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetItems,
            row: excelRow,
            message: '状态是「${status.label}」，但没有填「${ExcelSchema.sellPrice}」',
          ),
        );
      }

      final buyDate = _parseDate(
        _cell(row, itemIndex[ExcelSchema.buyDate]),
        errors,
        excelRow,
        ExcelSchema.buyDate,
      );
      final sellDate = _parseDate(
        _cell(row, itemIndex[ExcelSchema.sellDate]),
        errors,
        excelRow,
        ExcelSchema.sellDate,
      );

      drafts.add(
        ItemDraft(
          id: id,
          title: title,
          category: _nullIfEmpty(_cell(row, itemIndex[ExcelSchema.category])),
          brand: _nullIfEmpty(_cell(row, itemIndex[ExcelSchema.brand])),
          model: _nullIfEmpty(_cell(row, itemIndex[ExcelSchema.model])),
          storage: _nullIfEmpty(_cell(row, itemIndex[ExcelSchema.storage])),
          color: _nullIfEmpty(_cell(row, itemIndex[ExcelSchema.color])),
          conditionBought: _nullIfEmpty(
            _cell(row, itemIndex[ExcelSchema.conditionBought]),
          ),
          conditionSold: _nullIfEmpty(
            _cell(row, itemIndex[ExcelSchema.conditionSold]),
          ),
          batteryHealth: _parsePercentOrNull(
            _cell(row, itemIndex[ExcelSchema.batteryHealth]),
            errors,
            excelRow,
          ),
          listPriceCents: _parseCentsOrNull(
            _cell(row, itemIndex[ExcelSchema.listPrice]),
            errors,
            excelRow,
            ExcelSchema.listPrice,
          ),
          tradeInCents: _parseCentsOrNull(
            _cell(row, itemIndex[ExcelSchema.tradeIn]),
            errors,
            excelRow,
            ExcelSchema.tradeIn,
          ),
          status: status,
          sourcePlatform: _nullIfEmpty(
            _cell(row, itemIndex[ExcelSchema.sourcePlatform]),
          ),
          buyDate: buyDate,
          buyPriceCents: buyCents,
          sellDate: sellDate,
          sellPriceCents: sellCents,
          sellPlatform: _nullIfEmpty(
            _cell(row, itemIndex[ExcelSchema.sellPlatform]),
          ),
          lotId: _nullIfEmpty(_cell(row, itemIndex[ExcelSchema.lotId])),
          note: _nullIfEmpty(_cell(row, itemIndex[ExcelSchema.note])),
        ),
      );

      // rawId 为空的行用一个占位 key，等费用表解析完再换成真 id。
      if (rawId.isEmpty && !existingIds.contains(id)) {
        // 新 id，无需额外动作；保留分支以便将来统计"真新增"。
      }
    }

    final expenses = await _parseExpenses(
      workbook,
      errors,
      knownIds: {...existingIds, ...drafts.map((d) => d.id!)},
    );

    return ExcelPreview(items: drafts, expenses: expenses, errors: errors);
  }

  /// 写库。必须先 [parse] 且 `preview.ok` 为真。
  ///
  /// 每件商品是一次 [ItemRepository.save]：内部是事务，费用走「全量替换」
  /// （先给旧费用打墓碑再插新的），所以重复导入同一份表不会累积重复费用。
  Future<int> apply(ExcelPreview preview) async {
    if (!preview.ok) {
      throw StateError('还有 ${preview.errors.length} 处错误，不能写入');
    }
    var written = 0;
    for (final draft in preview.items) {
      final list = preview.expenses[draft.id] ?? const <ExpenseDraft>[];
      await _repo.save(draft, list);
      written++;
    }
    return written;
  }

  // -------------------------------------------------------------------
  // 费用表
  // -------------------------------------------------------------------
  Future<Map<String, List<ExpenseDraft>>> _parseExpenses(
    Excel workbook,
    List<ExcelRowError> errors, {
    required Set<String> knownIds,
  }) async {
    final sheet = _pickSheet(workbook, ExcelSchema.sheetExpenses);
    if (sheet == null) return const {};

    final index = _headerIndex(sheet, ExcelSchema.expenseHeaders);
    final itemIdColumn = index[ExcelSchema.expenseItemId];
    if (itemIdColumn == null) {
      // 没有商品 id 列就整张跳过——费用挂不到任何商品上。
      return const {};
    }

    final idColumn = index[ExcelSchema.expenseId];
    final result = <String, List<ExpenseDraft>>{};
    final seenIds = <String>{};
    final rows = sheet.rows;
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (_isBlank(row)) continue;
      final excelRow = r + 1;

      final itemId = _cell(row, itemIdColumn).trim();
      if (itemId.isEmpty) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetExpenses,
            row: excelRow,
            message: '「${ExcelSchema.expenseItemId}」不能为空',
          ),
        );
        continue;
      }
      if (!knownIds.contains(itemId)) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetExpenses,
            row: excelRow,
            message: '找不到 id 为「$itemId」的商品',
          ),
        );
        continue;
      }

      // 费用自己的 id：有就原地覆盖，没有就当新行（旧导出文件都没有这一列）。
      final rawId = _cell(row, idColumn).trim();
      if (rawId.isNotEmpty && !seenIds.add(rawId)) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetExpenses,
            row: excelRow,
            message: "「${ExcelSchema.expenseId}」$rawId 重复了，一笔费用只能出现一次",
          ),
        );
        continue;
      }

      final rawKind = _cell(row, index[ExcelSchema.expenseKind]).trim();
      final kind = rawKind.isEmpty
          ? ExpenseKind.other
          : ExcelSchema.kindFromLabel(rawKind);
      if (kind == null) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetExpenses,
            row: excelRow,
            message:
                '费用种类「$rawKind」不认识（可用：'
                '${ExpenseKind.values.map((e) => e.label).join(' / ')}）',
          ),
        );
        continue;
      }

      final rawSide = _cell(row, index[ExcelSchema.expenseSide]).trim();
      final side = rawSide.isEmpty
          ? ExpenseSide.buy
          : ExcelSchema.sideFromLabel(rawSide);
      if (side == null) {
        errors.add(
          ExcelRowError(
            sheet: ExcelSchema.sheetExpenses,
            row: excelRow,
            message: '侧别「$rawSide」不认识（可用：买入 / 卖出）',
          ),
        );
        continue;
      }

      final amount = _parseCents(
        _cell(row, index[ExcelSchema.expenseAmount]),
        errors,
        excelRow,
        ExcelSchema.expenseAmount,
        sheet: ExcelSchema.sheetExpenses,
      );

      final incurredAt = _parseDate(
        _cell(row, index[ExcelSchema.expenseDate]),
        errors,
        excelRow,
        ExcelSchema.expenseDate,
        sheet: ExcelSchema.sheetExpenses,
      );

      result
          .putIfAbsent(itemId, () => <ExpenseDraft>[])
          .add(
            ExpenseDraft(
              id: rawId.isEmpty ? null : rawId,
              kind: kind,
              side: side,
              amountCents: amount,
              incurredAt: incurredAt,
              note: _nullIfEmpty(_cell(row, index[ExcelSchema.expenseNote])),
            ),
          );
    }
    return result;
  }

  // -------------------------------------------------------------------
  // 工具
  // -------------------------------------------------------------------

  /// 按名字取表；名字对不上时退回第一张（用户可能把 sheet 改名了）。
  Sheet? _pickSheet(Excel workbook, String name) {
    final byName = workbook.tables[name];
    if (byName != null) return byName;
    if (workbook.tables.isEmpty) return null;
    return workbook.tables.values.first;
  }

  /// 表头名 -> 列号。缺失的列不在 map 里，取值时按空串处理。
  Map<String, int> _headerIndex(Sheet sheet, List<String> expected) {
    final map = <String, int>{};
    if (sheet.rows.isEmpty) return map;
    final header = sheet.rows.first;
    for (var c = 0; c < header.length; c++) {
      final name = _cell(header, c).trim();
      if (name.isEmpty) continue;
      map.putIfAbsent(name, () => c);
    }
    // 容错：表头里多出的列不影响，缺的列靠 expected 里的名字兜底。
    for (final name in expected) {
      map.putIfAbsent(name, () => -1);
    }
    return map;
  }

  String _cell(List<Data?> row, int? column) {
    if (column == null || column < 0 || column >= row.length) return '';
    return _cellText(row[column]?.value);
  }

  String _cellText(CellValue? value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value.text ?? '';
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return _trimDouble(value.value);
    if (value is BoolCellValue) return value.value.toString();
    if (value is DateCellValue) {
      return _out.format(DateTime(value.year, value.month, value.day));
    }
    if (value is DateTimeCellValue) {
      return _out.format(
        DateTime(
          value.year,
          value.month,
          value.day,
          value.hour,
          value.minute,
          value.second,
        ),
      );
    }
    return value.toString();
  }

  /// 1234.0 写成 1234，别让金额尾巴上挂个 .0。
  String _trimDouble(double raw) {
    if (raw == raw.roundToDouble()) return raw.toInt().toString();
    return raw.toString();
  }

  bool _isBlank(List<Data?> row) {
    for (final cell in row) {
      if (_cellText(cell?.value).trim().isNotEmpty) return false;
    }
    return true;
  }

  String? _nullIfEmpty(String raw) {
    final text = raw.trim();
    return text.isEmpty ? null : text;
  }

  Future<Set<String>> _existingItemIds() async {
    final rows = await _db.select(_db.items).get();
    return rows.map((e) => e.id).toSet();
  }

  /// 买入价这类必填金额：空或非数字都记为错误，返回 0 让调用方继续收集其他错误。
  int _parseCents(
    String raw,
    List<ExcelRowError> errors,
    int excelRow,
    String column, {
    String sheet = ExcelSchema.sheetItems,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      errors.add(
        ExcelRowError(sheet: sheet, row: excelRow, message: '「$column」不能为空'),
      );
      return 0;
    }
    final money = Money.tryParseYuan(text);
    if (money == null) {
      errors.add(
        ExcelRowError(
          sheet: sheet,
          row: excelRow,
          message: '「$column」不是金额：$text',
        ),
      );
      return 0;
    }
    return money.cents;
  }

  /// 卖出价这类可空金额：空就是空，非数字才算错。
  int? _parseCentsOrNull(
    String raw,
    List<ExcelRowError> errors,
    int excelRow,
    String column, {
    String sheet = ExcelSchema.sheetItems,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final money = Money.tryParseYuan(text);
    if (money == null) {
      errors.add(
        ExcelRowError(
          sheet: sheet,
          row: excelRow,
          message: '「$column」不是金额：$text',
        ),
      );
      return null;
    }
    return money.cents;
  }

  /// 电池健康：0–100 的整数百分比。空就是空，非数字或越界算错。
  ///
  /// 越界不静默截断：用户手敲 120 大概率是想写别的，直接改成 100
  /// 会让他以为系统记错了。
  int? _parsePercentOrNull(
    String raw,
    List<ExcelRowError> errors,
    int excelRow,
  ) {
    final text = raw.trim().replaceAll('%', '');
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null) {
      errors.add(
        ExcelRowError(
          sheet: ExcelSchema.sheetItems,
          row: excelRow,
          message: '「${ExcelSchema.batteryHealth}」不是整数：$raw',
        ),
      );
      return null;
    }
    if (value < 0 || value > 100) {
      errors.add(
        ExcelRowError(
          sheet: ExcelSchema.sheetItems,
          row: excelRow,
          message: '「${ExcelSchema.batteryHealth}」要在 0–100 之间：$raw',
        ),
      );
      return null;
    }
    return value;
  }

  DateTime? _parseDate(
    String raw,
    List<ExcelRowError> errors,
    int excelRow,
    String column, {
    String sheet = ExcelSchema.sheetItems,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final normalized = text.replaceAll('/', '-').replaceAll('.', '-');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      errors.add(
        ExcelRowError(
          sheet: sheet,
          row: excelRow,
          message: '「$column」不是日期：$text（要写成 ${ExcelSchema.datePattern}）',
        ),
      );
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
