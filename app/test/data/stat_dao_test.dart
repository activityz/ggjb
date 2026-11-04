import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/stat_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/date_period.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: StatDao —— 分组统计与月度成交数。
/// 纪律：这里不自己算钱，只把 ProfitLine 交给 ProfitCalculator 汇总。
void main() {
  late AppDatabase db;
  late StatDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = StatDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> put(
    String id, {
    required ItemStatus status,
    DateTime? sellDate,
    String? category,
    String? sellPlatform,
    int buyCents = 100000,
    int sellCents = 120000,
    bool deleted = false,
  }) async {
    final created = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: '测试机 $id',
            buyPriceCents: buyCents,
            sellPriceCents: Value(status.isRealized ? sellCents : null),
            sellDate: Value(sellDate),
            category: Value(category),
            sellPlatform: Value(sellPlatform),
            createdAt: created,
            updatedAt: created,
            deviceId: 'dev-test',
            status: Value(status),
            deletedAt: Value(deleted ? created : null),
          ),
        );
  }

  group('monthlySoldCounts', () {
    test('长度恒为 months，按时间正序，缺的月份补 0', () async {
      await put('a', status: ItemStatus.sold, sellDate: DateTime(2026, 8, 5));
      await put('b', status: ItemStatus.sold, sellDate: DateTime(2026, 9, 1));

      final result = await dao.monthlySoldCounts(
        months: 3,
        now: DateTime(2026, 10, 15),
      );

      expect(result, hasLength(3));
      expect(result.map((r) => '${r.year}-${r.month}'), [
        '2026-8',
        '2026-9',
        '2026-10',
      ]);
      expect(result.map((r) => r.count), [1, 1, 0]);
    });

    test('sold 与 completed 都算卖出，在库与已上架不算', () async {
      await put('a', status: ItemStatus.sold, sellDate: DateTime(2026, 10, 2));
      await put(
        'b',
        status: ItemStatus.completed,
        sellDate: DateTime(2026, 10, 3),
      );
      await put(
        'c',
        status: ItemStatus.inStock,
        sellDate: DateTime(2026, 10, 4),
      );
      await put(
        'd',
        status: ItemStatus.listed,
        sellDate: DateTime(2026, 10, 5),
      );

      final result = await dao.monthlySoldCounts(
        months: 1,
        now: DateTime(2026, 10, 15),
      );
      expect(result.single.count, 2);
    });

    test('已售但没有卖出日期的单不进任何月份（宁可少算）', () async {
      await put('a', status: ItemStatus.sold);
      final result = await dao.monthlySoldCounts(
        months: 2,
        now: DateTime(2026, 10, 15),
      );
      expect(result.map((r) => r.count), [0, 0]);
    });

    test('已软删除的单不计入', () async {
      await put(
        'a',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 2),
        deleted: true,
      );
      final result = await dao.monthlySoldCounts(
        months: 1,
        now: DateTime(2026, 10, 15),
      );
      expect(result.single.count, 0);
    });

    test('给定区间时只统计区间内的卖出日期（左闭右开）', () async {
      await put('a', status: ItemStatus.sold, sellDate: DateTime(2026, 10, 1));
      await put('b', status: ItemStatus.sold, sellDate: DateTime(2026, 10, 20));
      await put('c', status: ItemStatus.sold, sellDate: DateTime(2026, 11, 1));

      final result = await dao.monthlySoldCounts(
        months: 1,
        now: DateTime(2026, 10, 15),
        range: DateRange(
          from: DateTime(2026, 10, 1),
          to: DateTime(2026, 10, 20),
        ),
      );
      expect(result.single.count, 2, reason: '10-20 当天含、11-01 不含');
    });

    test('跨年时月份仍然连续', () async {
      await put('a', status: ItemStatus.sold, sellDate: DateTime(2025, 12, 3));
      final result = await dao.monthlySoldCounts(
        months: 3,
        now: DateTime(2026, 1, 10),
      );
      expect(result.map((r) => '${r.year}-${r.month}'), [
        '2025-11',
        '2025-12',
        '2026-1',
      ]);
      expect(result.map((r) => r.count), [0, 1, 0]);
    });
  });

  group('byCategory', () {
    test('空分类归到「未分类」', () async {
      await put(
        'a',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 2),
        category: '   ',
      );
      final stats = await dao.byCategory();
      expect(stats.single.label, '未分类');
      expect(stats.single.closedCount, 1);
    });

    test('按分类分组，各自统计单数', () async {
      await put(
        'a',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 2),
        category: '手机',
      );
      await put(
        'b',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 3),
        category: '手机',
      );
      await put(
        'c',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 4),
        category: '平板',
      );

      final stats = await dao.byCategory();
      final byLabel = {for (final s in stats) s.label: s.closedCount};
      expect(byLabel['手机'], 2);
      expect(byLabel['平板'], 1);
    });

    test('结果按净利降序', () async {
      // 手机：赚 200；平板：亏 100
      await put(
        'a',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 2),
        category: '手机',
        buyCents: 1000,
        sellCents: 1200,
      );
      await put(
        'b',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 3),
        category: '平板',
        buyCents: 1200,
        sellCents: 1100,
      );

      final stats = await dao.byCategory();
      expect(stats.first.label, '手机');
      expect(stats.last.label, '平板');
      expect(stats.first.profitCents, greaterThan(stats.last.profitCents));
    });

    test('已软删除的单不进分组', () async {
      await put(
        'a',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 2),
        category: '手机',
        deleted: true,
      );
      expect(await dao.byCategory(), isEmpty);
    });
  });

  group('bySellPlatform', () {
    test('空渠道归到「未知渠道」', () async {
      await put('a', status: ItemStatus.sold, sellDate: DateTime(2026, 10, 2));
      final stats = await dao.bySellPlatform();
      expect(stats.single.label, '未知渠道');
    });

    test('按渠道分组', () async {
      await put(
        'a',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 2),
        sellPlatform: '闲鱼',
      );
      await put(
        'b',
        status: ItemStatus.sold,
        sellDate: DateTime(2026, 10, 3),
        sellPlatform: '转转',
      );
      final stats = await dao.bySellPlatform();
      expect(stats.map((s) => s.label).toSet(), {'闲鱼', '转转'});
    });
  });
}
