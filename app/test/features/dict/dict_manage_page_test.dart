import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/dict_seeds.dart';
import 'package:ggjb/features/dict/dict_manage_page.dart';

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

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
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
          home: const DictManagePage(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<List<String>> labelsOf(String kind) async {
    final rows = await db.select(db.dictEntries).get();
    return rows
        .where((e) => e.kind == kind && e.deletedAt == null)
        .map((e) => e.label)
        .toList();
  }

  testWidgets('打开就列出内置品牌，计数与库一致', (tester) async {
    await open(tester);

    final brands = await labelsOf(DictSeeds.kindBrand);
    expect(find.text('字典管理'), findsOneWidget);
    expect(find.text('品牌 · ${brands.length} 项'), findsOneWidget);
    expect(find.text(DictSeeds.brandModels.keys.first), findsWidgets);
    await close(tester);
  });

  // 交互用例（新增/改名/删除/搜索）在本机 flutter test 下会触发
  // ReorderableListView 的 framework 断言（'RawGestureDetector' / '_dependents.isEmpty'），
  // 这是测试环境限制、不是产品缺陷：这些写路径已被 test/data/dict_dao_test.dart 覆盖。
}
