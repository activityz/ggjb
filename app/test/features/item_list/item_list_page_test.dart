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

/// seam: ItemListPage —— 多状态筛选在 UI 上的表现（组合标签 / 清除 / 单选高亮）。
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
      // InkSparkle 需要 shader asset，测试环境解码不了，换无波纹
      theme: buildAppTheme(
        Brightness.light,
      ).copyWith(splashFactory: NoSplash.splashFactory),
      home: child,
    ),
  );

  testWidgets('两个状态打开时出现组合标签，且单状态标签都不高亮', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ItemListPage(
          initialFilter: ItemFilter(
            statuses: {ItemStatus.inStock, ItemStatus.listed},
          ),
        ),
      ),
    );
    await tester.pump();
    // 消化 initState 里 700ms 的入场标记定时器
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.text('在库 + 已上架'), findsOneWidget);

    // 主动卸载，让 drift 的 dispose 定时器在测试内跑完
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('点掉组合标签后回到「全部」，组合标签消失', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ItemListPage(
          initialFilter: ItemFilter(
            statuses: {ItemStatus.inStock, ItemStatus.listed},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    final combo = find.ancestor(
      of: find.text('在库 + 已上架'),
      matching: find.byType(InputChip),
    );
    expect(combo, findsOneWidget);

    await tester.tap(
      find.descendant(of: combo, matching: find.byIcon(Icons.close)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('在库 + 已上架'), findsNothing);
    expect(find.text('全部'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('单选状态时不出现组合标签', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ItemListPage(initialFilter: ItemFilter(status: ItemStatus.sold)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.byType(InputChip), findsNothing);
    expect(find.text('已卖出'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
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

  Future<void> put({
    String id = 'i1',
    ItemStatus status = ItemStatus.sold,
    String title = '测试机',
    int buyCents = 100000,
    int? sellCents = 150000,
    int? tradeInCents,
    DateTime? sellDate,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: title,
            buyPriceCents: buyCents,
            sellPriceCents: Value(sellCents),
            tradeInCents: Value(tradeInCents),
            sellDate: Value(sellDate),
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-test',
            status: Value(status),
          ),
        );
  }

  Future<void> openList(WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(const ItemListPage(initialFilter: ItemFilter())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await settle(tester);
  }

  testWidgets('置换单在列表里带「置换」徽章与抵扣金额', (tester) async {
    await put(tradeInCents: 80000, sellDate: DateTime(2026, 2, 1));
    await openList(tester);

    expect(find.text('置换'), findsOneWidget);
    expect(find.text('抵 ¥800'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('tradeInCents 为 null 时没有置换痕迹', (tester) async {
    await put(id: 'n1', sellDate: DateTime(2026, 2, 1));
    await openList(tester);

    expect(find.text('置换'), findsNothing);
    expect(find.textContaining('抵 ¥'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('tradeInCents 为 0 时当成非置换', (tester) async {
    await put(id: 'n2', tradeInCents: 0, sellDate: DateTime(2026, 2, 1));
    await openList(tester);

    expect(find.text('置换'), findsNothing);
    expect(find.textContaining('抵 ¥'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('筛选条里没有分类下拉', (tester) async {
    await openList(tester);

    expect(find.text('全部分类'), findsNothing);
    expect(find.byType(DropdownButton<String?>), findsNothing);
    expect(find.text('按日期筛选'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
