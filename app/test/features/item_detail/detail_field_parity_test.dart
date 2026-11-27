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

/// seam: 详情页的字段展示（真库 + 真页面）。
///
/// 用户的两个抱怨：
/// 1. 编辑页能录「分类」「序列号」，详情页一处都不显示；
/// 2. 品牌 / 型号 / 内存规格 / 颜色被拼成一行 11px 灰字，没有字段名。
/// 这里断言的是结果：六项各自以「字段名 + 值」成行出现，拼接行不再存在。
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

  Future<void> putItem(
    String id, {
    String? brand,
    String? model,
    String? storage,
    String? color,
    String? category,
    String? serial,
    WarrantyStatus warranty = WarrantyStatus.none,
    DateTime? warrantyStart,
    DateTime? warrantyEnd,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: '测试机 $id',
        buyPriceCents: 300000,
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
        status: const Value(ItemStatus.inStock),
        brand: Value(brand),
        model: Value(model),
        storage: Value(storage),
        color: Value(color),
        category: Value(category),
        serial: Value(serial),
        warrantyStatus: Value(warranty),
        warrantyStart: Value(warrantyStart),
        warrantyEnd: Value(warrantyEnd),
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

  Future<void> open(WidgetTester tester, String itemId) async {
    tester.view.physicalSize = const Size(1400, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('品牌/型号/内存规格/颜色/分类/序列号各自成行，不再拼成一行', (tester) async {
    await putItem(
      'p1',
      brand: 'Apple',
      model: 'iPhone 13',
      storage: '128G',
      color: '蓝色',
      category: '手机',
      serial: 'F2LX1234ABCD',
    );

    await open(tester, 'p1');

    for (final label in ['品牌', '型号', '规格', '颜色', '分类', '序列号']) {
      expect(find.text(label), findsOneWidget, reason: '详情页缺少字段名「$label」');
    }
    expect(
      find.text('内存规格'),
      findsNothing,
      reason: '这一项已改名「规格」，旧名字不该再出现',
    );
    for (final value in ['Apple', 'iPhone 13', '128G', '蓝色', '手机', 'F2LX1234ABCD']) {
      expect(find.text(value), findsWidgets, reason: '详情页缺少值「$value」');
    }
    expect(
      find.textContaining('Apple · iPhone 13'),
      findsNothing,
      reason: '品牌型号不该再拼成一行灰字',
    );

    await teardownTree(tester);
  });

  testWidgets('分类与序列号没填时仍占一行，值为「—」', (tester) async {
    await putItem('p2');

    await open(tester, 'p2');

    expect(find.text('分类'), findsOneWidget);
    expect(find.text('序列号'), findsOneWidget);
    expect(
      find.text('—'),
      findsAtLeastNWidgets(2),
      reason: '空分类与空序列号都要显示占位，而不是把整行藏起来',
    );

    await teardownTree(tester);
  });

  testWidgets('厂家保修「无保修」也要有一行', (tester) async {
    await putItem('p3');

    await open(tester, 'p3');

    expect(find.text('无保修'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('厂家保修「已过保」显示状态行', (tester) async {
    await putItem('p4', warranty: WarrantyStatus.expired);

    await open(tester, 'p4');

    expect(find.text('已过保'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('厂家保修「在保」显示起止两行', (tester) async {
    await putItem(
      'p5',
      warranty: WarrantyStatus.active,
      warrantyStart: DateTime(2026, 1, 1),
      warrantyEnd: DateTime(2027, 1, 1),
    );

    await open(tester, 'p5');

    expect(find.text('厂家保修开始'), findsOneWidget);
    expect(find.text('厂家保修到期'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('详情页文字可选中复制，但没有复制按钮', (tester) async {
    await putItem('p6', serial: 'F2LX1234ABCD');

    await open(tester, 'p6');

    expect(
      find.byType(SelectionArea),
      findsWidgets,
      reason: '内容区要被 SelectionArea 包住，值才能长按选中复制',
    );
    expect(find.byIcon(Icons.copy), findsNothing, reason: '不要复制图标');
    expect(find.text('复制'), findsNothing, reason: '不要复制按钮');

    await teardownTree(tester);
  });
}
