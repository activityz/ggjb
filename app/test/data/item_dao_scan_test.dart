import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';

/// seam: 扫码定位时「按主键取一条还没删的记录」。
///
/// 只锁查询口径，不测上层跳转——跳转在 HomeShell 的 widget 测试里覆盖。
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

  Future<void> put(String id, {bool deleted = false}) async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: '测试机 $id',
            buyPriceCents: 100000,
            createdAt: at,
            updatedAt: at,
            deletedAt: Value(deleted ? at : null),
            deviceId: 'dev-test',
          ),
        );
  }

  const activeId = '123e4567-e89b-42d3-a456-426614174000';
  const deletedId = '123e4567-e89b-42d3-a456-426614174001';
  const missingId = '123e4567-e89b-42d3-a456-426614174002';

  test('未删除的记录能按主键取到', () async {
    await put(activeId);

    final item = await dao.findActiveById(activeId);

    expect(item, isNotNull);
    expect(item!.id, activeId);
  });

  test('软删的记录取不到', () async {
    await put(deletedId, deleted: true);

    expect(await dao.findActiveById(deletedId), isNull);
  });

  test('不存在的记录取不到', () async {
    await put(activeId);

    expect(await dao.findActiveById(missingId), isNull);
  });
}
