/// 利润口径的唯一实现。
///
/// **全项目只有这个文件可以决定「赚了多少钱」。** UI、DAO、导出模块都只能
/// 调用这里的函数，不得自己写 `sell - buy`。
///
/// 口径（与 docs/design/0001-architecture.md 第 3 节一致）：
/// - 单笔利润 = 卖出价 − 买入价 − 该商品全部未删除费用（买入侧 + 卖出侧）
/// - **已到手利润** = `completed`（钱已到账）的单笔利润之和
/// - **未到手利润** = `sold`（货走了、钱没到）的单笔利润之和
/// - **已实现利润** = 已到手 + 未到手，即 `sold` + `completed` 的利润之和。
///   钱到没到手不影响「赚了多少」，只影响「落袋了多少」
/// - 待收货款 = `sold` 状态的卖出价之和——是**欠款**不是利润，不并入任何利润
/// - 了结亏损 = `returned` + `scrapped` 的亏损之和（负数）
/// - **总利润** = 已实现利润 + 了结亏损
/// - 在途资金占用 = `inStock` / `listed` 的（买入价 + 已发生费用）之和，
///   单独展示，**不并入利润**
/// - 置换抵扣（[ProfitLine.tradeInCents]）只记账、**不并入利润**：旧机的价值
///   要等它作为新商品再卖出去时结算，否则同一笔钱会被算两次
library;

import 'enums.dart';

/// 单件商品的利润明细。
class ProfitLine {
  const ProfitLine({
    required this.itemId,
    required this.status,
    required this.buyPriceCents,
    required this.expenseCents,
    this.sellPriceCents,
    this.tradeInCents = 0,
  });

  final String itemId;
  final ItemStatus status;
  final int buyPriceCents;
  final int? sellPriceCents;

  /// 该商品所有未删除费用的合计（分）。
  final int expenseCents;

  /// 置换时买家旧机折的价（分）。**不参与利润**，只做展示与汇总。
  ///
  /// 默认 0 而不是 nullable：调用方（DAO/Excel）可以无脑带上这个字段，
  /// 不用到处判空；聚合时 `+=` 也天然正确。
  final int tradeInCents;

  /// 这笔单是不是「以旧换新」：买家拿旧机折了价。
  ///
  /// 只认抵扣金额 > 0 —— 0 和 null 都当没这回事，不然每张单都要多长一个徽章。
  bool get isTradeIn => tradeInCents > 0;

  /// 该商品的总投入（买入价 + 费用）。退货/报废的亏损基数就是它。
  int get totalCostCents => buyPriceCents + expenseCents;

  /// 是否已了结（售出 / 退货 / 报废）。
  bool get isClosed =>
      status != ItemStatus.inStock && status != ItemStatus.listed;

  /// 在途资金占用；仅 [ItemStatus.isActive] 状态有值。
  int get capitalOccupiedCents => status.isActive ? totalCostCents : 0;

  /// 单笔利润。
  ///
  /// 返回 null 表示尚未了结（还在库或在架），此时谈利润没有意义。
  int? get profitCents {
    switch (status) {
      case ItemStatus.sold:
      case ItemStatus.completed:
        // 卖出价为空时按 0 处理：白送/赠出也要把亏损算出来。
        return (sellPriceCents ?? 0) - totalCostCents;
      case ItemStatus.returned:
      case ItemStatus.scrapped:
        // 货没换成钱，但买入价和费用已经花出去，全额计亏。
        return -totalCostCents;
      case ItemStatus.inStock:
      case ItemStatus.listed:
        return null;
    }
  }

  /// 利润率（利润 / 总投入）。总投入为 0 时返回 null，避免除零。
  double? get marginRate {
    final profit = profitCents;
    if (profit == null || totalCostCents == 0) return null;
    return profit / totalCostCents;
  }
}

/// 多条记录的汇总。
class ProfitSummary {
  const ProfitSummary({
    required this.realizedProfitCents,
    required this.settledProfitCents,
    required this.unsettledProfitCents,
    required this.tradeInTotalCents,
    required this.closedLossCents,
    required this.capitalOccupiedCents,
    required this.pendingReceivableCents,
    required this.soldCount,
    required this.receivableCount,
    required this.lossClosedCount,
    required this.activeCount,
  });

  static const ProfitSummary empty = ProfitSummary(
    realizedProfitCents: 0,
    settledProfitCents: 0,
    unsettledProfitCents: 0,
    tradeInTotalCents: 0,
    closedLossCents: 0,
    capitalOccupiedCents: 0,
    pendingReceivableCents: 0,
    soldCount: 0,
    receivableCount: 0,
    lossClosedCount: 0,
    activeCount: 0,
  );

  /// 已卖出（含已到账）商品的利润合计 = [settledProfitCents] + [unsettledProfitCents]。
  final int realizedProfitCents;

  /// **已到手利润**：`completed` 状态的单笔利润之和。
  final int settledProfitCents;

  /// **未到手利润**：`sold` 状态的单笔利润之和——货已经出去了，钱还没到。
  ///
  /// 注意它和 [pendingReceivableCents] 不是一回事：这里是**利润**（卖价 − 成本），
  /// 那里是**货款全额**（卖价）。两个数差着整整一个成本。
  final int unsettledProfitCents;

  /// 置换抵扣合计（分）。只做记录，不进任何利润字段。
  final int tradeInTotalCents;

  /// 退货 + 报废造成的亏损合计，恒为 ≤ 0。
  final int closedLossCents;

  /// 在库 + 已上架的资金占用，恒为 ≥ 0。
  final int capitalOccupiedCents;

  /// 待收货款：`sold` 状态商品的卖出价合计——买家或平台还欠我的钱。
  ///
  /// 这是**货款**不是利润；对应的利润已经进了 [realizedProfitCents]，
  /// 所以它不并入 [netProfitCents]，只在看板上单列提醒。
  final int pendingReceivableCents;

  /// 已卖出总数（含已到账）。
  final int soldCount;

  /// 其中货款还没到手的单数。
  final int receivableCount;

  final int lossClosedCount;
  final int activeCount;

  /// **总利润** = 已实现利润 + 了结亏损（退货报废也一起算进去）。
  int get totalProfitCents => realizedProfitCents + closedLossCents;

  /// 旧名，等同 [totalProfitCents]。保留是因为统计/导出里还有引用，
  /// 新代码一律用 [totalProfitCents]。
  int get netProfitCents => totalProfitCents;

  /// 了结总单数（售出 + 退货 + 报废）。
  int get closedCount => soldCount + lossClosedCount;

  /// 平均每笔已实现利润；没有售出记录时为 null。
  int? get averageRealizedCents =>
      soldCount == 0 ? null : realizedProfitCents ~/ soldCount;

  /// 已实现利润率：利润 / 这些已售商品的成本。
  double? realizedMarginRate(int realizedCostCents) =>
      realizedCostCents == 0 ? null : realizedProfitCents / realizedCostCents;

  ProfitSummary merge(ProfitSummary other) => ProfitSummary(
    realizedProfitCents: realizedProfitCents + other.realizedProfitCents,
    settledProfitCents: settledProfitCents + other.settledProfitCents,
    unsettledProfitCents: unsettledProfitCents + other.unsettledProfitCents,
    tradeInTotalCents: tradeInTotalCents + other.tradeInTotalCents,
    closedLossCents: closedLossCents + other.closedLossCents,
    capitalOccupiedCents: capitalOccupiedCents + other.capitalOccupiedCents,
    pendingReceivableCents:
        pendingReceivableCents + other.pendingReceivableCents,
    soldCount: soldCount + other.soldCount,
    receivableCount: receivableCount + other.receivableCount,
    lossClosedCount: lossClosedCount + other.lossClosedCount,
    activeCount: activeCount + other.activeCount,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfitSummary &&
          realizedProfitCents == other.realizedProfitCents &&
          settledProfitCents == other.settledProfitCents &&
          unsettledProfitCents == other.unsettledProfitCents &&
          tradeInTotalCents == other.tradeInTotalCents &&
          closedLossCents == other.closedLossCents &&
          capitalOccupiedCents == other.capitalOccupiedCents &&
          pendingReceivableCents == other.pendingReceivableCents &&
          soldCount == other.soldCount &&
          receivableCount == other.receivableCount &&
          lossClosedCount == other.lossClosedCount &&
          activeCount == other.activeCount;

  @override
  int get hashCode => Object.hash(
    realizedProfitCents,
    settledProfitCents,
    unsettledProfitCents,
    tradeInTotalCents,
    closedLossCents,
    capitalOccupiedCents,
    pendingReceivableCents,
    soldCount,
    receivableCount,
    lossClosedCount,
    activeCount,
  );
}

/// 汇总器。纯函数，无 IO，可单测。
class ProfitCalculator {
  const ProfitCalculator._();

  /// 把一批 [ProfitLine] 聚合成看板要用的汇总。
  ///
  /// 同时返回已售商品的成本合计（[MarginBasis]），用于计算利润率——
  /// 利润率的分母只能是已售商品的成本，不能混入在途占用。
  static ProfitAggregate aggregate(Iterable<ProfitLine> lines) {
    var settled = 0;
    var unsettled = 0;
    var loss = 0;
    var occupied = 0;
    var pendingReceivable = 0;
    var soldCount = 0;
    var receivableCount = 0;
    var lossCount = 0;
    var activeCount = 0;
    var realizedCost = 0;
    var tradeIn = 0;

    for (final line in lines) {
      // 置换抵扣跟状态无关，一律累加到「已记录但未实现」那一栏。
      tradeIn += line.tradeInCents;
      switch (line.status) {
        case ItemStatus.sold:
          // 货走了钱没到：利润算「未到手」，货款全额另外挂到待收款上。
          unsettled += line.profitCents ?? 0;
          realizedCost += line.totalCostCents;
          soldCount++;
          pendingReceivable += line.sellPriceCents ?? 0;
          receivableCount++;
        case ItemStatus.completed:
          // 钱已到手，不再构成待收款。
          settled += line.profitCents ?? 0;
          realizedCost += line.totalCostCents;
          soldCount++;
        case ItemStatus.returned:
        case ItemStatus.scrapped:
          loss += line.profitCents ?? 0;
          lossCount++;
        case ItemStatus.inStock:
        case ItemStatus.listed:
          occupied += line.capitalOccupiedCents;
          activeCount++;
      }
    }

    return ProfitAggregate(
      summary: ProfitSummary(
        realizedProfitCents: settled + unsettled,
        settledProfitCents: settled,
        unsettledProfitCents: unsettled,
        tradeInTotalCents: tradeIn,
        closedLossCents: loss,
        capitalOccupiedCents: occupied,
        pendingReceivableCents: pendingReceivable,
        soldCount: soldCount,
        receivableCount: receivableCount,
        lossClosedCount: lossCount,
        activeCount: activeCount,
      ),
      realizedCostCents: realizedCost,
    );
  }
}

/// [ProfitCalculator.aggregate] 的返回值：汇总 + 利润率分母。
class ProfitAggregate {
  const ProfitAggregate({
    required this.summary,
    required this.realizedCostCents,
    this.operatingCostCents = 0,
  });

  final ProfitSummary summary;

  /// 已售出商品的总成本，利润率分母。
  final int realizedCostCents;

  /// 这段时间的运营成本（房租、水电、快递…），默认 0。
  ///
  /// 它不进 [summary] —— 那一层只认「单子」的账，运营成本不是某一单的。
  /// 扣减发生在 [netAfterOperatingCents]，由调用方（看板）把统计区间的
  /// 运营成本查出来填进来，这样列表页拿到的 summary 不会被它污染。
  final int operatingCostCents;

  /// 总利润再扣掉运营成本。
  ///
  /// 为什么是这里扣而不是一开始就算：总利润是「卖货挣的」，运营成本是
  /// 「为了卖这些货额外花的」，两者口径不同，混在一起就没法解释数字怎么来的。
  int get netAfterOperatingCents =>
      summary.totalProfitCents - operatingCostCents;

  ProfitAggregate withOperatingCost(int cents) => ProfitAggregate(
    summary: summary,
    realizedCostCents: realizedCostCents,
    operatingCostCents: cents,
  );
}
