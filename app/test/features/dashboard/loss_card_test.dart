import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/features/dashboard/dashboard_page.dart';

/// seam: 看板卡片 —— 口径要涵盖贱卖，且每张卡都能用手指点开明细。
///
/// 点击走真实指针事件（`tester.tap`），不直接调回调：曾经出现过
/// 「卡上挂着 onTap 但手指点不动」的真实故障——GlassCard 内部的
/// GestureDetector 无条件注册，抢走竞技场，外层 onTap 收不到事件。
/// 直接调回调的测法对这个故障是瞎的，所以这里必须点真的。
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed(
    String id, {
    required String title,
    required ItemStatus status,
    required int buy,
    int? sell,
  }) async {
    final now = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: title,
        buyPriceCents: buy,
        sellPriceCents: Value(sell),
        createdAt: now,
        updatedAt: now,
        deviceId: 'dev-test',
        status: Value(status),
        sellDate: Value(sell == null ? null : DateTime(2026, 2, 1)),
      ),
    );
  }

  /// 贱卖亏 400 + 退货亏 300，外加一单赚 500 与一件在库。
  Future<void> seedMixed() async {
    await seed(
      'cheap',
      title: '贱卖机',
      status: ItemStatus.sold,
      buy: 100000,
      sell: 60000,
    );
    await seed('ret', title: '退货机', status: ItemStatus.returned, buy: 30000);
    await seed(
      'win',
      title: '赚钱机',
      status: ItemStatus.completed,
      buy: 100000,
      sell: 150000,
    );
    await seed('stock', title: '在库机', status: ItemStatus.inStock, buy: 200000);
  }

  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
          home: const DashboardPage(),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// 等价于「手指点一下」，并等页面切换动画走完。
  Future<void> tapAndSettle(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text(label));
    await tester.pump(const Duration(milliseconds: 800));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('了结亏损卡把贱卖与退货一起算进去', (tester) async {
    await seedMixed();
    await pumpDashboard(tester);

    expect(find.text('了结亏损'), findsOneWidget);
    expect(
      find.textContaining('2 单亏钱'),
      findsOneWidget,
      reason: '贱卖 + 退货，赚钱与在库的不算',
    );
  });

  testWidgets('点了结亏损打开的是亏损明细', (tester) async {
    await seedMixed();
    await pumpDashboard(tester);

    await tapAndSettle(tester, '了结亏损');

    expect(find.text('贱卖机'), findsOneWidget);
    expect(find.text('退货机'), findsOneWidget);
    expect(find.text('赚钱机'), findsNothing);
    expect(find.text('在库机'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  /// 五张卡都要能用手指点开明细。这条曾经全挂：卡里的 GlassCard
  /// 自带手势层，抢走竞技场，外层 onTap 永远收不到点击。
  testWidgets('看板五张卡都能点开明细', (tester) async {
    await seedMixed();
    const titles = ['已到手利润', '未到手利润', '待收货款', '了结亏损', '在途占用'];

    for (final title in titles) {
      await pumpDashboard(tester);
      expect(find.text(title), findsOneWidget, reason: '$title 卡没渲染出来');

      await tapAndSettle(tester, title);

      expect(
        find.widgetWithText(AppBar, title),
        findsOneWidget,
        reason: '点「$title」没打开明细页',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}
