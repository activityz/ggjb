import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/repo/item_repository.dart';
import 'package:ggjb/domain/scan_code.dart';

/// seam: 扫码原文 → 一条可用记录。
///
/// 三条结局：格式不对、格式对但库里没有、命中。相机解码不在这里。
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

  const activeId = '123e4567-e89b-42d3-a456-426614174000';
  const deletedId = '123e4567-e89b-42d3-a456-426614174001';
  const missingId = '123e4567-e89b-42d3-a456-426614174002';

  Future<void> put(String id, {bool deleted = false}) async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: '测试机',
            buyPriceCents: 100000,
            createdAt: at,
            updatedAt: at,
            deletedAt: Value(deleted ? at : null),
            deviceId: 'dev-test',
          ),
        );
  }

  test('扫到不是本应用的码，判为格式错误', () async {
    final r = await repo.resolveScan('hello');

    expect(r, isA<ScanMiss>());
    expect((r as ScanMiss).reason, ScanMissReason.malformed);
  });

  test('码值合法但库里没有，判为找不到', () async {
    final r = await repo.resolveScan(missingId);

    expect(r, isA<ScanMiss>());
    expect((r as ScanMiss).reason, ScanMissReason.notFound);
  });

  test('码值合法但记录已删，判为找不到', () async {
    await put(deletedId, deleted: true);

    final r = await repo.resolveScan(deletedId);

    expect(r, isA<ScanMiss>());
    expect((r as ScanMiss).reason, ScanMissReason.notFound);
  });

  test('扫到存在的记录，返回该记录 id', () async {
    await put(activeId);

    final r = await repo.resolveScan(' \r\n$activeId\n');

    expect(r, isA<ScanHit>());
    expect((r as ScanHit).itemId, activeId);
  });
}
