import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/features/item_detail/item_detail_page.dart';
import 'package:ggjb/features/scan/scan_entry_button.dart';

/// seam: 顶栏扫码入口的四态。
///
/// 有/无入口（平台能力）、命中跳详情、未命中给提示。相机本身通过
/// `scanLauncherProvider` 注入，测试里不碰真实取景。
void main() {
  const activeId = '123e4567-e89b-42d3-a456-426614174000';
  const missingId = '123e4567-e89b-42d3-a456-426614174002';

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> put(String id) async {
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

  Future<void> pumpHarness(
    WidgetTester tester, {
    required bool scanAvailable,
    required String? scanned,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('dev-test'),
          deviceNameProvider.overrideWithValue('测试设备'),
          scanAvailableProvider.overrideWithValue(scanAvailable),
          scanLauncherProvider.overrideWithValue((_) async => scanned),
        ],
        child: MaterialApp(
          theme: buildAppTheme(
            Brightness.light,
          ).copyWith(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            appBar: AppBar(actions: const [ScanEntryButton()]),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('没有摄像头能力的平台不渲染入口', (tester) async {
    await pumpHarness(tester, scanAvailable: false, scanned: null);

    expect(find.byTooltip('扫码'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('有摄像头能力时渲染入口', (tester) async {
    await pumpHarness(tester, scanAvailable: true, scanned: null);

    expect(find.byTooltip('扫码'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('扫到存在的记录时打开详情', (tester) async {
    await put(activeId);
    await pumpHarness(tester, scanAvailable: true, scanned: activeId);

    await tester.tap(find.byTooltip('扫码'));
    await settle(tester);

    expect(find.byType(ItemDetailPage), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('扫到不存在的记录时提示没找到', (tester) async {
    await pumpHarness(tester, scanAvailable: true, scanned: missingId);

    await tester.tap(find.byTooltip('扫码'));
    await settle(tester);

    expect(find.text('没找到这一笔'), findsOneWidget);
    expect(find.byType(ItemDetailPage), findsNothing);

    await teardownTree(tester);
  });
}
