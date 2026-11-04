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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> put(
    String id,
    ItemStatus status, {
    int? sellCents,
    DateTime? sellDate,
    int? tradeInCents,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: '测试机 $id',
            buyPriceCents: 100000,
            sellPriceCents: Value(sellCents),
            sellDate: Value(sellDate),
            tradeInCents: Value(tradeInCents),
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-test',
            status: Value(status),
          ),
        );
  }

  Future<void> open(WidgetTester tester, String itemId) async {
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
    expect(find.text('商品详情'), findsOneWidget);
    // 状态按钮在页面底部，先把列表滚到底。
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
    }
  }

  Future<Item?> rowOf(String id) =>
      (db.select(db.items)..where((t) => t.id.equals(id))).getSingleOrNull();

  testWidgets('在库时能上架、能卖出、能报废，没有退回类按钮', (tester) async {
    await put('i1', ItemStatus.inStock);
    await open(tester, 'i1');

    expect(find.text('标记已上架'), findsOneWidget);
    expect(find.text('标记已卖出'), findsOneWidget);
    expect(find.text('报废'), findsOneWidget);
    expect(find.text('标记已到账'), findsNothing);
    expect(find.text('回到在库'), findsNothing);
    expect(find.text('买家退货'), findsNothing);
    expect(find.text('退回已卖出'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('已上架时仍然能卖出，能回到在库', (tester) async {
    await put('i1', ItemStatus.listed);
    await open(tester, 'i1');

    expect(find.text('标记已卖出'), findsOneWidget);
    expect(find.text('回到在库'), findsOneWidget);
    expect(find.text('标记已上架'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('已卖出时重点是「标记已到账」，也能退货', (tester) async {
    await put('i1', ItemStatus.sold, sellCents: 150000);
    await open(tester, 'i1');

    expect(find.text('标记已到账'), findsOneWidget);
    expect(find.text('买家退货'), findsOneWidget);
    expect(find.text('标记已卖出'), findsNothing);
    expect(find.text('报废'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('已到账只能退回已卖出，不给报废与回库', (tester) async {
    await put('i1', ItemStatus.completed, sellCents: 150000);
    await open(tester, 'i1');

    expect(find.text('退回已卖出'), findsOneWidget);
    expect(find.text('报废'), findsNothing);
    expect(find.text('回到在库'), findsNothing);
    expect(find.text('标记已到账'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('点「标记已上架」后库里变 listed，按钮跟着换', (tester) async {
    await put('i1', ItemStatus.inStock);
    await open(tester, 'i1');

    await tester.tap(find.text('标记已上架'));
    await settle(tester);

    expect((await rowOf('i1'))!.status, ItemStatus.listed);
    expect(find.text('回到在库'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('点「标记已到账」把 sold 推进到 completed', (tester) async {
    await put('i1', ItemStatus.sold, sellCents: 150000);
    await open(tester, 'i1');

    await tester.tap(find.text('标记已到账'));
    await settle(tester);
    // 到账会放粒子，1.5s 后自己收掉，不消化会报 timer 未完成。
    await tester.pump(const Duration(milliseconds: 1600));

    expect((await rowOf('i1'))!.status, ItemStatus.completed);
    expect(find.text('退回已卖出'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('退货把卖出价和卖出日期一起清掉', (tester) async {
    await put(
      'i1',
      ItemStatus.sold,
      sellCents: 150000,
      sellDate: DateTime(2026, 2, 1),
    );
    await open(tester, 'i1');

    await tester.tap(find.text('买家退货'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await settle(tester);

    final row = await rowOf('i1');
    expect(row!.status, ItemStatus.returned);
    expect(row.sellPriceCents, isNull);
    expect(row.sellDate, isNull);

    await teardownTree(tester);
  });

  testWidgets('「退回已卖出」把 completed 拉回 sold', (tester) async {
    await put('i1', ItemStatus.completed, sellCents: 150000);
    await open(tester, 'i1');

    await tester.tap(find.text('退回已卖出'));
    await settle(tester);

    expect((await rowOf('i1'))!.status, ItemStatus.sold);

    await teardownTree(tester);
  });

  /// 打开详情页但不滚到底：页头与卖出信息区在顶部，滚下去会被回收。
  Future<void> openTop(WidgetTester tester, String itemId) async {
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
    expect(find.text('商品详情'), findsOneWidget);
  }

  testWidgets('置换单详情标出「置换」与旧机抵扣金额', (tester) async {
    await put(
      't1',
      ItemStatus.sold,
      sellCents: 150000,
      sellDate: DateTime(2026, 2, 1),
      tradeInCents: 80000,
    );
    await openTop(tester, 't1');

    expect(find.textContaining('置换'), findsWidgets);
    expect(find.text('旧机抵扣'), findsOneWidget);
    expect(find.text('¥800'), findsWidgets);

    await teardownTree(tester);
  });

  testWidgets('非置换单详情没有置换痕迹', (tester) async {
    await put(
      'n1',
      ItemStatus.sold,
      sellCents: 150000,
      sellDate: DateTime(2026, 2, 1),
    );
    await openTop(tester, 'n1');

    expect(find.textContaining('置换'), findsNothing);
    expect(find.text('旧机抵扣'), findsNothing);

    await teardownTree(tester);
  });
}
