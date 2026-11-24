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

/// seam: 详情页里与「商家保修」有关的两个出口 ——
/// 标记已卖出时当场填，以及原本就有的行怎么展示。
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

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
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
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
    await tester.pump();
  }

  String slash(DateTime value) =>
      '${value.year}/${value.month.toString().padLeft(2, '0')}/'
      '${value.day.toString().padLeft(2, '0')}';

  Future<void> put(
    String id, {
    ItemStatus status = ItemStatus.inStock,
    String? serial,
    DateTime? merchantStart,
    DateTime? merchantEnd,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: '详情机',
        buyPriceCents: 300000,
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
        status: Value(status),
        sellPriceCents: Value(status.isRealized ? 400000 : null),
        sellPlatform: Value(status.isRealized ? '闲鱼' : null),
        serial: Value(serial),
        merchantWarrantyStart: Value(merchantStart),
        merchantWarrantyEnd: Value(merchantEnd),
      ),
    );
  }

  testWidgets('标记已卖出弹窗里有商家保修两日期，且预填今天与一年后', (tester) async {
    await put('d1');
    await open(tester, 'd1');
    await scrollTo(tester, find.text('标记已卖出'));
    await tester.tap(find.text('标记已卖出'));
    await settle(tester);

    expect(find.text('商家保修开始'), findsOneWidget);
    expect(find.text('商家保修到期'), findsOneWidget);

    final today = DateTime.now();
    // 弹窗里的日期沿用既有 DateRange.formatDate，是 2026/11/24 这种斜杠写法；
    // 详情页的「时间与渠道」用横杠。两处格式不同是现状，不在这里统一。
    expect(find.text(slash(today)), findsWidgets);
    expect(
      find.text(slash(DateTime(today.year + 1, today.month, today.day))),
      findsWidgets,
    );

    await tester.tap(find.text('取消'));
    await settle(tester);
    await close(tester);
  });

  testWidgets('弹窗里确认后商家保修两日期落库', (tester) async {
    await put('d2');
    await open(tester, 'd2');
    await scrollTo(tester, find.text('标记已卖出'));
    await tester.tap(find.text('标记已卖出'));
    await settle(tester);

    await tester.enterText(find.byType(TextField).at(0), '4000');
    await tester.pump();
    // 卖出渠道是字典字段（readOnly，点开底部选择器），不能直接 enterText。
    await tester.tap(
      find
          .ancestor(
            of: find.text('卖出渠道 *'),
            matching: find.byType(TextField),
          )
          .first,
    );
    await settle(tester);
    await tester.tap(find.text('闲鱼').last);
    await settle(tester);
    await tester.tap(find.text('确定'));
    await settle(tester);

    // 弹窗没关就说明校验没过，先把这个事实断言出来，别让它伪装成落库失败。
    expect(find.text('确定'), findsNothing, reason: '弹窗应该已经关闭');

    final row = (await db.select(db.items).get()).single;
    expect(row.status, ItemStatus.sold);
    expect(row.merchantWarrantyStart, isNotNull);
    expect(row.merchantWarrantyEnd, isNotNull);
    await close(tester);
  });

  testWidgets('已卖出且填了商家保修：详情页展示两行日期', (tester) async {
    await put(
      'd3',
      status: ItemStatus.sold,
      serial: 'SN-D3',
      merchantStart: DateTime(2026, 11, 24),
      merchantEnd: DateTime(2027, 11, 24),
    );
    await open(tester, 'd3');
    await scrollTo(tester, find.text('商家保修开始'));

    expect(find.text('商家保修开始'), findsOneWidget);
    expect(find.text('2026-11-24'), findsWidgets);
    expect(find.text('商家保修到期'), findsOneWidget);
    expect(find.text('2027-11-24'), findsWidgets);
    await close(tester);
  });

  testWidgets('已卖出但没填商家保修：给补填入口，不编日期', (tester) async {
    await put('d4', status: ItemStatus.sold);
    await open(tester, 'd4');
    await scrollTo(tester, find.text('商家保修'));

    expect(find.text('商家保修'), findsOneWidget);
    expect(find.textContaining('未填写'), findsWidgets);
    await close(tester);
  });
}
