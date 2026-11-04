import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: itemListProvider —— 状态集合过滤必须下推到 SQL，结果集合与看板口径一致。
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        deviceIdProvider.overrideWithValue('test-device'),
        deviceNameProvider.overrideWithValue('测试设备'),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> seed(String id, ItemStatus status) async {
    final now = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: '测试机 $id',
            buyPriceCents: 100000,
            sellPriceCents: Value(status.isRealized ? 120000 : null),
            createdAt: now,
            updatedAt: now,
            deviceId: 'dev-test',
            status: Value(status),
          ),
        );
  }

  test('看板「已卖出」= {sold, completed}，下钻只出这两个状态', () async {
    await seed('a', ItemStatus.sold);
    await seed('b', ItemStatus.completed);
    await seed('c', ItemStatus.inStock);
    await seed('d', ItemStatus.listed);

    final repo = container.read(itemRepositoryProvider);
    final sub = repo.watchList(
      statuses: const {ItemStatus.sold, ItemStatus.completed},
    );
    final rows = await sub.first;

    expect(rows.length, 2, reason: 'sold + completed 恰好两条');
    expect(
      rows.every(
        (r) =>
            r.item.status == ItemStatus.sold ||
            r.item.status == ItemStatus.completed,
      ),
      isTrue,
      reason: '不能混入在库/已上架',
    );
  });

  test('itemListProvider 把 ItemFilter.statuses 透传给 DAO', () async {
    await seed('a', ItemStatus.sold);
    await seed('b', ItemStatus.completed);
    await seed('c', ItemStatus.inStock);

    final filter = ItemFilter(
      statuses: const {ItemStatus.sold, ItemStatus.completed},
    );
    final done = Completer<List<ItemListRow>>();
    final sub = container.listen(itemListProvider(filter), (_, next) {
      if (next.hasValue && !done.isCompleted) done.complete(next.value);
    });
    addTearDown(sub.close);

    final rows = await done.future.timeout(const Duration(seconds: 10));
    expect(rows.length, 2, reason: 'provider 层透传后同样是两条');
  });
}
