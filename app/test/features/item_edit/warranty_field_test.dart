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

/// seam: ItemEditPage 的「保修」区块 —— 下拉常驻、只有「在保」才展开日期。
///
/// 表单是懒加载的 ListView：屏幕外的控件根本不在 element 树里，
/// 所以每个断言前都要先把它滚进来，否则拿到的是「0 个」而不是「被隐藏了」。
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

  Finder warrantyDropdown() =>
      find.byType(DropdownButtonFormField<WarrantyStatus>);

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

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 80,
    );
    await tester.pump();
  }

  Future<void> pickWarranty(WidgetTester tester, String label) async {
    await scrollTo(tester, warrantyDropdown());
    await tester.tap(warrantyDropdown());
    await settle(tester);
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await settle(tester);
  }

  /// 某个日期字段当前显示的文字（字段本身是 label + 文本，不是 TextField）。
  Finder dateTextIn(String label, String text) => find.descendant(
        of: find
            .ancestor(of: find.text(label), matching: find.byType(InputDecorator))
            .first,
        matching: find.text(text),
      );

  testWidgets('默认无保修：下拉在、两个日期不展开', (tester) async {
    await open(tester);
    await scrollTo(tester, warrantyDropdown());

    expect(warrantyDropdown(), findsOneWidget);
    expect(find.text('无保修'), findsWidgets);
    expect(find.text('保修开始'), findsNothing);
    expect(find.text('保修到期'), findsNothing);
    await close(tester);
  });

  testWidgets('选「在保」后展开两个日期，开始日期预填买入日期', (tester) async {
    await open(tester);
    await pickWarranty(tester, '在保');

    await scrollTo(tester, find.text('保修开始'));
    expect(find.text('保修开始'), findsOneWidget);
    expect(find.text('保修到期'), findsOneWidget);

    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    expect(
      dateTextIn('保修开始', today),
      findsOneWidget,
      reason: '新建时买入日期默认今天，保修开始应跟着预填',
    );
    expect(
      dateTextIn('保修到期', '未填'),
      findsOneWidget,
      reason: '到期日不猜，留给用户选',
    );
    await close(tester);
  });

  testWidgets('在保保存后三个字段都落库', (tester) async {
    await open(tester);
    await type(tester, '名称 *', '保修机');
    await type(tester, '买入价（元）*', '3000');
    await pickWarranty(tester, '在保');
    await tapSave(tester);

    final row = (await db.select(db.items).get()).single;
    expect(row.warrantyStatus, WarrantyStatus.active);
    expect(row.warrantyStart, isNotNull);
    expect(row.warrantyEnd, isNull);
    await close(tester);
  });

  testWidgets('已有在保单改成「已过保」保存后两个日期被清空', (tester) async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'w1',
            title: '旧在保机',
            buyPriceCents: 200000,
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-test',
            status: const Value(ItemStatus.inStock),
            warrantyStatus: const Value(WarrantyStatus.active),
            warrantyStart: Value(DateTime(2025, 5, 1)),
            warrantyEnd: Value(DateTime(2026, 5, 1)),
          ),
        );

    await open(tester, itemId: 'w1');
    await scrollTo(tester, find.text('保修开始'));
    expect(find.text('保修开始'), findsOneWidget);
    expect(dateTextIn('保修到期', '2026-05-01'), findsOneWidget);

    await pickWarranty(tester, '已过保');
    expect(find.text('保修开始'), findsNothing, reason: '不在保就不展开日期');

    await tapSave(tester);

    final row = (await db.select(db.items).get()).single;
    expect(row.warrantyStatus, WarrantyStatus.expired);
    expect(row.warrantyStart, isNull);
    expect(row.warrantyEnd, isNull);
    await close(tester);
  });
}
