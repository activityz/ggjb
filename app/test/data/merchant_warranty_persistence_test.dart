import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/repo/item_repository.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: ItemRepository.save → items 表的序列号与商家保修两列。
///
/// 只验证「写进去什么读出来什么」，以及两组保修互不串味；
/// 「卖出必填」是编辑页与详情页的校验，不在这里测（仓储层不做业务收敛）。
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
    String? serial,
    WarrantyStatus warrantyStatus = WarrantyStatus.none,
    DateTime? warrantyStart,
    DateTime? warrantyEnd,
    DateTime? merchantWarrantyStart,
    DateTime? merchantWarrantyEnd,
  }) => ItemDraft(
    id: id,
    title: '保修卡机',
    status: ItemStatus.sold,
    buyPriceCents: 500000,
    serial: serial,
    warrantyStatus: warrantyStatus,
    warrantyStart: warrantyStart,
    warrantyEnd: warrantyEnd,
    merchantWarrantyStart: merchantWarrantyStart,
    merchantWarrantyEnd: merchantWarrantyEnd,
  );

  test('序列号与商家保修原样落库并读回', () async {
    final start = DateTime(2026, 11, 24);
    final end = DateTime(2027, 11, 24);

    final id = await repo.save(
      draft(
        serial: 'SN-ABC123',
        merchantWarrantyStart: start,
        merchantWarrantyEnd: end,
      ),
      const [],
    );

    final saved = await row(id);
    expect(saved.serial, 'SN-ABC123');
    expect(saved.merchantWarrantyStart, start);
    expect(saved.merchantWarrantyEnd, end);

    final loaded = await repo.load(id);
    expect(loaded!.item.serial, 'SN-ABC123');
    expect(loaded.item.merchantWarrantyStart, start);
    expect(loaded.item.merchantWarrantyEnd, end);
  });

  test('两组保修同时存在时各自独立，不互相串味', () async {
    final id = await repo.save(
      draft(
        warrantyStatus: WarrantyStatus.active,
        warrantyStart: DateTime(2025, 3, 1),
        warrantyEnd: DateTime(2026, 3, 1),
        merchantWarrantyStart: DateTime(2026, 11, 24),
        merchantWarrantyEnd: DateTime(2027, 11, 24),
      ),
      const [],
    );

    final saved = await row(id);
    expect(saved.warrantyStatus, WarrantyStatus.active);
    expect(saved.warrantyStart, DateTime(2025, 3, 1));
    expect(saved.warrantyEnd, DateTime(2026, 3, 1));
    expect(saved.merchantWarrantyStart, DateTime(2026, 11, 24));
    expect(saved.merchantWarrantyEnd, DateTime(2027, 11, 24));
  });

  test('不传这三项时：序列号与商家保修为空，厂家保修仍是默认无保修', () async {
    final id = await repo.save(draft(), const []);

    final saved = await row(id);
    expect(saved.serial, isNull);
    expect(saved.merchantWarrantyStart, isNull);
    expect(saved.merchantWarrantyEnd, isNull);
    expect(saved.warrantyStatus, WarrantyStatus.none);
  });

  test('更新已有行时三项可被改写', () async {
    final id = await repo.save(
      draft(
        serial: 'SN-OLD',
        merchantWarrantyStart: DateTime(2026, 1, 1),
        merchantWarrantyEnd: DateTime(2027, 1, 1),
      ),
      const [],
    );

    await repo.save(
      draft(
        id: id,
        serial: 'SN-NEW',
        merchantWarrantyStart: DateTime(2026, 11, 24),
        merchantWarrantyEnd: DateTime(2027, 11, 24),
      ),
      const [],
    );

    final saved = await row(id);
    expect(saved.serial, 'SN-NEW');
    expect(saved.merchantWarrantyStart, DateTime(2026, 11, 24));
    expect(saved.merchantWarrantyEnd, DateTime(2027, 11, 24));
  });

  test('Companion 直写也能落这三列（导入路径走值对象）', () async {
    final now = DateTime(2026, 11, 24, 10);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'raw-1',
            title: '直写',
            status: const Value(ItemStatus.inStock),
            buyPriceCents: 100,
            createdAt: now,
            updatedAt: now,
            deviceId: 'dev-test',
            serial: const Value('SN-RAW'),
            merchantWarrantyStart: Value(DateTime(2026, 11, 24)),
            merchantWarrantyEnd: Value(DateTime(2027, 11, 24)),
          ),
        );

    final saved = await row('raw-1');
    expect(saved.serial, 'SN-RAW');
    expect(saved.merchantWarrantyStart, DateTime(2026, 11, 24));
  });
}
