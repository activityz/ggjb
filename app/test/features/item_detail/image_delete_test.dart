import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/features/item_detail/item_detail_page.dart';
import 'package:image/image.dart' as img;

/// seam: 图片的删除入口（真库 + 真页面 + 真指针）。
///
/// 用户的原话是「添加的图片没有办法删除吗?」——删除功能一直在（长按格子），
/// 但页面上没有任何提示，等于没有。这里断言大图里那个可见入口真的能删，
/// 以及取消时不会误删。
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

  Uint8List realPng(int width, int height) {
    final canvas = img.Image(width: width, height: height);
    img.fill(canvas, color: img.ColorRgb8(40, 120, 200));
    return Uint8List.fromList(img.encodePng(canvas));
  }

  Future<void> putItem(String id) async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: '图片机 $id',
        buyPriceCents: 300000,
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
        status: const Value(ItemStatus.inStock),
      ),
    );
  }

  Future<void> putAttachment(String id, String itemId, Uint8List bytes) async {
    final at = DateTime(2026, 1, 2, 12);
    await db.into(db.attachments).insert(
      AttachmentsCompanion.insert(
        id: id,
        itemId: itemId,
        role: AttachmentRole.other,
        mime: const Value('image/png'),
        bytes: bytes,
        sizeBytes: Value(bytes.length),
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> open(WidgetTester tester, String itemId) async {
    tester.view.physicalSize = const Size(1400, 3200);
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

  /// 点缩略图打开大图。
  Future<void> openBigImage(WidgetTester tester) async {
    await tester.tap(
      find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
    );
    await settle(tester);
    expect(find.byType(InteractiveViewer), findsOneWidget, reason: '大图没打开');
  }

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('大图里点「删除」并确认，图片从图片区消失', (tester) async {
    await putItem('d1');
    await putAttachment('attd1', 'd1', realPng(300, 200));

    await open(tester, 'd1');
    await openBigImage(tester);

    expect(find.text('删除'), findsOneWidget, reason: '大图里必须有可见的删除入口');
    await tester.tap(find.text('删除'));
    await settle(tester);
    expect(find.text('删除这张图片'), findsOneWidget, reason: '删除前要先确认');

    await tester.tap(find.text('确定'));
    await settle(tester);

    expect(
      find.textContaining('还没有图片'),
      findsOneWidget,
      reason: '删掉后图片区应该回到空态',
    );
    // 项目里的删除一律是软删除：行还在，deleted_at 落上。
    final rows = await db.select(db.attachments).get();
    expect(rows, hasLength(1));
    expect(rows.single.deletedAt, isNotNull, reason: '删除要真的落 deleted_at');

    await teardownTree(tester);
  });

  testWidgets('点「删除」后取消：图片还在，大图仍打开', (tester) async {
    await putItem('d2');
    await putAttachment('attd2', 'd2', realPng(300, 200));

    await open(tester, 'd2');
    await openBigImage(tester);

    await tester.tap(find.text('删除'));
    await settle(tester);
    await tester.tap(find.text('取消'));
    await settle(tester);

    expect(find.byType(InteractiveViewer), findsOneWidget, reason: '取消后大图不该关');
    expect(find.textContaining('还没有图片'), findsNothing);
    final rows = await db.select(db.attachments).get();
    expect(rows, hasLength(1));
    expect(rows.single.deletedAt, isNull, reason: '取消不能留下删除痕迹');

    await teardownTree(tester);
  });
}
