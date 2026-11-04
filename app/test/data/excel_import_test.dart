import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/exchange/excel_import.dart';
import 'package:ggjb/data/exchange/excel_rows.dart';
import 'package:ggjb/data/repo/item_repository.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: ExcelImportService.parse / apply —— 从导出的表再读回来。
void main() {
  late AppDatabase db;
  late ItemRepository repo;
  late ExcelImportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ItemRepository(
      db: db,
      itemDao: ItemDao(db),
      attachmentDao: AttachmentDao(db),
      deviceId: 'dev-test',
    );
    service = ExcelImportService(db: db, repository: repo);
  });

  tearDown(() async => db.close());

  List<CellValue?> headerRow(List<String> headers) =>
      headers.map((h) => TextCellValue(h) as CellValue?).toList();

  /// 按 ExcelSchema.itemHeaders 的顺序，把 map 里的值填成一行。
  List<CellValue?> itemRow(Map<String, String> values) => ExcelSchema
      .itemHeaders
      .map(
        (h) => (values[h] ?? '').isEmpty
            ? null
            : TextCellValue(values[h]!) as CellValue?,
      )
      .toList();

  List<CellValue?> expenseRow(Map<String, String> values) => ExcelSchema
      .expenseHeaders
      .map(
        (h) => (values[h] ?? '').isEmpty
            ? null
            : TextCellValue(values[h]!) as CellValue?,
      )
      .toList();

  Uint8List buildBook({
    List<List<CellValue?>> items = const [],
    List<List<CellValue?>> expenses = const [],
  }) {
    final book = Excel.createExcel();
    final def = book.getDefaultSheet();
    if (def != null && def != ExcelSchema.sheetItems) {
      book.rename(def, ExcelSchema.sheetItems);
    }
    book.appendRow(ExcelSchema.sheetItems, headerRow(ExcelSchema.itemHeaders));
    for (final row in items) {
      book.appendRow(ExcelSchema.sheetItems, row);
    }
    book.appendRow(
      ExcelSchema.sheetExpenses,
      headerRow(ExcelSchema.expenseHeaders),
    );
    for (final row in expenses) {
      book.appendRow(ExcelSchema.sheetExpenses, row);
    }
    return Uint8List.fromList(book.save()!);
  }

  Uint8List bookWithIdOnly() {
    final book = Excel.createExcel();
    final def = book.getDefaultSheet()!;
    if (def != ExcelSchema.sheetItems) {
      book.rename(def, ExcelSchema.sheetItems);
    }
    book.appendRow(ExcelSchema.sheetItems, [TextCellValue(ExcelSchema.id)]);
    return Uint8List.fromList(book.save()!);
  }

  test('最小一行：名称 + 买入价，其余留空', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({ExcelSchema.title: '小米 14', ExcelSchema.buyPrice: '3200'}),
        ],
      ),
    );

    expect(preview.ok, isTrue, reason: preview.describeErrors());
    expect(preview.itemCount, 1);
    final draft = preview.items.single;
    expect(draft.title, '小米 14');
    expect(draft.buyPriceCents, 320000);
    expect(draft.status, ItemStatus.inStock);
    expect(draft.category, isNull);
  });

  test('完整一行：字段逐个映射', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({
            ExcelSchema.id: 'i-fixed',
            ExcelSchema.title: 'iPhone 15',
            ExcelSchema.category: '手机',
            ExcelSchema.brand: 'Apple',
            ExcelSchema.model: 'A3092',
            ExcelSchema.storage: '256G',
            ExcelSchema.color: '原色钛金属',
            ExcelSchema.status: '已卖出',
            ExcelSchema.buyPrice: '5800',
            ExcelSchema.buyDate: '2026-01-05',
            ExcelSchema.sourcePlatform: '闲鱼',
            ExcelSchema.sellPrice: '6400',
            ExcelSchema.sellDate: '2026-02-11',
            ExcelSchema.sellPlatform: '转转',
            ExcelSchema.batteryHealth: '92',
            ExcelSchema.note: '轻微使用痕迹',
            ExcelSchema.lotId: 'L-1',
          }),
        ],
      ),
    );

    expect(preview.ok, isTrue, reason: preview.describeErrors());
    final draft = preview.items.single;
    expect(draft.id, 'i-fixed');
    expect(draft.brand, 'Apple');
    expect(draft.model, 'A3092');
    expect(draft.status, ItemStatus.sold);
    expect(draft.buyPriceCents, 580000);
    expect(draft.sellPriceCents, 640000);
    expect(draft.buyDate, DateTime(2026, 1, 5));
    expect(draft.sellDate, DateTime(2026, 2, 11));
    expect(draft.batteryHealth, 92);
    expect(draft.lotId, 'L-1');
  });

  test('金额里的货币符号与千分位被吃掉', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({ExcelSchema.title: 'A', ExcelSchema.buyPrice: '¥1,200.50'}),
        ],
      ),
    );

    expect(preview.ok, isTrue, reason: preview.describeErrors());
    expect(preview.items.single.buyPriceCents, 120050);
  });

  test('空行跳过，不算错误', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({ExcelSchema.title: 'A', ExcelSchema.buyPrice: '100'}),
          itemRow({}),
          itemRow({ExcelSchema.title: 'B', ExcelSchema.buyPrice: '200'}),
        ],
      ),
    );

    expect(preview.itemCount, 2);
    expect(preview.errors, isEmpty);
  });

  test('名称为空报错并跳过该行', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({ExcelSchema.buyPrice: '100'}),
        ],
      ),
    );

    expect(preview.ok, isFalse);
    expect(preview.itemCount, 0);
    expect(preview.errors.map((e) => e.message).join(' | '), contains('不能为空'));
    expect(preview.errors.single.toString(), contains('第 2 行'));
  });

  test('状态不认识时报错，可用值写进提示', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({
            ExcelSchema.title: 'A',
            ExcelSchema.buyPrice: '100',
            ExcelSchema.status: '已送人',
          }),
        ],
      ),
    );

    expect(preview.itemCount, 0);
    final message = preview.errors.map((e) => e.message).join(' | ');
    expect(message, contains('已送人'));
    expect(message, contains('在库'));
  });

  test('卖出状态缺卖出价时提醒', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({
            ExcelSchema.title: 'A',
            ExcelSchema.buyPrice: '100',
            ExcelSchema.status: '已卖出',
          }),
        ],
      ),
    );

    expect(preview.errors.map((e) => e.message).join(' | '), contains('没有填'));
  });

  test('同一个 id 出现两次报错', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({
            ExcelSchema.id: 'dup',
            ExcelSchema.title: 'A',
            ExcelSchema.buyPrice: '100',
          }),
          itemRow({
            ExcelSchema.id: 'dup',
            ExcelSchema.title: 'B',
            ExcelSchema.buyPrice: '200',
          }),
        ],
      ),
    );

    expect(preview.itemCount, 2);
    expect(preview.errors.map((e) => e.message).join(' | '), contains('出现了两次'));
  });

  test('表头缺名称列时给出一条表头级提示', () async {
    final preview = await service.parse(bookWithIdOnly());

    expect(preview.itemCount, 0);
    expect(preview.errors.single.message, contains('缺少'));
  });

  test('费用按商品 id 挂上去', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({
            ExcelSchema.id: 'i1',
            ExcelSchema.title: 'A',
            ExcelSchema.buyPrice: '100',
          }),
        ],
        expenses: [
          expenseRow({
            ExcelSchema.expenseItemId: 'i1',
            ExcelSchema.expenseKind: '维修/清洁',
            ExcelSchema.expenseSide: '买入',
            ExcelSchema.expenseAmount: '120',
          }),
        ],
      ),
    );

    expect(preview.ok, isTrue, reason: preview.describeErrors());
    expect(preview.expenseCount, 1);
    final expense = preview.expenses['i1']!.single;
    expect(expense.kind, ExpenseKind.repair);
    expect(expense.side, ExpenseSide.buy);
    expect(expense.amountCents, 12000);
  });

  test('parse 只预览，不写库', () async {
    await service.parse(
      buildBook(
        items: [
          itemRow({ExcelSchema.title: '小米 14', ExcelSchema.buyPrice: '3200'}),
        ],
      ),
    );

    expect(await db.select(db.items).get(), isEmpty);
  });

  test('apply 更新库里已有的 id', () async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'i1',
            title: '旧名字',
            buyPriceCents: 100000,
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-old',
          ),
        );

    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({
            ExcelSchema.id: 'i1',
            ExcelSchema.title: '小米 14',
            ExcelSchema.buyPrice: '3200',
          }),
        ],
      ),
    );
    final written = await service.apply(preview);

    expect(written, 1);
    final row = await (db.select(
      db.items,
    )..where((t) => t.id.equals('i1'))).getSingle();
    expect(row.title, '小米 14');
    expect(row.buyPriceCents, 320000);
    expect(row.deviceId, 'dev-old', reason: '编辑不改最初录入设备');
  });

  // 缺陷#4：新行没有 id 时 parse 会分配 uuid，于是 repo.save 走 update 分支，
  // update 不存在的行 = 0 行受影响，apply 却照样 written++。
  // 用户看到「已导入 1 件」，列表里却什么都没有。
  test('apply 把表里的新行插进库', () async {
    final preview = await service.parse(
      buildBook(
        items: [
          itemRow({ExcelSchema.title: '小米 14', ExcelSchema.buyPrice: '3200'}),
        ],
      ),
    );
    await service.apply(preview);

    final rows = await db.select(db.items).get();
    expect(rows.single.title, '小米 14');
  });
  Uint8List bookWithExpenses(List<Map<String, String>> rows) => buildBook(
    items: [
      itemRow({
        ExcelSchema.id: 'p1',
        ExcelSchema.title: '小米 14',
        ExcelSchema.buyPrice: '3200',
      }),
    ],
    expenses: [
      for (final row in rows)
        expenseRow({
          ExcelSchema.expenseItemId: 'p1',
          ExcelSchema.expenseKind: ExpenseKind.repair.label,
          ExcelSchema.expenseSide: ExpenseSide.buy.label,
          ...row,
        }),
    ],
  );

  test('同一份表连导两次，费用不重复也不换 id', () async {
    final bytes = bookWithExpenses([
      {'费用id': 'e1', ExcelSchema.expenseAmount: '40'},
    ]);
    await service.apply(await service.parse(bytes));
    await service.apply(await service.parse(bytes));

    final alive = await (db.select(
      db.expenses,
    )..where((t) => t.deletedAt.isNull())).get();
    expect(alive.length, 1);
    expect(alive.single.id, 'e1');
    expect(alive.single.amountCents, 4000);
    final dead = await (db.select(
      db.expenses,
    )..where((t) => t.deletedAt.isNotNull())).get();
    expect(dead, isEmpty, reason: '原地覆盖不该产生墓碑');
  });

  test('本地已软删的费用被表里的 id 复活', () async {
    await service.apply(
      await service.parse(
        bookWithExpenses([
          {'费用id': 'e1', ExcelSchema.expenseAmount: '40'},
        ]),
      ),
    );
    await (db.update(db.expenses)..where((t) => t.id.equals('e1'))).write(
      ExpensesCompanion(deletedAt: Value(DateTime(2026, 2, 1))),
    );

    await service.apply(
      await service.parse(
        bookWithExpenses([
          {'费用id': 'e1', ExcelSchema.expenseAmount: '60'},
        ]),
      ),
    );

    final row = await (db.select(
      db.expenses,
    )..where((t) => t.id.equals('e1'))).getSingle();
    expect(row.deletedAt, isNull);
    expect(row.amountCents, 6000);
  });

  test('没有费用 id 列的旧文件照样能导入', () async {
    final legacy = ExcelSchema.expenseHeaders
        .where((h) => h != '费用id')
        .toList();
    final book = Excel.createExcel();
    final def = book.getDefaultSheet();
    if (def != null && def != ExcelSchema.sheetItems) {
      book.rename(def, ExcelSchema.sheetItems);
    }
    book.appendRow(ExcelSchema.sheetItems, headerRow(ExcelSchema.itemHeaders));
    book.appendRow(
      ExcelSchema.sheetItems,
      itemRow({
        ExcelSchema.id: 'p1',
        ExcelSchema.title: '小米 14',
        ExcelSchema.buyPrice: '3200',
      }),
    );
    book.appendRow(ExcelSchema.sheetExpenses, headerRow(legacy));
    book.appendRow(
      ExcelSchema.sheetExpenses,
      headerRow([
        'p1',
        '小米 14',
        ExpenseKind.repair.label,
        ExpenseSide.buy.label,
        '40',
        '',
        '',
      ]),
    );
    final preview = await service.parse(Uint8List.fromList(book.save()!));

    expect(preview.ok, isTrue);
    expect(preview.expenseCount, 1);
    await service.apply(preview);
    final rows = await db.select(db.expenses).get();
    expect(rows.length, 1);
    expect(rows.single.amountCents, 4000);
  });

  test('两行写了同一个费用 id 就报错', () async {
    final preview = await service.parse(
      bookWithExpenses([
        {'费用id': 'e1', ExcelSchema.expenseAmount: '40'},
        {'费用id': 'e1', ExcelSchema.expenseAmount: '60'},
      ]),
    );

    expect(preview.ok, isFalse);
    expect(preview.errors.map((e) => e.message).join(' | '), contains('费用id'));
  });
}
