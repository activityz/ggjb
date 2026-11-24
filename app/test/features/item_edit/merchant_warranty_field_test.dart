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

/// seam: ItemEditPage 的「序列号」与「商家保修」两个新区块。
///
/// 抓：卖出时预填当天/+1 年、已有值不被覆盖、缺日期时保存被拦、序列号落库。
/// 漏：系统日期选择器的内部行为（只验证入口与显示值）。
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

  Finder statusDropdown() => find.byType(DropdownButtonFormField<ItemStatus>);

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

  Future<void> pickStatus(WidgetTester tester, String label) async {
    await scrollTo(tester, statusDropdown());
    await tester.tap(statusDropdown());
    await settle(tester);
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await settle(tester);
  }

  String ymd(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Finder dateTextIn(String label, String text) => find.descendant(
    of: find
        .ancestor(of: find.text(label), matching: find.byType(InputDecorator))
        .first,
    matching: find.text(text),
  );

  Future<void> insertSold({
    required String id,
    String? serial,
    DateTime? merchantStart,
    DateTime? merchantEnd,
    bool withSellPrice = true,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: '已卖出机',
        buyPriceCents: 300000,
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
        status: const Value(ItemStatus.sold),
        sellPriceCents: Value(withSellPrice ? 400000 : null),
        sellPlatform: const Value('闲鱼'),
        serial: Value(serial),
        merchantWarrantyStart: Value(merchantStart),
        merchantWarrantyEnd: Value(merchantEnd),
      ),
    );
  }

  testWidgets('在库商品不显示商家保修日期', (tester) async {
    await open(tester);
    await scrollTo(tester, find.text('卖出情况'));

    expect(find.text('商家保修开始'), findsNothing);
    expect(find.text('商家保修到期'), findsNothing);
    await close(tester);
  });

  testWidgets('切到「已卖出」后两日期出现，并预填今天与一年后', (tester) async {
    await open(tester);
    await pickStatus(tester, '已卖出');

    final today = DateTime.now();
    final nextYear = DateTime(today.year + 1, today.month, today.day);

    await scrollTo(tester, find.text('商家保修开始'));
    expect(find.text('商家保修开始'), findsOneWidget);
    expect(find.text('商家保修到期'), findsOneWidget);
    expect(dateTextIn('商家保修开始', ymd(today)), findsOneWidget);
    expect(dateTextIn('商家保修到期', ymd(nextYear)), findsOneWidget);
    await close(tester);
  });

  testWidgets('已有商家保修值重新打开页面时不被预填覆盖', (tester) async {
    await insertSold(
      id: 's1',
      merchantStart: DateTime(2026, 11, 24),
      merchantEnd: DateTime(2027, 11, 24),
    );

    await open(tester, itemId: 's1');
    await scrollTo(tester, find.text('商家保修开始'));

    expect(dateTextIn('商家保修开始', '2026-11-24'), findsOneWidget);
    expect(dateTextIn('商家保修到期', '2027-11-24'), findsOneWidget);
    await close(tester);
  });

  testWidgets('已卖出但商家保修为空：保存被拦并点明缺的是商家保修', (tester) async {
    await insertSold(id: 's2');

    await open(tester, itemId: 's2');
    await tapSave(tester);

    expect(find.textContaining('商家保修'), findsWidgets);
    final rows = await db.select(db.items).get();
    expect(rows.single.merchantWarrantyStart, isNull, reason: '被拦就不该落库');
    await close(tester);
  });

  testWidgets('序列号填了会落库', (tester) async {
    await open(tester);
    await type(tester, '名称 *', '序列号机');
    await type(tester, '买入价（元）*', '1000');
    await type(tester, '序列号', 'SN-ABC123');
    await tapSave(tester);

    final row = (await db.select(db.items).get()).single;
    expect(row.serial, 'SN-ABC123');
    await close(tester);
  });

  testWidgets('序列号留空保存后为空', (tester) async {
    await open(tester);
    await type(tester, '名称 *', '无序列号机');
    await type(tester, '买入价（元）*', '1000');
    await tapSave(tester);

    final row = (await db.select(db.items).get()).single;
    expect(row.serial, isNull);
    await close(tester);
  });
}
