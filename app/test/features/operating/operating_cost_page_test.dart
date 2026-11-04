import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/date_period.dart';
import 'package:ggjb/domain/money.dart';
import 'package:ggjb/features/operating/operating_cost_page.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget host({DashboardFilter filter = DashboardFilter.all}) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      deviceIdProvider.overrideWithValue('dev-test'),
      deviceNameProvider.overrideWithValue('测试设备'),
    ],
    child: MaterialApp(
      theme: buildAppTheme(
        Brightness.light,
      ).copyWith(splashFactory: NoSplash.splashFactory),
      home: OperatingCostPage(filter: filter),
    ),
  );

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
    String kind,
    int cents, {
    DateTime? spentAt,
    String? note,
  }) async {
    final at = spentAt ?? DateTime(2026, 3, 7, 10);
    await db
        .into(db.operatingCosts)
        .insert(
          OperatingCostsCompanion.insert(
            id: id,
            kind: kind,
            amountCents: cents,
            spentAt: at,
            note: Value(note),
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-test',
          ),
        );
  }

  testWidgets('空账本提示还没记过，合计为零', (tester) async {
    await tester.pumpWidget(host());
    await settle(tester);

    expect(find.text('还没记过运营成本'), findsOneWidget);
    expect(find.text(Money(0).toYuanString()), findsWidgets);

    await teardownTree(tester);
  });

  testWidgets('有记录时列出类别、日期、金额，标题栏是合计', (tester) async {
    await put('o1', '房租', 300000);
    await put('o2', '快递费', 1200);

    await tester.pumpWidget(host());
    await settle(tester);

    expect(find.text('房租'), findsOneWidget);
    expect(find.text('快递费'), findsOneWidget);
    expect(find.text(Money(301200).toYuanString()), findsWidgets);
    expect(find.text('还没记过运营成本'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('记一笔：选类别、填金额、存下后落到库里并刷新合计', (tester) async {
    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.text('记一笔'));
    await settle(tester);
    expect(find.text('记一笔运营成本'), findsOneWidget);

    // 类别走字典选择器
    await tester.tap(find.byType(TextField).first);
    await settle(tester);
    await tester.tap(find.text('水电').last);
    await settle(tester);

    await tester.enterText(find.widgetWithText(TextField, '例：1200'), '88.8');
    await tester.tap(find.text('存下'));
    await settle(tester);

    final rows = await db.select(db.operatingCosts).get();
    expect(rows, hasLength(1));
    expect(rows.single.kind, '水电');
    expect(rows.single.amountCents, 8880);
    expect(rows.single.deviceId, 'dev-test');

    expect(find.text('记一笔运营成本'), findsNothing);
    expect(find.text('水电'), findsOneWidget);
    expect(find.text(Money(8880).toYuanString()), findsWidgets);

    await teardownTree(tester);
  });

  testWidgets('金额空着不放行，弹窗留在原地', (tester) async {
    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.text('记一笔'));
    await settle(tester);
    await tester.tap(find.byType(TextField).first);
    await settle(tester);
    await tester.tap(find.text('房租').last);
    await settle(tester);

    await tester.tap(find.text('存下'));
    await settle(tester);

    expect(find.text('记一笔运营成本'), findsOneWidget);
    expect(await db.select(db.operatingCosts).get(), isEmpty);

    await teardownTree(tester);
  });

  testWidgets('点已有条目打开编辑，改金额后库里与合计同步', (tester) async {
    await put('o1', '房租', 300000);

    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.text('房租'));
    await settle(tester);
    expect(find.text('改一下'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '例：1200'), '2500');
    await tester.tap(find.text('存下'));
    await settle(tester);

    final rows = await db.select(db.operatingCosts).get();
    expect(rows, hasLength(1));
    expect(rows.single.amountCents, 250000);
    expect(find.text(Money(250000).toYuanString()), findsWidgets);

    await teardownTree(tester);
  });

  testWidgets('删除要先确认，确认后是软删', (tester) async {
    await put('o1', '房租', 300000);

    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await settle(tester);
    expect(find.text('删掉这条？'), findsOneWidget);

    await tester.tap(find.text('删掉'));
    await settle(tester);

    final rows = await db.select(db.operatingCosts).get();
    expect(rows, hasLength(1));
    expect(rows.single.deletedAt, isNotNull);

    await teardownTree(tester);
  });

  // 缺陷#5：operating_cost_page.dart 的删除按钮只调 softDelete(row.id)，
  // 没有 ref.invalidate(operatingCostsProvider/operatingTotalProvider)，
  // 删完列表与合计必须立刻更新，不需要退出页面。
  testWidgets('删除后列表立刻消失、合计归零', (tester) async {
    await put('o1', '房租', 300000);

    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await settle(tester);
    await tester.tap(find.text('删掉'));
    await settle(tester);

    expect(find.text('房租'), findsNothing);
    expect(find.text(Money(0).toYuanString()), findsWidgets);

    await teardownTree(tester);
  });

  testWidgets('筛选非全部时，过滤之外的记录不出现', (tester) async {
    await put('old', '房租', 100000, spentAt: DateTime(2026, 1, 5, 10));
    await put('new', '水电', 20000, spentAt: DateTime(2026, 3, 7, 10));

    await tester.pumpWidget(
      host(
        filter: DashboardFilter(
          range: DateRange(
            from: DateTime(2026, 3, 1),
            to: DateTime(2026, 3, 31),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('水电'), findsOneWidget);
    expect(find.text('房租'), findsNothing);

    await teardownTree(tester);
  });
}
