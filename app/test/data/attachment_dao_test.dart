import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: AttachmentDao —— 列表只读 meta，详情页才拉 BLOB；删的是墓碑。
void main() {
  late AppDatabase db;
  late AttachmentDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = AttachmentDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedItem(String id) async {
    final now = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: '测试机 $id',
            buyPriceCents: 100000,
            createdAt: now,
            updatedAt: now,
            deviceId: 'dev-test',
          ),
        );
  }

  Future<String> addAttachment(
    String id, {
    String itemId = 'item-1',
    DateTime? createdAt,
    DateTime? updatedAt,
    Uint8List? thumb,
    int sizeBytes = 3,
  }) async {
    final stamp = createdAt ?? DateTime(2026, 1, 1, 12);
    await dao.insert(
      AttachmentsCompanion.insert(
        id: id,
        itemId: itemId,
        role: AttachmentRole.buyShot,
        bytes: Uint8List.fromList([1, 2, 3]),
        thumb: Value(thumb),
        width: const Value(1080),
        height: const Value(1440),
        sizeBytes: Value(sizeBytes),
        createdAt: stamp,
        updatedAt: updatedAt ?? stamp,
        deviceId: 'dev-test',
      ),
    );
    return id;
  }

  test('listMeta 返回元数据，按 createdAt 升序', () async {
    await seedItem('item-1');
    await addAttachment('b', createdAt: DateTime(2026, 1, 2));
    await addAttachment('a', createdAt: DateTime(2026, 1, 1));

    final metas = await dao.listMeta('item-1');
    expect(metas.map((m) => m.id), ['a', 'b']);
    final first = metas.first;
    expect(first.itemId, 'item-1');
    expect(first.role, AttachmentRole.buyShot);
    expect(first.width, 1080);
    expect(first.height, 1440);
    expect(first.sizeBytes, 3);
  });

  test('listMeta 只返回指定商品的附件', () async {
    await seedItem('item-1');
    await seedItem('item-2');
    await addAttachment('a', itemId: 'item-1');
    await addAttachment('b', itemId: 'item-2');
    final metas = await dao.listMeta('item-1');
    expect(metas.map((m) => m.id), ['a']);
  });

  test('软删除后 listMeta 不再返回，但字节仍在表里', () async {
    await seedItem('item-1');
    await addAttachment('a');
    await dao.softDelete('a', now: DateTime(2026, 2, 1));

    expect(await dao.listMeta('item-1'), isEmpty);
    expect(await dao.bytesOf('a'), Uint8List.fromList([1, 2, 3]));
  });

  test('thumbOf 与 bytesOf 各自取对应字段', () async {
    await seedItem('item-1');
    await addAttachment('a', thumb: Uint8List.fromList([9, 9]));
    expect(await dao.thumbOf('a'), Uint8List.fromList([9, 9]));
    expect(await dao.bytesOf('a'), Uint8List.fromList([1, 2, 3]));
  });

  test('没有缩略图时 thumbOf 返回 null', () async {
    await seedItem('item-1');
    await addAttachment('a');
    expect(await dao.thumbOf('a'), isNull);
  });

  test('不存在的附件 id 两个取字节接口都返回 null，不抛异常', () async {
    expect(await dao.thumbOf('nope'), isNull);
    expect(await dao.bytesOf('nope'), isNull);
  });

  test('allForSync 带上元数据，按 updatedAt 过滤增量', () async {
    await seedItem('item-1');
    await addAttachment('a', updatedAt: DateTime(2026, 1, 1));
    await addAttachment('b', updatedAt: DateTime(2026, 3, 1));

    final all = await dao.allForSync();
    expect(all.map((c) => c.id.value), ['a', 'b']);

    final since = await dao.allForSync(since: DateTime(2026, 2, 1));
    expect(since.map((c) => c.id.value), ['b']);
  });

  test('allForSync 不携带 BLOB 内容（图片字节走独立通道）', () async {
    await seedItem('item-1');
    await addAttachment('a');
    final companions = await dao.allForSync();
    final c = companions.single;
    // Companion 里只填了元数据列，bytes/thumb 不在同步载荷中
    final filled = <String>[
      if (c.id.present) 'id',
      if (c.bytes.present) 'bytes',
      if (c.thumb.present) 'thumb',
    ];
    expect(filled, ['id']);
  });
}
