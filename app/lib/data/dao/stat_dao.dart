import 'package:drift/drift.dart';

import '../../domain/date_period.dart';
import '../../domain/enums.dart';
import '../../domain/profit.dart';
import '../db/app_database.dart';
import 'item_dao.dart';

/// 一个分组（分类 / 渠道）的汇总。
class GroupStat {
  const GroupStat({
    required this.label,
    required this.closedCount,
    required this.profitCents,
    required this.realizedCents,
    required this.lossCents,
  });

  /// 分组名，空值已经归一成「未分类」/「未知渠道」。
  final String label;

  /// 了结单数（已售 + 退货 + 报废）。
  final int closedCount;

  /// 净到手 = 已实现利润 + 了结亏损。
  final int profitCents;

  final int realizedCents;
  final int lossCents;
}

/// 某个月卖出了几台。
class MonthlySoldCount {
  const MonthlySoldCount({
    required this.year,
    required this.month,
    required this.count,
  });

  final int year;
  final int month;
  final int count;

  /// `2026-10`，给图表的横轴用。
  String get label => '$year-${month.toString().padLeft(2, '0')}';
}

/// 看板的聚合查询。
///
/// 纪律：这里**不自己算钱**。只从 [ItemDao.allProfitLines] 拿 [ProfitLine]，
/// 再用 [ProfitCalculator] 汇总，保证和单笔利润、看板总览是同一套口径。
class StatDao {
  StatDao(this._db);

  final AppDatabase _db;

  Future<List<GroupStat>> byCategory({
    DateField? dateField,
    DateRange? range,
  }) =>
      _group(
        'COALESCE(NULLIF(TRIM(i.category), \'\'), \'未分类\')',
        dateField: dateField,
        range: range,
      );

  Future<List<GroupStat>> bySellPlatform({
    DateField? dateField,
    DateRange? range,
  }) =>
      _group(
        'COALESCE(NULLIF(TRIM(i.sell_platform), \'\'), \'未知渠道\')',
        dateField: dateField,
        range: range,
      );

  Future<List<GroupStat>> _group(
    String labelExpr, {
    DateField? dateField,
    DateRange? range,
  }) async {
    final rows = await _db.customSelect('''
      SELECT i.id AS id, $labelExpr AS k
        FROM items i
       WHERE i.deleted_at IS NULL
    ''').get();

    final labelOf = <String, String>{};
    for (final row in rows) {
      final id = row.read<String>('id');
      labelOf[id] = row.read<String>('k');
    }

    // 时间筛选交给 allProfitLines：它走 SQL 过滤，这里只负责分组。
    final lines = await ItemDao(_db).allProfitLines(
      dateField: dateField,
      range: range,
    );
    final grouped = <String, List<ProfitLine>>{};
    for (final line in lines) {
      grouped.putIfAbsent(labelOf[line.itemId] ?? '未分类', () => []).add(line);
    }

    final stats = <GroupStat>[];
    grouped.forEach((label, groupLines) {
      final agg = ProfitCalculator.aggregate(groupLines);
      final summary = agg.summary;
      if (summary.closedCount == 0 && summary.activeCount == 0) return;
      stats.add(
        GroupStat(
          label: label,
          closedCount: summary.closedCount,
          profitCents: summary.netProfitCents,
          realizedCents: summary.realizedProfitCents,
          lossCents: summary.closedLossCents,
        ),
      );
    });

    stats.sort((a, b) => b.profitCents.compareTo(a.profitCents));
    return stats;
  }

  /// 近 [months] 个月「每个月卖出几台」。
  ///
  /// 口径（需求 3）：`sold` + `completed` 都算卖出，按 `sellDate` 归月。
  /// `sellDate` 为空的已售单无处可归，**不计入**——硬塞进当月会让这个月的
  /// 数字突然虚高，宁可少算也不能算错。
  ///
  /// 在 Dart 侧分组而不是写 `strftime`：SQLite 的 unixepoch + localtime
  /// 会跟着系统时区跑，跨月边缘容易把 10-31 23:00 记到 11 月；
  /// 数据量在几千级，全拉回来分组的成本可以忽略。
  ///
  /// 返回按时间正序、长度恒为 [months]，没有成交的月份补 0。
  Future<List<MonthlySoldCount>> monthlySoldCounts({
    int months = 12,
    DateTime? now,
    DateRange? range,
  }) async {
    final from = range?.startInclusive;
    final to = range?.endExclusive;
    final rows = await (_db.select(_db.items)
          ..where(
            (t) {
              var cond =
                  t.deletedAt.isNull() &
                  t.sellDate.isNotNull() &
                  (t.status.equalsValue(ItemStatus.sold) |
                      t.status.equalsValue(ItemStatus.completed));
              if (from != null) {
                cond = cond & t.sellDate.isBiggerOrEqualValue(from);
              }
              if (to != null) {
                cond = cond & t.sellDate.isSmallerThanValue(to);
              }
              return cond;
            },
          ))
        .get();

    final counts = <String, int>{};
    for (final item in rows) {
      final d = item.sellDate;
      if (d == null) continue;
      final key = '${d.year}-${d.month}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final anchor = now ?? DateTime.now();
    // 从「本月往前数 months-1 个月」开始，缺的补 0。
    var cursor = DateTime(anchor.year, anchor.month - (months - 1));
    final result = <MonthlySoldCount>[];
    for (var i = 0; i < months; i++) {
      result.add(
        MonthlySoldCount(
          year: cursor.year,
          month: cursor.month,
          count: counts['${cursor.year}-${cursor.month}'] ?? 0,
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return result;
  }
}
