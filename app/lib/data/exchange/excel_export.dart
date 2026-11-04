/// 把整库导出成 Excel（两个 sheet：商品 / 费用明细）。
///
/// 一条纪律：**利润、总投入、费用合计、利润率这四列必须来自
/// [ProfitLine]，不能在这里重算。** 否则哪天口径变了，Excel 里还是
/// 老算法，用户拿着表来问「为什么和 App 里不一样」。
library;

import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../domain/app_paths.dart';
import '../../domain/enums.dart';
import '../../domain/profit.dart';
import '../dao/item_dao.dart';
import '../db/app_database.dart';
import 'excel_rows.dart';

/// 导出结果：文件 + 行数，交给 UI 提示。
class ExcelExportResult {
  const ExcelExportResult({
    required this.file,
    required this.itemCount,
    required this.expenseCount,
    required this.sizeBytes,
  });

  final File file;
  final int itemCount;
  final int expenseCount;
  final int sizeBytes;

  String describe() =>
      '已导出 $itemCount 件商品、$expenseCount 条费用（${(sizeBytes / 1024).toStringAsFixed(1)} KB）';
}

class ExcelExportService {
  ExcelExportService(this._db);

  final AppDatabase _db;

  final DateFormat _date = DateFormat(ExcelSchema.datePattern);

  /// 生成 xlsx 字节。不落盘，方便单测与直接分享。
  Future<List<int>> buildBytes() async {
    final items =
        await (_db.select(_db.items)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();
    final expenses = await (_db.select(
      _db.expenses,
    )..where((t) => t.deletedAt.isNull())).get();

    final lines = <String, ProfitLine>{
      for (final line in await ItemDao(_db).allProfitLines()) line.itemId: line,
    };
    final titleOf = <String, String>{
      for (final item in items) item.id: item.title,
    };

    final excel = Excel.createExcel();

    // Excel 包默认带一张 Sheet1，把它改名当商品表，省得留一张空表。
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != ExcelSchema.sheetItems) {
      excel.rename(defaultSheet, ExcelSchema.sheetItems);
    }

    excel.appendRow(
      ExcelSchema.sheetItems,
      ExcelSchema.itemHeaders
          .map((h) => TextCellValue(h) as CellValue?)
          .toList(),
    );

    for (final item in items) {
      final line = lines[item.id];
      excel.appendRow(ExcelSchema.sheetItems, <CellValue?>[
        TextCellValue(item.id),
        TextCellValue(item.title),
        _text(item.category),
        _text(item.brand),
        _text(item.model),
        _text(item.storage),
        _text(item.color),
        TextCellValue(ExcelSchema.statusLabel(item.status)),
        _money(item.buyPriceCents),
        _text(item.buyDate == null ? null : _date.format(item.buyDate!)),
        _text(item.sourcePlatform),
        _text(item.conditionBought),
        item.sellPriceCents == null ? null : _money(item.sellPriceCents!),
        _text(item.sellDate == null ? null : _date.format(item.sellDate!)),
        _text(item.sellPlatform),
        _text(item.conditionSold),
        item.batteryHealth == null ? null : IntCellValue(item.batteryHealth!),
        item.listPriceCents == null ? null : _money(item.listPriceCents!),
        item.tradeInCents == null ? null : _money(item.tradeInCents!),
        // 以下四列由 ProfitLine 提供，口径与看板一致。
        _money(line?.expenseCents ?? 0),
        _money(line?.totalCostCents ?? item.buyPriceCents),
        line?.profitCents == null ? null : _money(line!.profitCents!),
        line?.marginRate == null
            ? null
            : DoubleCellValue(
                double.parse((line!.marginRate! * 100).toStringAsFixed(2)),
              ),
        _text(item.note),
        _text(item.lotId),
      ]);
    }

    excel.appendRow(
      ExcelSchema.sheetExpenses,
      ExcelSchema.expenseHeaders
          .map((h) => TextCellValue(h) as CellValue?)
          .toList(),
    );

    for (final expense in expenses) {
      excel.appendRow(ExcelSchema.sheetExpenses, <CellValue?>[
        TextCellValue(expense.id),
        TextCellValue(expense.itemId),
        _text(titleOf[expense.itemId]),
        TextCellValue(ExcelSchema.kindLabel(expense.kind)),
        TextCellValue(ExcelSchema.sideLabel(expense.side)),
        _money(expense.amountCents),
        _text(
          expense.incurredAt == null ? null : _date.format(expense.incurredAt!),
        ),
        _text(expense.note),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Excel 生成失败：save() 返回了 null');
    }
    return bytes;
  }

  /// 生成文件。位置与 .db 快照同一策略：Android 优先外部存储，
  /// 其他平台用应用文档目录。
  Future<ExcelExportResult> exportToFile({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final bytes = await buildBytes();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(at);
    final dir = await _targetDir();
    final file = File(p.join(dir.path, 'ggjb_$stamp.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
    return ExcelExportResult(
      file: file,
      itemCount: await _countItems(),
      expenseCount: await _countExpenses(),
      sizeBytes: bytes.length,
    );
  }

  Future<int> _countItems() async {
    final rows = await (_db.select(
      _db.items,
    )..where((t) => t.deletedAt.isNull())).get();
    return rows.length;
  }

  Future<int> _countExpenses() async {
    final rows = await (_db.select(
      _db.expenses,
    )..where((t) => t.deletedAt.isNull())).get();
    return rows.length;
  }

  Future<Directory> _targetDir() => AppPaths.exportDir();

  /// 空单元格写 null，别写空字符串——空串在 Excel 里是「有值」，
  /// 导入时会被当成用户手填的内容。
  CellValue? _text(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return TextCellValue(text);
  }

  /// 金额一律「分 → 元」的 double，Excel 里才能直接求和。
  CellValue _money(int cents) => DoubleCellValue(cents / 100);

  /// 供导入端复用的状态枚举（避免两处各写一份翻译）。
  static ItemStatus statusOrStock(String raw) =>
      ExcelSchema.statusFromLabel(raw) ?? ItemStatus.inStock;
}
