import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/features/warranty/warranty_card_service.dart';

/// seam: WarrantyCardService —— 保修卡的存、查、换、重置。
///
/// 只验证「库里现在有几张有效卡」与「日期有没有被顺手改掉」，
/// 不碰截图（那条在 warranty_card_view_test 里用真实渲染验证）。
void main() {
  late AppDatabase db;
  late WarrantyCardService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = WarrantyCardService(
      db: db,
      attachments: AttachmentDao(db),
      deviceId: 'dev-test',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> putItem(String id) async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: '保修卡机',
        buyPriceCents: 300000,
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
        status: const Value(ItemStatus.sold),
        sellPriceCents: const Value(400000),
        merchantWarrantyStart: Value(DateTime(2026, 11, 24)),
        merchantWarrantyEnd: Value(DateTime(2027, 11, 24)),
      ),
    );
  }

  /// 最小合法 PNG 头，够断言「存的是图片字节」。
  Uint8List fakePng(int marker) => Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    marker,
  ]);

  test('保存后查得到，字节原样返回', () async {
    await putItem('i1');
    final png = fakePng(1);

    final id = await service.save('i1', png);
    final latest = await service.latest('i1');

    expect(latest, isNotNull);
    expect(latest!.id, id);
    expect(latest.bytes, png);
    expect(latest.mime, 'image/png');
    expect(latest.width, 1080);
    expect(latest.height, 1620);
    expect(latest.role, AttachmentRole.warrantyCard);
  });

  test('连续保存两次：只留一张有效卡，且是后一张', () async {
    await putItem('i2');

    await service.save('i2', fakePng(1));
    final secondId = await service.save('i2', fakePng(2));

    final all = await (db.select(db.attachments)..where(
          (t) => t.itemId.equals('i2'),
        ))
        .get();
    final alive = all.where((a) => a.deletedAt == null).toList();

    expect(alive, hasLength(1));
    expect(alive.single.id, secondId);
    expect(alive.single.bytes.last, 2);
  });

  test('重置后查不到卡，但商家保修日期保留', () async {
    await putItem('i3');
    await service.save('i3', fakePng(3));

    final removed = await service.reset('i3');

    expect(removed, 1);
    expect(await service.latest('i3'), isNull);

    final item = (await db.select(db.items).get()).single;
    expect(item.merchantWarrantyStart, DateTime(2026, 11, 24));
    expect(item.merchantWarrantyEnd, DateTime(2027, 11, 24));
  });

  test('没有卡的商品查出来是 null', () async {
    await putItem('i4');
    expect(await service.latest('i4'), isNull);
  });

  test('重置后再保存新卡能正常查到', () async {
    await putItem('i5');
    await service.save('i5', fakePng(5));
    await service.reset('i5');

    final newId = await service.save('i5', fakePng(6));
    final latest = await service.latest('i5');

    expect(latest!.id, newId);
    expect(latest.bytes.last, 6);
  });
}
