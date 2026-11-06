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

/// seam: ItemDetailPage「时间与渠道」里的保修行。
///
/// 只认状态、不认日期：在保才展示起止日；已过保只留一行「已过保」；
/// 无保修什么都不显示（旧单据不该凭空长出一行「无保修」）。
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
    String id, {
    WarrantyStatus status = WarrantyStatus.none,
    DateTime? start,
    DateTime? end,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: '保修机 $id',
            buyPriceCents: 300000,
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-test',
            status: const Value(ItemStatus.inStock),
            warrantyStatus: Value(status),
            warrantyStart: Value(start),
            warrantyEnd: Value(end),
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
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 80,
    );
    await tester.pump();
  }

  testWidgets('在保：展示保修开始与到期', (tester) async {
    await put(
      'w1',
      status: WarrantyStatus.active,
      start: DateTime(2025, 3, 1),
      end: DateTime(2026, 3, 1),
    );
    await open(tester, 'w1');

    await scrollTo(tester, find.text('保修开始'));
    expect(find.text('保修开始'), findsOneWidget);
    expect(find.text('2025-03-01'), findsOneWidget);
    expect(find.text('保修到期'), findsOneWidget);
    expect(find.text('2026-03-01'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('在保但日期没填：显示破折号而不是报错', (tester) async {
    await put('w2', status: WarrantyStatus.active);
    await open(tester, 'w2');

    await scrollTo(tester, find.text('保修开始'));
    expect(find.text('保修开始'), findsOneWidget);
    expect(find.text('保修到期'), findsOneWidget);
    expect(find.text('—'), findsWidgets);

    await teardownTree(tester);
  });

  testWidgets('已过保：只留一行「已过保」，不展示日期', (tester) async {
    await put(
      'w3',
      status: WarrantyStatus.expired,
      start: DateTime(2024, 1, 1),
      end: DateTime(2025, 1, 1),
    );
    await open(tester, 'w3');

    await scrollTo(tester, find.text('已过保'));
    expect(find.text('已过保'), findsOneWidget);
    expect(find.text('保修开始'), findsNothing);
    expect(find.text('2024-01-01'), findsNothing);

    await teardownTree(tester);
  });

  testWidgets('无保修：一行都不显示', (tester) async {
    await put('w4');
    await open(tester, 'w4');

    await scrollTo(tester, find.text('买入成色'));
    expect(find.text('保修'), findsNothing);
    expect(find.text('无保修'), findsNothing);
    expect(find.text('保修开始'), findsNothing);

    await teardownTree(tester);
  });
}
