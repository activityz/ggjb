import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/domain/date_period.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: `ItemFilter.onlyLoss` → `itemListProvider` 的过滤结果。
///
/// 亏损判据依赖单笔利润（跨商品与费用两张表），所以过滤放在 provider 层、
/// 复用同一份 `ProfitLine` 口径，而不是在 SQL 里另写一套。
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        deviceIdProvider.overrideWithValue('dev-test'),
        deviceNameProvider.overrideWithValue('测试设备'),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// StreamProvider 的首值光靠 `.future` 在纯 test 环境里等不到，
  /// 显式 listen 一次（既有 item_filter_statuses_test 同样是这么写的）。
  Future<List<ItemListRow>> rowsOf(ItemFilter filter) async {
    final done = Completer<List<ItemListRow>>();
    final sub = container.listen(itemListProvider(filter), (_, next) {
      if (next.hasValue && !done.isCompleted) done.complete(next.value);
    });
    addTearDown(sub.close);
    return done.future.timeout(const Duration(seconds: 10));
  }

  Future<void> put(
    String id, {
    required ItemStatus status,
    required int buy,
    int? sell,
    DateTime? sellDate,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: '单 $id',
        buyPriceCents: buy,
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-test',
        status: Value(status),
        sellPriceCents: Value(sell),
        sellDate: Value(sellDate),
      ),
    );
  }

  Future<void> seedFour() async {
    await put('win', status: ItemStatus.completed, buy: 1000, sell: 1500);
    await put(
      'cheap',
      status: ItemStatus.sold,
      buy: 1000,
      sell: 800,
      sellDate: DateTime(2026, 2, 1),
    );
    await put('ret', status: ItemStatus.returned, buy: 700);
    await put('stock', status: ItemStatus.inStock, buy: 900);
  }

  test('onlyLoss 只出单笔利润为负的单', () async {
    await seedFour();

    final rows = await rowsOf(const ItemFilter(onlyLoss: true));

    expect(rows.map((r) => r.item.id).toSet(), {'cheap', 'ret'});
    for (final row in rows) {
      expect(row.profitLine.profitCents, lessThan(0));
    }
  });

  test('不加 onlyLoss 时照旧列出全部', () async {
    await seedFour();

    final rows = await rowsOf(const ItemFilter());

    expect(rows.length, 4);
  });

  test('只看亏损时不会把在库商品算进来', () async {
    await seedFour();

    final rows = await rowsOf(const ItemFilter(onlyLoss: true));

    expect(rows.any((r) => r.item.id == 'stock'), isFalse);
    expect(rows.any((r) => r.item.id == 'win'), isFalse);
  });

  test('onlyLoss 与日期筛选可以叠加', () async {
    await seedFour();

    final rows = await rowsOf(
      ItemFilter(
        onlyLoss: true,
        dateField: DateField.sell,
        range: DateRange(from: DateTime(2026, 1, 1), to: DateTime(2026, 3, 1)),
      ),
    );

    // cheap 的卖出日期在区间内；ret 是退货、没有卖出日期，被日期筛掉。
    expect(rows.map((r) => r.item.id).toList(), ['cheap']);
  });
}
