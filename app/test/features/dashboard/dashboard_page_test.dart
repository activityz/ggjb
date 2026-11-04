import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/features/dashboard/dashboard_page.dart';
import 'package:ggjb/features/item_list/item_list_page.dart';

/// seam: DashboardPage —— 三颗胶囊必须能下钻，且状态集合与 profit.dart 口径一致。
/// 口径：已卖出 = {sold, completed}；待收 = {sold}；未卖 = {inStock, listed}。
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed(String id, ItemStatus status) async {
    final now = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: '测试机 $id',
            buyPriceCents: 100000,
            sellPriceCents: Value(status.isRealized ? 120000 : null),
            createdAt: now,
            updatedAt: now,
            deviceId: 'dev-test',
            status: Value(status),
          ),
        );
  }

  /// 2 sold + 1 completed + 1 inStock → 已卖出 3 / 待收 2 / 未卖 1
  Future<void> seedMixed() async {
    await seed('a', ItemStatus.sold);
    await seed('b', ItemStatus.sold);
    await seed('c', ItemStatus.completed);
    await seed('d', ItemStatus.inStock);
  }

  Future<void> pumpDashboard(WidgetTester tester) async {
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
    // drift 的 stream 走真实异步，fake clock 推不动，需要 runAsync 让真实
    // 事件循环跑起来，再 pump 把结果画上去。
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> settle(WidgetTester tester) async {
    // 明细页有 700ms 入场定时器，push 之后必须先消化掉
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('点「已卖出 3」下钻，状态集合是 sold + completed', (tester) async {
    await seedMixed();
    await pumpDashboard(tester);

    expect(find.text('已卖出 3'), findsOneWidget);

    await tester.tap(find.text('已卖出 3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    final page = tester.widget<ItemListPage>(find.byType(ItemListPage));
    expect(page.initialFilter?.statuses, const {
      ItemStatus.sold,
      ItemStatus.completed,
    }, reason: '看板「已卖出 3」= sold 2 + completed 1');

    await settle(tester);
  });

  testWidgets('点「待收 2」下钻，状态只有 sold', (tester) async {
    await seedMixed();
    await pumpDashboard(tester);

    expect(find.text('待收 2'), findsOneWidget);

    await tester.tap(find.text('待收 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    final page = tester.widget<ItemListPage>(find.byType(ItemListPage));
    expect(page.initialFilter?.status, ItemStatus.sold);

    await settle(tester);
  });

  testWidgets('看板筛选弹窗里没有「分类」', (tester) async {
    await seedMixed();
    await pumpDashboard(tester);

    await tester.tap(find.text('全部时间'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('全部时间'), findsWidgets);
    expect(find.text('分类'), findsNothing, reason: '分类筛选已移除');

    await settle(tester);
  });
}
