import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/features/barcode/qr_export.dart';
import 'package:ggjb/features/warranty/warranty_card_view.dart';
import 'package:image/image.dart' as img;

/// seam: WarrantyCardView —— 卡面上有什么、没有什么，以及能不能截成合规 PNG。
///
/// 「不含价格」是这条 seam 的重点：这卡是交给买家的，成本与成交价都不该出现。
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Item> seed() async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: 'warranty-item-0001',
        title: '详情机 iPhone 13',
        brand: const Value('Apple'),
        model: const Value('iPhone 13'),
        storage: const Value('128G'),
        color: const Value('蓝色'),
        buyPriceCents: 300000,
        sellPriceCents: const Value(400000),
        conditionSold: const Value('95新'),
        serial: const Value('SN-ABC123'),
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
        status: const Value(ItemStatus.sold),
        sellDate: Value(DateTime(2026, 11, 24)),
        merchantWarrantyStart: Value(DateTime(2026, 11, 24)),
        merchantWarrantyEnd: Value(DateTime(2027, 11, 24)),
      ),
    );
    return (await db.select(db.items).get()).single;
  }

  Future<void> pumpCard(WidgetTester tester, Item item, {GlobalKey? key}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: WarrantyCardView(item: item),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('卡面印四部分新条款与温馨提示', (tester) async {
    final item = await seed();
    await pumpCard(tester, item);

    expect(find.text('详情机 iPhone 13'), findsOneWidget);
    expect(find.textContaining('SN-ABC123'), findsWidgets);
    expect(find.textContaining('2026-11-24'), findsWidgets);
    expect(find.textContaining('2027-11-24'), findsWidgets);

    for (final heading in [
      '一、保修保障范围',
      '二、不在保修范围（免责条款）',
      '三、售后服务须知',
      '四、店铺服务承诺',
    ]) {
      expect(find.text(heading), findsOneWidget, reason: '缺少小节标题：$heading');
    }
    expect(
      find.textContaining('温馨提示'),
      findsOneWidget,
      reason: '条款结尾的温馨提示也要印上',
    );
  });

  testWidgets('免责条款五条齐全，旧简版条款不再出现', (tester) async {
    final item = await seed();
    await pumpCard(tester, item);

    for (final snippet in [
      '人为损坏：摔裂、变形、屏幕碎裂',
      '私自改装、更换配件、破解系统',
      '正常使用磨损',
      '外力导致的配件损坏',
      '因客户自行刷机、还原、更改硬件',
    ]) {
      expect(
        find.textContaining(snippet),
        findsOneWidget,
        reason: '免责条款缺一条：$snippet',
      );
    }

    expect(find.textContaining('凭本机序列号享受店内保修'), findsNothing);
    expect(find.textContaining('本店店内保修：非人为故障'), findsNothing);
    expect(find.textContaining('①'), findsNothing, reason: '旧编号不该残留');
  });

  testWidgets('卡面不再显示成色', (tester) async {
    final item = await seed();
    await pumpCard(tester, item);

    expect(find.text('成色'), findsNothing);
    expect(find.textContaining('95新'), findsNothing, reason: '成色值也不该出现');
  });

  testWidgets('卡面不出现任何价格与利润字样', (tester) async {
    final item = await seed();
    await pumpCard(tester, item);

    expect(find.textContaining('¥'), findsNothing);
    expect(find.textContaining('3000'), findsNothing);
    expect(find.textContaining('4000'), findsNothing);
    expect(find.textContaining('利润'), findsNothing);
    expect(find.textContaining('成本'), findsNothing);
  });

  testWidgets('截图出来是 1080×1620 的 PNG', (tester) async {
    final item = await seed();
    final key = GlobalKey();
    await pumpCard(tester, item, key: key);
    await tester.pump();

    Uint8List? png;
    await tester.runAsync(() async {
      png = await renderBoundaryPng(key, pixelRatio: warrantyCardPixelRatio);
    });

    expect(png, isNotNull);
    expect(
      png!.sublist(0, 8),
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      reason: 'PNG 魔数',
    );

    final decoded = img.decodePng(png!);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1080);
    expect(decoded.height, 1620);
  });

  /// S4：卡头印店铺 logo。
  ///
  /// 两件事一起验：卡面里真的有那张资源图（结构），以及截出来的 PNG 卡头
  /// 区域确实有深色像素（说明不是透明/空白占位）。旧布局里 logo 位置被
  /// 「保修卡」标题占着，所以像素断言配合结构断言才有区分度。
  testWidgets('卡头有店铺 logo，卡面不出 overflow', (tester) async {
    final item = await seed();
    final key = GlobalKey();
    await pumpCard(tester, item, key: key);
    await tester.pump();

    // 先解码，否则截到的是空白 logo（D6：冷启动首帧是异步的）
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(shopLogoAsset),
        tester.element(find.byType(WarrantyCardView)),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == shopLogoAsset,
      ),
      findsOneWidget,
      reason: '卡头必须用内置的店铺 logo 资源',
    );

    Uint8List? png;
    await tester.runAsync(() async {
      png = await renderBoundaryPng(key, pixelRatio: warrantyCardPixelRatio);
    });
    final decoded = img.decodePng(png!)!;
    expect(decoded.width, 1080);
    expect(decoded.height, 1620);

    // 卡头带：逻辑 y≈18..44 → 物理 54..132
    var dark = 0;
    for (var y = 54; y < 132; y++) {
      for (var x = 60; x < 1020; x++) {
        final p = decoded.getPixel(x, y);
        if (p.r < 120 && p.g < 120 && p.b < 120) dark++;
      }
    }
    expect(dark, greaterThan(500), reason: '卡头应当印上了 logo 的深色笔画');

    expect(tester.takeException(), isNull, reason: '卡面不允许溢出');
  });
}
