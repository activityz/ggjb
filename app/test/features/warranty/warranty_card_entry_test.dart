import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/features/item_detail/item_detail_page.dart';
import 'package:ggjb/features/warranty/warranty_card_service.dart';
import 'package:image/image.dart' as img;

/// seam: 详情页保修卡区块的三种状态 —— 未卖出给说明、无卡给生成、有卡给查看+重置。
class _Launcher extends StatelessWidget {
  const _Launcher({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ItemDetailPage(itemId: itemId),
            ),
          ),
          child: const Text('打开详情'),
        ),
      ),
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> open(WidgetTester tester, String itemId) async {
    // 详情页很长，用大视口一次渲染完：滚动查找在这种多段文本的页面上
    // 容易命中多个候选，反而把「文案对不对」这件事搅浑。
    tester.view.physicalSize = const Size(1000, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('dev-test'),
          deviceNameProvider.overrideWithValue('测试设备'),
        ],
        child: MaterialApp(
          theme: buildAppTheme(
            Brightness.light,
          ).copyWith(splashFactory: NoSplash.splashFactory),
          home: _Launcher(itemId: itemId),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('打开详情'));
    await settle(tester);
  }

  Future<void> put(String id, {ItemStatus status = ItemStatus.sold}) async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: '卡机 $id',
        buyPriceCents: 300000,
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
        status: Value(status),
        sellPriceCents: Value(status.isRealized ? 400000 : null),
        merchantWarrantyStart: Value(DateTime(2026, 11, 24)),
        merchantWarrantyEnd: Value(DateTime(2027, 11, 24)),
      ),
    );
  }

  /// 一张 1×1 的合法 PNG：`Image.memory` 真会去解码，手写字节糊弄不过去。
  final tinyPng = Uint8List.fromList(
    img.encodePng(img.Image(width: 1, height: 1)),
  );

  testWidgets('未卖出：说明要先标记卖出，没有生成按钮', (tester) async {
    await put('c1', status: ItemStatus.inStock);
    await open(tester, 'c1');

    expect(find.textContaining('标记已卖出后可以生成保修卡'), findsOneWidget);
    expect(find.text('生成保修卡'), findsNothing);
    await close(tester);
  });

  testWidgets('已卖出且没有卡：出现「生成保修卡」', (tester) async {
    await put('c2');
    await open(tester, 'c2');

    expect(find.text('生成保修卡'), findsOneWidget);
    expect(find.text('查看保修卡'), findsNothing);
    await close(tester);
  });

  testWidgets('已有卡：变成「查看保修卡」并出现「重置保修卡」', (tester) async {
    await put('c3');
    await WarrantyCardService(
      db: db,
      attachments: AttachmentDao(db),
      deviceId: 'dev-test',
    ).save('c3', tinyPng);

    await open(tester, 'c3');

    expect(find.text('查看保修卡'), findsOneWidget);
    expect(find.text('重置保修卡'), findsOneWidget);
    expect(find.text('生成保修卡'), findsNothing);
    await close(tester);
  });
}
