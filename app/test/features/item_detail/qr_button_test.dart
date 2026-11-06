import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/features/item_detail/item_detail_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// seam: 详情页顶栏的二维码入口。
///
/// 只验「点得到、弹得出来」；弹窗内容由 qr_dialog_test 负责。
void main() {
  const itemId = '123e4567-e89b-42d3-a456-426614174000';

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

  Future<void> open(WidgetTester tester) async {
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
          home: const ItemDetailPage(itemId: itemId),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('详情页顶栏能打开二维码弹窗', (tester) async {
    await put();
    await open(tester);

    await tester.tap(find.byTooltip('二维码'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining(itemId.toUpperCase()), findsWidgets);

    await teardownTree(tester);
  });
}
