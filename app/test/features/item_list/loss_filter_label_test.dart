import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/features/item_list/item_list_page.dart';

/// seam: 明细列表的「只看亏损」标签 —— 看板带进来的派生筛选要能看见、能关掉。
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      deviceIdProvider.overrideWithValue('test-device'),
      deviceNameProvider.overrideWithValue('测试设备'),
    ],
    child: MaterialApp(
      theme: buildAppTheme(
        Brightness.light,
      ).copyWith(splashFactory: NoSplash.splashFactory),
      home: child,
    ),
  );

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

  Future<void> seedMixed() async {
    await seed(
      'cheap',
      title: '贱卖机',
      status: ItemStatus.sold,
      buy: 100000,
      sell: 60000,
    );
    await seed(
      'win',
      title: '赚钱机',
      status: ItemStatus.completed,
      buy: 100000,
      sell: 150000,
    );
  }

  /// 列表页有 700ms 入场标记定时器；末尾必须主动卸载，
  /// 让 drift 关闭 stream 的 0ms 定时器在测试内跑完（否则 fake timer 断言会失败）。
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('以 onlyLoss 打开：出现标签，只列亏损单', (tester) async {
    await seedMixed();

    await tester.pumpWidget(
      wrap(
        const ItemListPage(initialFilter: ItemFilter(onlyLoss: true)),
      ),
    );
    await settle(tester);

    expect(find.text('只看亏损'), findsOneWidget);
    expect(find.text('贱卖机'), findsOneWidget);
    expect(find.text('赚钱机'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('点掉标签后恢复全部', (tester) async {
    await seedMixed();

    await tester.pumpWidget(
      wrap(
        const ItemListPage(initialFilter: ItemFilter(onlyLoss: true)),
      ),
    );
    await settle(tester);

    // InputChip 的删除按钮
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, '只看亏损'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await settle(tester);

    expect(find.text('只看亏损'), findsNothing);
    expect(find.text('贱卖机'), findsOneWidget);
    expect(find.text('赚钱机'), findsOneWidget);

    await teardownTree(tester);
  });
}
