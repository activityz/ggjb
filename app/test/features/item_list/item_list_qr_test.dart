import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/features/item_list/item_list_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// seam: 列表每行的二维码入口。
///
/// 抓住「点图标出该条的二维码弹窗」「点卡片其余区域仍进详情」。
void main() {
  const itemId = '123e4567-e89b-42d3-a456-426614174000';
  const title = 'iPhone 13 128G';

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> put() async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: itemId,
            title: title,
            buyPriceCents: 100000,
            createdAt: at,
            updatedAt: at,
            deviceId: 'test-device',
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
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('test-device'),
          deviceNameProvider.overrideWithValue('测试设备'),
        ],
        child: MaterialApp(
          theme: buildAppTheme(
            Brightness.light,
          ).copyWith(splashFactory: NoSplash.splashFactory),
          home: const ItemListPage(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('每行都有二维码按钮，点开是对应记录的弹窗', (tester) async {
    await put();
    await open(tester);

    expect(find.text(title), findsOneWidget);
    expect(find.byTooltip('二维码'), findsOneWidget);

    await tester.tap(find.byTooltip('二维码'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining(itemId.toUpperCase()), findsWidgets);
    expect(find.text(title), findsWidgets);

    await teardownTree(tester);
  });

  testWidgets('点卡片其余区域仍然进详情', (tester) async {
    await put();
    await open(tester);

    await tester.tap(find.text(title));
    await settle(tester);

    expect(find.text('商品详情'), findsOneWidget);

    await teardownTree(tester);
  });
}
