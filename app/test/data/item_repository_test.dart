import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/repo/item_repository.dart';
import 'package:ggjb/domain/date_period.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: ItemRepository —— UI 唯一允许的写入口。
void main() {
  late AppDatabase db;
  late ItemDao itemDao;
  late ItemRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    itemDao = ItemDao(db);
    repo = ItemRepository(
      db: db,
      itemDao: itemDao,
      attachmentDao: AttachmentDao(db),
      deviceId: 'dev-test',
    );
  });

  tearDown(() async {
    await db.close();
  });

  ItemDraft draft({
    String? id,
    String title = '测试机',
    ItemStatus status = ItemStatus.inStock,
    int buyPriceCents = 100000,
    String? category,
    String? note,
    DateTime? buyDate,
    DateTime? sellDate,
    int? sellPriceCents,
  }) => ItemDraft(
    id: id,
    title: title,
    status: status,
    buyPriceCents: buyPriceCents,
    category: category,
    note: note,
    buyDate: buyDate,
    sellDate: sellDate,
    sellPriceCents: sellPriceCents,
  );

  ExpenseDraft expense(
    int cents, {
    String? id,
    ExpenseKind kind = ExpenseKind.shipping,
    ExpenseSide side = ExpenseSide.buy,
  }) => ExpenseDraft(id: id, kind: kind, side: side, amountCents: cents);

  Future<Item> row(String id) async =>
      (await (db.select(db.items)..where((t) => t.id.equals(id))).getSingle());

  group('save 新建', () {
    test('返回 id 并落库商品与费用', () async {
      final id = await repo.save(draft(), [expense(1500), expense(500)]);

      final saved = await row(id);
      expect(saved.title, '测试机');
      expect(saved.status, ItemStatus.inStock);
      expect(saved.deviceId, 'dev-test');

      final loaded = await repo.load(id);
      expect(loaded!.expenses, hasLength(2));
      expect(
        loaded.expenses.map((e) => e.amountCents).reduce((a, b) => a + b),
        2000,
      );
    });

    test('保存时补齐 updatedAt，不让它留在 1970', () async {
      final id = await repo.save(draft(), const []);
      final saved = await row(id);
      expect(
        saved.updatedAt.difference(DateTime.now()).inMinutes.abs(),
        lessThan(5),
      );
    });
  });

  group('save 编辑', () {
    test('保留 createdAt 与最初的 deviceId', () async {
      final id = await repo.save(draft(title: '旧标题'), const []);
      final created = (await row(id)).createdAt;

      final other = ItemRepository(
        db: db,
        itemDao: itemDao,
        attachmentDao: AttachmentDao(db),
        deviceId: 'dev-other',
      );
      await other.save(draft(id: id, title: '新标题'), const []);

      final saved = await row(id);
      expect(saved.title, '新标题');
      expect(saved.createdAt, created, reason: '创建时间不能被编辑改掉');
      expect(saved.deviceId, 'dev-test', reason: 'deviceId 记录最初创建者');
    });

    test('带 id 复活一条已软删的费用，不炸主键冲突', () async {
      final id = await repo.save(draft(), [expense(1000)]);
      final first = (await repo.load(id))!.expenses.single;

      // 先删掉这笔费用（走全量替换：本次列表里没有它）
      await repo.save(draft(id: id), const []);
      expect((await repo.load(id))!.expenses, isEmpty);
      final tomb = await (db.select(
        db.expenses,
      )..where((t) => t.id.equals(first.id))).getSingle();
      expect(tomb.deletedAt, isNotNull, reason: '墓碑保留给对端同步');

      // 再把它带回来 —— 旧实现会 `UNIQUE constraint failed: expenses.id`
      await repo.save(draft(id: id), [expense(3000, id: first.id)]);

      final loaded = await repo.load(id);
      expect(loaded!.expenses.single.id, first.id);
      expect(loaded.expenses.single.amountCents, 3000);
      expect(loaded.expenses.single.deletedAt, isNull);
    });

    test('本次不在列表里的旧费用全部打墓碑', () async {
      final id = await repo.save(draft(), [expense(100), expense(200)]);
      final before = (await repo.load(id))!.expenses.toList();

      await repo.save(draft(id: id), [expense(999, id: before.first.id)]);

      final after = (await repo.load(id))!.expenses;
      expect(after, hasLength(1));
      expect(after.single.id, before.first.id);
      expect(after.single.amountCents, 999);
    });

    test('空费用列表不会生成非法的 NOT IN ()', () async {
      final id = await repo.save(draft(), [expense(100)]);
      await repo.save(draft(id: id), const []);
      expect((await repo.load(id))!.expenses, isEmpty);
    });

    test('编辑费用保留其 createdAt', () async {
      final id = await repo.save(draft(), [expense(100)]);
      final e = (await repo.load(id))!.expenses.single;
      await repo.save(draft(id: id), [expense(500, id: e.id)]);
      final after = (await repo.load(id))!.expenses.single;
      expect(after.createdAt, e.createdAt);
    });
  });

  group('状态机', () {
    late String id;

    setUp(() async {
      id = await repo.save(draft(), const []);
    });

    test('markSold 写入卖出价、日期、渠道并置为已卖出', () async {
      final when = DateTime(2026, 3, 7);
      await repo.markSold(
        id,
        sellPriceCents: 180000,
        sellDate: when,
        sellPlatform: '闲鱼',
      );
      final saved = await row(id);
      expect(saved.status, ItemStatus.sold);
      expect(saved.sellPriceCents, 180000);
      expect(saved.sellDate, when);
      expect(saved.sellPlatform, '闲鱼');
    });

    test('markSold 不给日期时默认当前时间', () async {
      await repo.markSold(id, sellPriceCents: 100);
      final saved = await row(id);
      expect(saved.sellDate, isNotNull);
      expect(
        saved.sellDate!.difference(DateTime.now()).inMinutes.abs(),
        lessThan(5),
      );
    });

    test('markCompleted 只改状态，卖出价与日期原样保留', () async {
      final when = DateTime(2026, 3, 7);
      await repo.markSold(id, sellPriceCents: 180000, sellDate: when);
      await repo.markCompleted(id);

      final saved = await row(id);
      expect(saved.status, ItemStatus.completed);
      expect(saved.sellPriceCents, 180000);
      expect(saved.sellDate, when);
    });

    test('unmarkCompleted 退回已卖出', () async {
      await repo.markSold(id, sellPriceCents: 180000);
      await repo.markCompleted(id);
      await repo.unmarkCompleted(id);
      expect((await row(id)).status, ItemStatus.sold);
    });

    test('markReturned 清空卖出价与卖出日期', () async {
      await repo.markSold(id, sellPriceCents: 180000);
      await repo.markReturned(id);

      final saved = await row(id);
      expect(saved.status, ItemStatus.returned);
      expect(saved.sellPriceCents, isNull);
      expect(saved.sellDate, isNull);
    });

    test('markListed 置为已上架，仍在途', () async {
      await repo.markListed(id);
      expect((await row(id)).status, ItemStatus.listed);
    });

    test('markScrapped 清空卖出价', () async {
      await repo.markSold(id, sellPriceCents: 180000);
      await repo.markScrapped(id);
      final saved = await row(id);
      expect(saved.status, ItemStatus.scrapped);
      expect(saved.sellPriceCents, isNull);
    });

    test('backToStock 从已卖出退回在库并清空卖出信息', () async {
      await repo.markSold(
        id,
        sellPriceCents: 180000,
        sellDate: DateTime(2026, 3, 7),
      );
      await repo.backToStock(id);
      final saved = await row(id);
      expect(saved.status, ItemStatus.inStock);
      expect(saved.sellPriceCents, isNull);
      expect(saved.sellDate, isNull);
    });

    test('delete 是软删，列表看不到但记录还在', () async {
      await repo.delete(id);
      expect(await repo.load(id), isNull);
      expect((await row(id)).deletedAt, isNotNull);
    });
  });

  group('aggregate', () {
    test('默认是全库口径', () async {
      await repo.save(draft(category: '手机'), const []);
      final sold = await repo.save(draft(status: ItemStatus.sold), const []);
      await repo.markSold(sold, sellPriceCents: 120000);

      final agg = await repo.aggregate();
      expect(agg.summary.activeCount, 1);
      expect(agg.summary.soldCount, 1);
    });

    test('给日期范围时只算范围内成交的单', () async {
      final a = await repo.save(draft(), const []);
      await repo.markSold(
        a,
        sellPriceCents: 100,
        sellDate: DateTime(2026, 3, 5),
      );
      final b = await repo.save(draft(), const []);
      await repo.markSold(
        b,
        sellPriceCents: 200,
        sellDate: DateTime(2026, 6, 5),
      );

      final agg = await repo.aggregate(
        dateField: DateField.sell,
        range: DateRange(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 31)),
      );
      expect(agg.summary.soldCount, 1);
    });
  });

  group('图片', () {
    test('addImage 记录尺寸与体积，能按 id 取回原图与缩略图', () async {
      final id = await repo.save(draft(), const []);
      final attId = await repo.addImage(
        itemId: id,
        role: AttachmentRole.buyShot,
        bytes: [1, 2, 3, 4],
        thumb: [9, 9],
        width: 1200,
        height: 1600,
      );

      final meta = (await repo.attachmentsOf(id)).single;
      expect(meta.role, AttachmentRole.buyShot);
      expect(meta.sizeBytes, 4);
      expect(meta.width, 1200);
      expect(meta.height, 1600);

      expect(await repo.fullImage(attId), [1, 2, 3, 4]);
      expect(await repo.thumbImage(attId), [9, 9]);
    });

    test('deleteImage 后列表不再出现，但字节仍可读（墓碑）', () async {
      final id = await repo.save(draft(), const []);
      final attId = await repo.addImage(
        itemId: id,
        role: AttachmentRole.serial,
        bytes: [7],
        thumb: [7],
        width: 10,
        height: 10,
      );

      await repo.deleteImage(attId);
      expect(await repo.attachmentsOf(id), isEmpty);
      expect(await repo.fullImage(attId), [7]);
    });
  });
}
