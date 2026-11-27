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
import 'package:ggjb/features/item_detail/image_saver.dart';
import 'package:ggjb/features/item_detail/item_detail_page.dart';
import 'package:image/image.dart' as img;

/// seam: 详情页大图弹窗里的「保存」入口（真库 + 真页面 + 真指针点击）。
///
/// 上一轮踩过「卡上挂了 onTap 但手势被内层吃掉」的坑（看板五张卡全部点不动），
/// 所以这里不用直接调回调，老老实实 `tester.tap` 走真实指针事件。
/// 系统「另存为」对话框本身由 `ImageSaver` 的注入点挡掉，只断言我们这一侧的决定。
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

  Future<void> open(
    WidgetTester tester,
    String itemId,
    ImageSaver saver,
  ) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('dev-test'),
          deviceNameProvider.overrideWithValue('测试设备'),
          imageSaverProvider.overrideWithValue(saver),
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

  testWidgets('点大图里的「保存」把原图交给保存器', (tester) async {
    final bytes = realPng(300, 200);
    await putItem('b1');
    await putAttachment('attb1', 'b1', bytes);

    final calls = <({String fileName, Uint8List bytes})>[];
    final saver = ImageSaver(
      saveBytes: ({required fileName, required bytes}) async {
        calls.add((fileName: fileName, bytes: bytes));
        return '/tmp/$fileName';
      },
      clock: () => DateTime(2026, 11, 24, 17, 30, 5),
    );

    await open(tester, 'b1', saver);

    await tester.tap(
      find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
    );
    await settle(tester);
    expect(find.byType(InteractiveViewer), findsOneWidget, reason: '大图没打开');

    expect(find.text('保存'), findsOneWidget, reason: '大图里必须有保存入口');
    await tester.tap(find.text('保存'));
    await settle(tester);

    expect(calls.length, 1);
    expect(calls.single.fileName, 'ggjb-图片机 b1-20261124-173005.png');
    expect(calls.single.bytes, bytes, reason: '交出去的必须是原图字节');
    expect(find.textContaining('已保存'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
