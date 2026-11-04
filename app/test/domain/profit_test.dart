import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/domain/profit.dart';

ProfitLine line({
  required ItemStatus status,
  required int buy,
  int expense = 0,
  int? sell,
  String id = 'x',
}) => ProfitLine(
  itemId: id,
  status: status,
  buyPriceCents: buy,
  expenseCents: expense,
  sellPriceCents: sell,
);

void main() {
  group('单笔毛利', () {
    test('正常盈利：卖价 - 买价 - 全部费用', () {
      final l = line(
        status: ItemStatus.sold,
        buy: 100000,
        sell: 150000,
        expense: 2000,
      );
      expect(l.profitCents, 48000);
      expect(l.totalCostCents, 102000);
    });

    test('卖出侧与买入侧费用一视同仁', () {
      final a = line(
        status: ItemStatus.sold,
        buy: 1000,
        sell: 2000,
        expense: 100,
      );
      final b = line(
        status: ItemStatus.sold,
        buy: 1000,
        sell: 2000,
        expense: 100,
      );
      expect(a.profitCents, b.profitCents);
      expect(a.profitCents, 900);
    });

    test('亏损单为负数', () {
      final l = line(
        status: ItemStatus.sold,
        buy: 100000,
        sell: 80000,
        expense: 5000,
      );
      expect(l.profitCents, -25000);
    });

    test('卖出价为 null 但状态是 sold（赠出）按 0 计，全额亏损', () {
      final l = line(
        status: ItemStatus.sold,
        buy: 50000,
        sell: null,
        expense: 1000,
      );
      expect(l.profitCents, -51000);
    });

    test('退货：卖出侧费用照扣，计全额亏损', () {
      final l = line(
        status: ItemStatus.returned,
        buy: 30000,
        sell: null,
        expense: 1500,
      );
      expect(l.profitCents, -31500);
      expect(l.isClosed, isTrue);
    });

    test('报废：同退货口径', () {
      final l = line(status: ItemStatus.scrapped, buy: 20000, expense: 800);
      expect(l.profitCents, -20800);
      expect(l.isClosed, isTrue);
    });

    test('在库 / 上架：没有利润，只有资金占用', () {
      for (final s in [ItemStatus.inStock, ItemStatus.listed]) {
        final l = line(status: s, buy: 60000, expense: 1200);
        expect(l.profitCents, isNull);
        expect(l.isClosed, isFalse);
        expect(l.capitalOccupiedCents, 61200);
      }
    });

    test('已了结的没有资金占用', () {
      final l = line(status: ItemStatus.sold, buy: 1000, sell: 2000);
      expect(l.capitalOccupiedCents, 0);
    });

    test('毛利率', () {
      final l = line(
        status: ItemStatus.sold,
        buy: 100000,
        sell: 150000,
        expense: 0,
      );
      expect(l.marginRate, closeTo(0.5, 1e-9));
    });

    test('成本为 0 时毛利率为 null，不除零', () {
      final l = line(status: ItemStatus.sold, buy: 0, sell: 1000, expense: 0);
      expect(l.marginRate, isNull);
      expect(l.profitCents, 1000);
    });
  });

  group('汇总口径', () {
    test('已实现利润只算 sold，不含退回报废', () {
      final agg = ProfitCalculator.aggregate([
        line(id: '1', status: ItemStatus.sold, buy: 1000, sell: 1500), // +500
        line(id: '2', status: ItemStatus.sold, buy: 2000, sell: 2600), // +600
        line(
          id: '3',
          status: ItemStatus.returned,
          buy: 3000,
          expense: 100,
        ), // -3100
        line(id: '4', status: ItemStatus.scrapped, buy: 500), // -500
        line(id: '5', status: ItemStatus.inStock, buy: 8000), // 占用
        line(id: '6', status: ItemStatus.listed, buy: 4000, expense: 200), // 占用
      ]);

      expect(agg.summary.realizedProfitCents, 1100);
      expect(agg.summary.closedLossCents, -3600);
      expect(agg.summary.netProfitCents, -2500);
      expect(agg.summary.capitalOccupiedCents, 12200);
      expect(agg.summary.soldCount, 2);
      expect(agg.summary.lossClosedCount, 2);
      expect(agg.summary.activeCount, 2);
      expect(agg.summary.closedCount, 4);
      expect(agg.realizedCostCents, 3000);
    });

    test('已实现毛利率用已售成本作分母，不混入在途', () {
      final agg = ProfitCalculator.aggregate([
        line(id: '1', status: ItemStatus.sold, buy: 1000, sell: 1500),
        line(id: '2', status: ItemStatus.inStock, buy: 999999),
      ]);
      expect(agg.realizedCostCents, 1000);
      expect(
        agg.summary.realizedMarginRate(agg.realizedCostCents),
        closeTo(0.5, 1e-9),
      );
    });

    test('平均每笔已实现毛利', () {
      final agg = ProfitCalculator.aggregate([
        line(id: '1', status: ItemStatus.sold, buy: 0, sell: 100),
        line(id: '2', status: ItemStatus.sold, buy: 0, sell: 300),
      ]);
      expect(agg.summary.averageRealizedCents, 200);
    });

    test('空集合不崩，平均为 null', () {
      final agg = ProfitCalculator.aggregate(const []);
      expect(agg.summary.realizedProfitCents, 0);
      expect(agg.summary.averageRealizedCents, isNull);
      expect(agg.summary.realizedMarginRate(0), isNull);
      expect(agg.summary, ProfitSummary.empty);
    });

    test('merge 可累加', () {
      final a = ProfitCalculator.aggregate([
        line(id: '1', status: ItemStatus.sold, buy: 1000, sell: 1500),
      ]);
      final b = ProfitCalculator.aggregate([
        line(id: '2', status: ItemStatus.sold, buy: 2000, sell: 2100),
      ]);
      final m = a.summary.merge(b.summary);
      expect(m.realizedProfitCents, 600);
      expect(m.soldCount, 2);
    });
  });

  group('已到账 completed', () {
    test('completed 的毛利与 sold 同口径：卖价 − 买价 − 费用', () {
      final l = line(
        status: ItemStatus.completed,
        buy: 100000,
        sell: 150000,
        expense: 2000,
      );
      expect(l.profitCents, 48000);
      expect(l.isClosed, isTrue);
      expect(l.capitalOccupiedCents, 0);
    });

    test('completed 也计入已实现利润，但不再构成待收货款', () {
      final agg = ProfitCalculator.aggregate([
        line(
          id: '1',
          status: ItemStatus.sold,
          buy: 1000,
          sell: 1500,
        ), // +500，待收 1500
        line(
          id: '2',
          status: ItemStatus.completed,
          buy: 2000,
          sell: 2600,
        ), // +600，已到账
      ]);
      expect(agg.summary.realizedProfitCents, 1100);
      expect(agg.summary.soldCount, 2);
      expect(agg.summary.receivableCount, 1);
      expect(agg.summary.pendingReceivableCents, 1500);
      expect(agg.realizedCostCents, 3000);
    });

    test('待收货款是欠款，不并入净到手', () {
      final agg = ProfitCalculator.aggregate([
        line(id: '1', status: ItemStatus.sold, buy: 1000, sell: 1500),
      ]);
      expect(agg.summary.netProfitCents, 500);
      expect(agg.summary.pendingReceivableCents, 1500);
    });

    test('全部到账时待收归零', () {
      final agg = ProfitCalculator.aggregate([
        line(id: '1', status: ItemStatus.completed, buy: 1000, sell: 1200),
      ]);
      expect(agg.summary.pendingReceivableCents, 0);
      expect(agg.summary.receivableCount, 0);
      expect(agg.summary.realizedProfitCents, 200);
    });

    test('merge 会累加待收款', () {
      final a = ProfitCalculator.aggregate([
        line(id: '1', status: ItemStatus.sold, buy: 1000, sell: 1500),
      ]);
      final b = ProfitCalculator.aggregate([
        line(id: '2', status: ItemStatus.sold, buy: 2000, sell: 2400),
      ]);
      final m = a.summary.merge(b.summary);
      expect(m.pendingReceivableCents, 3900);
      expect(m.receivableCount, 2);
    });

    test('状态语义：只有 sold 待收，只有 completed 已结算', () {
      expect(ItemStatus.sold.isReceivable, isTrue);
      expect(ItemStatus.sold.isSettled, isFalse);
      expect(ItemStatus.completed.isReceivable, isFalse);
      expect(ItemStatus.completed.isSettled, isTrue);
      for (final s in ItemStatus.values) {
        expect(s.isRealized, s == ItemStatus.sold || s == ItemStatus.completed);
      }
    });
  });
  group('置换抵扣', () {
    test('抵扣只留痕，不进利润也不进成本', () {
      const l = ProfitLine(
        itemId: 'trade-1',
        status: ItemStatus.sold,
        buyPriceCents: 70000,
        expenseCents: 0,
        sellPriceCents: 150000,
        tradeInCents: 80000,
      );

      // 利润 = 卖价 − 买价 − 费用；抵扣既不是收入也不是成本。
      expect(l.profitCents, 80000);
      expect(l.totalCostCents, 70000);

      final agg = ProfitCalculator.aggregate([l]);
      expect(agg.summary.realizedProfitCents, 80000);
      expect(agg.summary.tradeInTotalCents, 80000);
    });
  });
}
