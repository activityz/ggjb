import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/date_period.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: ItemDao —— 明细列表的查询口径与软删除级联。
void main() {
  late AppDatabase db;
  late ItemDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ItemDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> put(
    String id, {
    String title = '测试机',
    ItemStatus status = ItemStatus.inStock,
    String? category,
    String? brand,
    String? model,
    String? note,
    DateTime? buyDate,
    DateTime? sellDate,
    int buyCents = 100000,
    int? sellCents,
    DateTime? updatedAt,
    bool deleted = false,
  }) async {
    final created = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: title,
            category: Value(category),
            brand: Value(brand),
            model: Value(model),
            note: Value(note),
            buyDate: Value(buyDate),
            sellDate: Value(sellDate),
            buyPriceCents: buyCents,
            sellPriceCents: Value(sellCents),
            createdAt: created,
            updatedAt: updatedAt ?? created,
            deletedAt: Value(deleted ? created : null),
            deviceId: 'dev-test',
            status: Value(status),
          ),
        );
  }

  Future<void> putExpense(String id, String itemId, int cents) async {
    final now = DateTime(2026, 1, 1, 12);
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: id,
            itemId: itemId,
            kind: ExpenseKind.shipping,
            side: ExpenseSide.buy,
            amountCents: cents,
            createdAt: now,
            updatedAt: now,
            deviceId: 'dev-test',
          ),
        );
  }

  List<String> ids(List<ItemListRow> rows) =>
      rows.map((r) => r.item.id).toList();

  group('watchList 过滤', () {
    test('默认排除软删除的记录', () async {
      await put('a');
      await put('b', deleted: true);
      expect(ids(await dao.watchList().first), ['a']);
    });

    test('statuses 集合优先于单个 status', () async {
      await put('a', status: ItemStatus.sold);
      await put('b', status: ItemStatus.completed);
      await put('c', status: ItemStatus.inStock);

      final rows = await dao
          .watchList(
            status: ItemStatus.inStock,
            statuses: {ItemStatus.sold, ItemStatus.completed},
          )
          .first;
      expect(ids(rows).toSet(), {'a', 'b'});
    });

    test('单个 status 过滤仍然可用', () async {
      await put('a', status: ItemStatus.sold);
      await put('b', status: ItemStatus.inStock);
      expect(ids(await dao.watchList(status: ItemStatus.sold).first), ['a']);
    });

    test('关键词同时匹配标题、品牌、机型、备注', () async {
      await put('a', title: 'iPhone 15');
      await put('b', brand: 'Apple');
      await put('c', model: 'iPhone 15 Pro');
      await put('d', note: '带 iPhone 包装盒');
      await put('e', title: '小米 14');

      final rows = await dao.watchList(keyword: 'iPhone').first;
      expect(ids(rows).toSet(), {'a', 'c', 'd'});
    });

    test('关键词首尾空格被忽略，纯空白等于不过滤', () async {
      await put('a', title: 'iPhone');
      await put('b', title: '小米');
      expect(ids(await dao.watchList(keyword: '  iPhone  ').first), ['a']);
      expect((await dao.watchList(keyword: '   ').first).length, 2);
    });

    test('买入日期用左闭右开，次日 0 点整不算当天', () async {
      await put('a', buyDate: DateTime(2026, 3, 1));
      await put('b', buyDate: DateTime(2026, 3, 31, 23, 59, 59));
      await put('c', buyDate: DateTime(2026, 4, 1));

      final rows = await dao
          .watchList(
            dateField: DateField.buy,
            range: DateRange(
              from: DateTime(2026, 3, 1),
              to: DateTime(2026, 3, 31),
            ),
          )
          .first;
      expect(ids(rows).toSet(), {'a', 'b'});
    });

    test('卖出日期同理，且不会把没有卖出日期的在库单带出来', () async {
      await put('a', status: ItemStatus.sold, sellDate: DateTime(2026, 3, 5));
      await put('b', status: ItemStatus.inStock);
      final rows = await dao
          .watchList(
            dateField: DateField.sell,
            range: DateRange(from: DateTime(2026, 3, 1)),
          )
          .first;
      expect(ids(rows), ['a']);
    });

    test('结果按 updatedAt 倒序', () async {
      await put('a', updatedAt: DateTime(2026, 1, 1));
      await put('b', updatedAt: DateTime(2026, 3, 1));
      await put('c', updatedAt: DateTime(2026, 2, 1));
      expect(ids(await dao.watchList().first), ['b', 'c', 'a']);
    });
  });

  group('列表附带信息', () {
    test('一条商品挂两条费用时只出一行，金额合计', () async {
      await put('a');
      await putExpense('e1', 'a', 1500);
      await putExpense('e2', 'a', 2500);

      final rows = await dao.watchList().first;
      expect(rows, hasLength(1));
      expect(rows.single.expenseCents, 4000);
    });

    test('列表带上第一张缩略图（按 createdAt 最早）', () async {
      await put('a');
      final now = DateTime(2026, 1, 1, 12);
      await db
          .into(db.attachments)
          .insert(
            AttachmentsCompanion.insert(
              id: 'p2',
              itemId: 'a',
              role: AttachmentRole.buyShot,
              bytes: Uint8List.fromList([0]),
              thumb: Value(Uint8List.fromList([2])),
              createdAt: now.add(const Duration(hours: 2)),
              updatedAt: now.add(const Duration(hours: 2)),
              deviceId: 'dev-test',
            ),
          );
      await db
          .into(db.attachments)
          .insert(
            AttachmentsCompanion.insert(
              id: 'p1',
              itemId: 'a',
              role: AttachmentRole.buyShot,
              bytes: Uint8List.fromList([0]),
              thumb: Value(Uint8List.fromList([1])),
              createdAt: now,
              updatedAt: now,
              deviceId: 'dev-test',
            ),
          );

      final row = (await dao.watchList().first).single;
      expect(row.thumb, Uint8List.fromList([1]));
    });
  });

  group('load 与软删除', () {
    test('load 返回商品与其费用', () async {
      await put('a');
      await putExpense('e1', 'a', 100);
      final loaded = await dao.load('a');
      expect(loaded, isNotNull);
      expect(loaded!.item.id, 'a');
      expect(loaded.expenses.single.amountCents, 100);
    });

    test('load 对软删除的商品返回 null', () async {
      await put('a', deleted: true);
      expect(await dao.load('a'), isNull);
    });

    test('softDeleteItem 级联软删费用与附件', () async {
      await put('a');
      await putExpense('e1', 'a', 100);
      await db
          .into(db.attachments)
          .insert(
            AttachmentsCompanion.insert(
              id: 'p1',
              itemId: 'a',
              role: AttachmentRole.buyShot,
              bytes: Uint8List.fromList([0]),
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
              deviceId: 'dev-test',
            ),
          );

      await dao.softDeleteItem('a', now: DateTime(2026, 5, 1));

      expect(await dao.watchList().first, isEmpty);
      expect(await dao.allExpenses(), isEmpty);
      final raw = await (db.select(
        db.attachments,
      )..where((t) => t.id.equals('p1'))).getSingle();
      expect(raw.deletedAt, isNotNull, reason: '写墓碑，不物理删');
    });

    test('findById 能查到软删除的记录（同步需要墓碑）', () async {
      await put('a', deleted: true);
      expect(await dao.findById('a'), isNotNull);
    });
  });

  group('allProfitLines', () {
    test('把同一商品的多条费用汇总成 expenseCents', () async {
      await put('a', status: ItemStatus.sold, sellCents: 200000);
      await putExpense('e1', 'a', 1000);
      await putExpense('e2', 'a', 2000);

      final lines = await dao.allProfitLines();
      expect(lines.single.expenseCents, 3000);
      expect(lines.single.status, ItemStatus.sold);
    });

    test('按卖出日期过滤且排除软删除', () async {
      await put('a', status: ItemStatus.sold, sellDate: DateTime(2026, 3, 5));
      await put('b', status: ItemStatus.sold, sellDate: DateTime(2026, 6, 5));
      await put(
        'c',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 3, 6),
        deleted: true,
      );

      final lines = await dao.allProfitLines(
        dateField: DateField.sell,
        range: DateRange(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 31)),
      );
      expect(lines.map((l) => l.itemId), ['a']);
    });
  });
}
