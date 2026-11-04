import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/features/item_edit/item_edit_page.dart';

class _Launcher extends StatelessWidget {
  const _Launcher({required this.itemId});

  final String? itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => ItemEditPage(itemId: itemId),
            ),
          ),
          child: const Text('打开表单'),
        ),
      ),
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
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

  Finder fieldOf(String label) => find
      .ancestor(of: find.text(label), matching: find.byType(TextField))
      .first;

  Future<void> open(WidgetTester tester, {String? itemId}) async {
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
    await tester.tap(find.text('打开表单'));
    await settle(tester);
  }

  Future<void> type(WidgetTester tester, String label, String text) async {
    final field = fieldOf(label);
    await tester.scrollUntilVisible(
      field,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.enterText(field, text);
    await tester.pump();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await settle(tester);
  }

  testWidgets('名称空着不让保存', (tester) async {
    await open(tester);
    await tapSave(tester);

    expect(find.text('名称不能为空'), findsOneWidget);
    expect(await db.select(db.items).get(), isEmpty);
    await close(tester);
  });

  testWidgets('填名称和买入价就能落库，状态默认在库', (tester) async {
    await open(tester);
    await type(tester, '名称 *', 'iPhone 13');
    await type(tester, '买入价（元）*', '1200');
    await tapSave(tester);

    expect(find.text('记一笔'), findsNothing, reason: '保存成功应该退出表单');
    final row = (await db.select(db.items).get()).single;
    expect(row.title, 'iPhone 13');
    expect(row.buyPriceCents, 120000);
    expect(row.status, ItemStatus.inStock);
    expect(row.deviceId, 'dev-test');
    await close(tester);
  });

  testWidgets('买入价不是数字时报错且不落库', (tester) async {
    await open(tester);
    await type(tester, '名称 *', 'iPhone 13');
    await type(tester, '买入价（元）*', 'abc');
    await tapSave(tester);

    expect(find.text('买入价填一个数字'), findsOneWidget);
    expect(await db.select(db.items).get(), isEmpty);
    await close(tester);
  });

  testWidgets('电池健康超出 0–100 被拦下', (tester) async {
    await open(tester);
    await type(tester, '名称 *', 'iPhone 13');
    await type(tester, '买入价（元）*', '1200');
    await type(tester, '电池健康（%）', '120');
    await tapSave(tester);

    expect(find.text('电池健康填 0–100 的整数'), findsOneWidget);
    expect(await db.select(db.items).get(), isEmpty);
    await close(tester);
  });

  testWidgets('状态选成已卖出却没填卖出价会被拦下', (tester) async {
    await open(tester);
    await type(tester, '名称 *', 'iPhone 13');
    await type(tester, '买入价（元）*', '1200');

    final dropdown = find.byType(DropdownButtonFormField<ItemStatus>);
    await tester.scrollUntilVisible(
      dropdown,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(dropdown);
    await settle(tester);
    await tester.tap(find.text('已卖出').last);
    await settle(tester);

    await tapSave(tester);

    expect(find.text('「已卖出」必须填卖出价'), findsOneWidget);
    expect(await db.select(db.items).get(), isEmpty);
    await close(tester);
  });

  testWidgets('编辑已有商品时预填，保存保留 id 与创建时间', (tester) async {
    final created = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'i1',
            title: '旧标题',
            buyPriceCents: 100000,
            createdAt: created,
            updatedAt: created,
            deviceId: 'seed-device',
            status: const Value(ItemStatus.inStock),
          ),
        );

    await open(tester, itemId: 'i1');
    expect(find.text('编辑'), findsOneWidget);
    final prefilled = tester.widget<TextField>(fieldOf('名称 *'));
    expect(prefilled.controller?.text, '旧标题');

    await type(tester, '名称 *', '新标题');
    await tapSave(tester);

    final row = (await db.select(db.items).get()).single;
    expect(row.id, 'i1');
    expect(row.title, '新标题');
    expect(row.createdAt, created);
    expect(row.deviceId, 'seed-device', reason: '编辑不能改写最初录入设备');
    await close(tester);
  });
}
