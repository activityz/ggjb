import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/repo/item_repository.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: ItemRepository.save → items 表新增的三列。
///
/// 只验证「写进去什么读出来什么」，不碰编辑页的清空逻辑：
/// 仓储层不做业务收敛，草稿是什么就落什么。
void main() {
  late AppDatabase db;
  late ItemRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ItemRepository(
      db: db,
      itemDao: ItemDao(db),
      attachmentDao: AttachmentDao(db),
      deviceId: 'dev-test',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Item> row(String id) =>
      (db.select(db.items)..where((t) => t.id.equals(id))).getSingle();

  ItemDraft draft({
    String? id,
    WarrantyStatus warrantyStatus = WarrantyStatus.none,
    DateTime? warrantyStart,
    DateTime? warrantyEnd,
  }) => ItemDraft(
    id: id,
    title: '保修机',
    status: ItemStatus.inStock,
    buyPriceCents: 500000,
    warrantyStatus: warrantyStatus,
    warrantyStart: warrantyStart,
    warrantyEnd: warrantyEnd,
  );

  test('在保：三个字段原样落库并读回', () async {
    final start = DateTime(2025, 3, 1);
    final end = DateTime(2026, 3, 1);

    final id = await repo.save(
      draft(
        warrantyStatus: WarrantyStatus.active,
        warrantyStart: start,
        warrantyEnd: end,
      ),
      const [],
    );

    final saved = await row(id);
    expect(saved.warrantyStatus, WarrantyStatus.active);
    expect(saved.warrantyStart, start);
    expect(saved.warrantyEnd, end);

    final loaded = await repo.load(id);
    expect(loaded!.item.warrantyStatus, WarrantyStatus.active);
    expect(loaded.item.warrantyStart, start);
    expect(loaded.item.warrantyEnd, end);
  });

  test('不填保修：默认无保修，两个日期都是 null', () async {
    final id = await repo.save(draft(), const []);

    final saved = await row(id);
    expect(saved.warrantyStatus, WarrantyStatus.none);
    expect(saved.warrantyStart, isNull);
    expect(saved.warrantyEnd, isNull);
  });

  test('编辑时把状态改回无保修会覆盖旧值', () async {
    final id = await repo.save(
      draft(
        warrantyStatus: WarrantyStatus.active,
        warrantyStart: DateTime(2025, 3, 1),
        warrantyEnd: DateTime(2026, 3, 1),
      ),
      const [],
    );

    await repo.save(draft(id: id), const []);

    final saved = await row(id);
    expect(saved.warrantyStatus, WarrantyStatus.none);
    expect(saved.warrantyStart, isNull);
    expect(saved.warrantyEnd, isNull);
  });

  test('旧行（不写保修列）读出来是无保修', () async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'legacy-1',
            title: '老机器',
            buyPriceCents: 100000,
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-old',
            warrantyStatus: const Value.absent(),
          ),
        );

    final saved = await row('legacy-1');
    expect(saved.warrantyStatus, WarrantyStatus.none);
    expect(saved.warrantyStart, isNull);
  });
}
