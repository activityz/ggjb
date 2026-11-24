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

  testWidgets('卡面含标题、序列号、商家保修两日期与三条条款', (tester) async {
    final item = await seed();
    await pumpCard(tester, item);

    expect(find.text('详情机 iPhone 13'), findsOneWidget);
    expect(find.textContaining('SN-ABC123'), findsWidgets);
    expect(find.textContaining('2026-11-24'), findsWidgets);
    expect(find.textContaining('2027-11-24'), findsWidgets);

    for (final term in WarrantyCardView.terms) {
      expect(find.text(term), findsOneWidget, reason: '条款要原文照抄');
    }
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
}
