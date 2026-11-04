import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/exchange/excel_export.dart';
import 'package:ggjb/data/exchange/excel_import.dart';
import 'package:ggjb/data/repo/item_repository.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: ExcelExportService.buildBytes → ExcelImportService.parse/apply。
///
/// 用户报的现场是「导出 → 清空本地数据 → 导入 → 提示成功但列表还是空」。
/// 这里把那一串动作原样跑一遍：两个独立库，一个导出、一个全新的空库导入。
void main() {
  late AppDatabase src;
  late AppDatabase dst;

  setUp(() {
    src = AppDatabase(NativeDatabase.memory());
    dst = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await src.close();
    await dst.close();
  });

  Future<void> putItem(
    AppDatabase db,
    String id, {
    required String title,
    ItemStatus status = ItemStatus.inStock,
    int buyCents = 100000,
    int? sellCents,
    DateTime? sellDate,
    int? tradeInCents,
    String? category,
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
            sellDate: Value(sellDate),
            tradeInCents: Value(tradeInCents),
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-src',
            status: Value(status),
          ),
        );
  }

  Future<void> putExpense(
    AppDatabase db,
    String id,
    String itemId,
    int cents,
  ) async {
    final at = DateTime(2026, 1, 1, 12);
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
            deviceId: 'dev-src',
          ),
        );
  }

  test('导出后导入空库：商品与费用都能还原', () async {
    await putItem(src, 'a', title: 'iPhone 13', category: '手机');
    await putItem(
      src,
      'b',
      title: '小米 13',
      status: ItemStatus.sold,
      sellCents: 150000,
      sellDate: DateTime(2026, 3, 7),
      tradeInCents: 80000,
    );
    await putExpense(src, 'e1', 'a', 2500);
    await putExpense(src, 'e2', 'b', 1200);

    final bytes = await ExcelExportService(src).buildBytes();

    final repo = ItemRepository(
      db: dst,
      itemDao: ItemDao(dst),
      attachmentDao: AttachmentDao(dst),
      deviceId: 'dev-dst',
    );
    final service = ExcelImportService(db: dst, repository: repo);

    final preview = await service.parse(Uint8List.fromList(bytes));
    expect(preview.errors, isEmpty);
    expect(preview.itemCount, 2);

    final written = await service.apply(preview);
    expect(written, 2);

    final itemRows = await dst.select(dst.items).get();
    expect(itemRows.map((e) => e.title).toSet(), {'iPhone 13', '小米 13'});

    final expenseRows = await dst.select(dst.expenses).get();
    expect(expenseRows.length, 2);
    expect(expenseRows.map((e) => e.amountCents).toSet(), {2500, 1200});
  });
  test('本地有同 id 的软删商品时，导入应当把它复活而不是继续藏着', () async {
    await putItem(src, 'a', title: 'iPhone 13');
    await putExpense(src, 'e1', 'a', 2500);
    final bytes = await ExcelExportService(src).buildBytes();

    // dst 里预置一条同 id、已被软删的商品与费用 —— 模拟「清空过数据」。
    await putItem(dst, 'a', title: 'iPhone 13');
    await putExpense(dst, 'e1', 'a', 2500);
    final tomb = DateTime(2026, 2, 1);
    await (dst.update(dst.items)..where((t) => t.id.equals('a'))).write(
      ItemsCompanion(deletedAt: Value(tomb)),
    );
    await (dst.update(dst.expenses)..where((t) => t.id.equals('e1'))).write(
      ExpensesCompanion(deletedAt: Value(tomb)),
    );

    final repo = ItemRepository(
      db: dst,
      itemDao: ItemDao(dst),
      attachmentDao: AttachmentDao(dst),
      deviceId: 'dev-dst',
    );
    final service = ExcelImportService(db: dst, repository: repo);
    final preview = await service.parse(Uint8List.fromList(bytes));
    expect(preview.ok, isTrue);
    await service.apply(preview);

    final row = await (dst.select(
      dst.items,
    )..where((t) => t.id.equals('a'))).getSingle();
    expect(row.deletedAt, isNull, reason: '导入后商品应当回到列表里');

    // 费用表不写费用 id（只写商品 id），导入按「全量替换」处理：
    // 旧费用打墓碑、新费用换新 id。所以这里只要求「可见的那条金额还在」，
    // 不要求旧 id 复活。
    final visible = await (dst.select(
      dst.expenses,
    )..where((t) => t.deletedAt.isNull())).get();
    expect(visible.length, 1);
    expect(visible.single.itemId, 'a');
    expect(visible.single.amountCents, 2500);
  });
}
