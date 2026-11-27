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

/// seam: 详情页「图片」模块的缩略图渲染（真库 + 真 provider + 真页面）。
///
/// 用户报的现象：图片那块一直转圈。根因是 `attachments.thumb` 为 NULL
/// （保修卡入库时没写缩略图），而视图把「没有缩略图」当成「还在加载」，
/// 于是渲染 `CircularProgressIndicator` —— 空 thumb 是持久状态，转圈永不停止。
///
/// 所以这里断言的是：**任何**情况下都不允许常驻转圈。
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

  /// 真能解码的 PNG：Image.memory 遇到坏字节会渲染错误占位，测不出「出图」。
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

  Future<void> putAttachment(
    String id,
    String itemId, {
    required Uint8List bytes,
    Uint8List? thumb,
  }) async {
    final at = DateTime(2026, 1, 2, 12);
    await db.into(db.attachments).insert(
      AttachmentsCompanion.insert(
        id: id,
        itemId: itemId,
        role: AttachmentRole.warrantyCard,
        mime: const Value('image/png'),
        bytes: bytes,
        thumb: thumb == null ? const Value.absent() : Value(thumb),
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
    // 视口放大，让整页一次渲染完，省掉滚动带来的抖动
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

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('缩略图为空但有原图：直接出图，不转圈', (tester) async {
    await putItem('a1');
    await putAttachment(
      'att1',
      'a1',
      bytes: realPng(300, 200),
      // 保修卡入库时的真实形态：只有原图，thumb 为空
    );

    await open(tester, 'a1');

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: '空缩略图被当成「加载中」，就会永久转圈——用户报的就是这个',
    );
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
      findsOneWidget,
      reason: '没有缩略图时要回退显示原图',
    );

    await teardownTree(tester);
  });

  testWidgets('缩略图与原图都为空：显示无预览，不转圈', (tester) async {
    await putItem('a2');
    // `attachments.bytes` 是 NOT NULL 列，所以「两列都空」在库里表达为
    // 空 blob；视图要把它和无图同等对待。
    await putAttachment('att2', 'a2', bytes: Uint8List(0));

    await open(tester, 'a2');

    expect(find.text('无预览'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await teardownTree(tester);
  });

  /// S5：真实指针点缩略图要能打开大图。
  ///
  /// 上一轮踩过「卡上挂了 onTap 但手势被内层吃掉」的坑，所以这里不用
  /// 直接调回调，老老实实 `tester.tap`。
  testWidgets('点缩略图打开大图', (tester) async {
    await putItem('a3');
    await putAttachment('att3', 'a3', bytes: realPng(300, 200));
    await open(tester, 'a3');

    final thumb = find.byWidgetPredicate(
      (w) => w is Image && w.image is MemoryImage,
    );
    expect(thumb, findsOneWidget);

    await tester.tap(thumb);
    await settle(tester);

    expect(
      find.byType(InteractiveViewer),
      findsOneWidget,
      reason: '点缩略图应当打开大图弹窗',
    );

    await teardownTree(tester);
  });
}
