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

/// 看板的聚合查询。
///
/// 纪律：这里**不自己算钱**。只从 [ItemDao.allProfitLines] 拿 [ProfitLine]，
/// 再用 [ProfitCalculator] 汇总，保证和单笔毛利、看板总览是同一套口径。
class StatDao {
  StatDao(this._db);

  final AppDatabase _db;

  Future<List<GroupStat>> byCategory() =>
      _group('COALESCE(NULLIF(TRIM(i.category), \'\'), \'未分类\')');

  Future<List<GroupStat>> bySellPlatform() =>
      _group('COALESCE(NULLIF(TRIM(i.sell_platform), \'\'), \'未知渠道\')');

  Future<List<GroupStat>> _group(String labelExpr) async {
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

    final lines = await ItemDao(_db).allProfitLines();
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
}
