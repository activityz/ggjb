import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/exchange/excel_export.dart';
import 'package:ggjb/data/exchange/excel_rows.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: ExcelExportService.buildBytes —— 导出表的口径与列布局。
void main() {
  late AppDatabase db;
  late ExcelExportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ExcelExportService(db);
  });

  tearDown(() async => db.close());

  Future<void> putItem(
    String id, {
    String title = '测试机',
    ItemStatus status = ItemStatus.inStock,
    String? category,
    int buyCents = 100000,
    int? sellCents,
    DateTime? buyDate,
    DateTime? sellDate,
    String? note,
    bool deleted = false,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: title,
            category: Value(category),
            buyPriceCents: buyCents,
            sellPriceCents: Value(sellCents),
            buyDate: Value(buyDate),
            sellDate: Value(sellDate),
            note: Value(note),
            createdAt: at,
            updatedAt: at,
            deletedAt: Value(deleted ? at : null),
            deviceId: 'dev-test',
            status: Value(status),
          ),
        );
  }

  Future<void> putExpense(String id, String itemId, int cents) async {
    final at = DateTime(2026, 1, 2, 12);
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: id,
            itemId: itemId,
            kind: ExpenseKind.repair,
            side: ExpenseSide.buy,
            amountCents: cents,
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-test',
          ),
        );
  }

  Sheet sheetOf(List<int> bytes, String name) {
    final book = Excel.decodeBytes(bytes);
    return book[name];
  }

  /// xlsx 往返后数值可能变成 IntCellValue，这里统一取 num。
  num? numOf(List<Data?> row, String header) {
    final cell = row[ExcelSchema.itemHeaders.indexOf(header)]?.value;
    if (cell is DoubleCellValue) return cell.value;
    if (cell is IntCellValue) return cell.value;
    return null;
  }

  test('导出两张表，表头与 ExcelSchema 一致', () async {
    await putItem('i1');
    final bytes = await service.buildBytes();
    final book = Excel.decodeBytes(bytes);

    expect(
      book.tables.keys,
      containsAll([ExcelSchema.sheetItems, ExcelSchema.sheetExpenses]),
    );
    final items = sheetOf(bytes, ExcelSchema.sheetItems);
    final headers = items.rows.first
        .map((c) => c?.value.toString() ?? '')
        .toList();
    expect(headers, ExcelSchema.itemHeaders);
    final expenses = sheetOf(bytes, ExcelSchema.sheetExpenses);
    expect(
      expenses.rows.first.map((c) => c?.value.toString() ?? '').toList(),
      ExcelSchema.expenseHeaders,
    );
  });

  test('软删的商品与费用不导出', () async {
    await putItem('alive');
    await putItem('dead', deleted: true);
    await putExpense('e1', 'alive', 4000);

    final items = sheetOf(await service.buildBytes(), ExcelSchema.sheetItems);
    final ids = items.rows.skip(1).map((r) => r[0]?.value.toString()).toSet();
    expect(ids, {'alive'});
  });

  test('金额按元写入，买入 1000 元是数值 1000', () async {
    await putItem('i1', buyCents: 100000);
    final items = sheetOf(await service.buildBytes(), ExcelSchema.sheetItems);
    final buyIndex = ExcelSchema.itemHeaders.indexOf(ExcelSchema.buyPrice);

    // 整数金额经 xlsx 往返后会被读成 IntCellValue，断言只看数值。
    expect(numOf(items.rows[1], ExcelSchema.buyPrice), 1000);
    expect(buyIndex, isNonNegative);
  });

  test('利润四列来自 ProfitLine：含费用、成本与利润率', () async {
    await putItem('i1', status: ItemStatus.sold, sellCents: 150000);
    await putExpense('e1', 'i1', 4000);

    final items = sheetOf(await service.buildBytes(), ExcelSchema.sheetItems);
    final row = items.rows[1];
    expect(numOf(row, ExcelSchema.expenseTotal), 40);
    expect(numOf(row, ExcelSchema.totalCost), 1040);
    expect(numOf(row, ExcelSchema.profitAmount), 460);
    // 口径：marginRate = 利润 / 总投入（profit.dart:77-80），不是除以卖出价。
    expect(
      numOf(row, ExcelSchema.profitRate)!.toDouble(),
      closeTo(44.23, 0.01),
    );
  });

  test('在库商品卖出列留空', () async {
    await putItem('i1', status: ItemStatus.inStock);
    final items = sheetOf(await service.buildBytes(), ExcelSchema.sheetItems);
    final row = items.rows[1];
    final sellIndex = ExcelSchema.itemHeaders.indexOf(ExcelSchema.sellPrice);
    final dateIndex = ExcelSchema.itemHeaders.indexOf(ExcelSchema.sellDate);

    expect(row[sellIndex]?.value, isNull);
    expect(row[dateIndex]?.value, isNull);
  });

  test('日期按 schema 的 pattern 写成文本', () async {
    await putItem('i1', buyDate: DateTime(2026, 3, 7));
    final items = sheetOf(await service.buildBytes(), ExcelSchema.sheetItems);
    final idx = ExcelSchema.itemHeaders.indexOf(ExcelSchema.buyDate);

    expect(items.rows[1][idx]?.value.toString(), '2026-03-07');
  });

  test('费用表带上商品标题，且渠道/种类用中文标签', () async {
    await putItem('i1', title: '小米 14');
    await putExpense('e1', 'i1', 4000);

    final expenses = sheetOf(
      await service.buildBytes(),
      ExcelSchema.sheetExpenses,
    );
    final row = expenses.rows[1];
    String? cell(String header) =>
        row[ExcelSchema.expenseHeaders.indexOf(header)]?.value.toString();
    expect(cell(ExcelSchema.expenseItemTitle), '小米 14');
    expect(cell(ExcelSchema.expenseKind), ExpenseKind.repair.label);
    expect(cell(ExcelSchema.expenseSide), ExpenseSide.buy.label);
  });

  test('没有商品时也能导出，只有表头', () async {
    final items = sheetOf(await service.buildBytes(), ExcelSchema.sheetItems);
    expect(items.rows.length, 1);
  });
  test('费用表首列是费用 id', () async {
    await putItem('i1');
    await putExpense('e1', 'i1', 4000);

    final expenses = sheetOf(
      await service.buildBytes(),
      ExcelSchema.sheetExpenses,
    );
    final headers = expenses.rows.first
        .map((c) => c?.value.toString() ?? '')
        .toList();
    expect(headers.first, '费用id');
    expect(expenses.rows[1].first?.value.toString(), 'e1');
  });
}
