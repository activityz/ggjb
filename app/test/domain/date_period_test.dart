import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/date_period.dart';

/// seam: DateRange —— 明细页与看板共用的时间区间换算。
/// 对外闭区间、对内半开：`[startInclusive, endExclusive)`。
void main() {
  group('边界换算', () {
    test('startInclusive 截到当天 0 点', () {
      final r = DateRange(from: DateTime(2026, 10, 5, 18, 30, 15));
      expect(r.startInclusive, DateTime(2026, 10, 5));
    });

    test('endExclusive 是所选日期的次日 0 点，跨月正确', () {
      final r = DateRange(to: DateTime(2026, 10, 31, 23, 59, 59));
      expect(r.endExclusive, DateTime(2026, 11, 1));
    });

    test('endExclusive 跨年正确', () {
      final r = DateRange(to: DateTime(2026, 12, 31));
      expect(r.endExclusive, DateTime(2027, 1, 1));
    });

    test('从 10-31 到 11-01 是两天，不丢数据', () {
      final r = DateRange(
        from: DateTime(2026, 10, 31),
        to: DateTime(2026, 11, 1),
      );
      expect(r.startInclusive, DateTime(2026, 10, 31));
      expect(r.endExclusive, DateTime(2026, 11, 2));
      final span = r.endExclusive!.difference(r.startInclusive!);
      expect(span.inDays, 2);
    });

    test('两端都不限时 start/end 都是 null，isEmpty 为真', () {
      const r = DateRange.all;
      expect(r.isEmpty, isTrue);
      expect(r.startInclusive, isNull);
      expect(r.endExclusive, isNull);
    });

    test('只给一端时不算空', () {
      expect(DateRange(from: DateTime(2026, 1, 1)).isEmpty, isFalse);
      expect(DateRange(to: DateTime(2026, 1, 1)).isEmpty, isFalse);
    });
  });

  group('label', () {
    test('全部时间', () {
      expect(const DateRange().label, '全部时间');
    });

    test('同一天只显示一个日期', () {
      final r = DateRange(from: DateTime(2026, 3, 7), to: DateTime(2026, 3, 7));
      expect(r.label, '2026/03/07');
    });

    test('区间用短横连接，月日补零', () {
      final r = DateRange(from: DateTime(2026, 3, 7), to: DateTime(2026, 4, 9));
      expect(r.label, '2026/03/07 – 2026/04/09');
    });

    test('只有起点是「之后」，只有终点是「之前」', () {
      expect(DateRange(from: DateTime(2026, 5, 1)).label, '2026/05/01 之后');
      expect(DateRange(to: DateTime(2026, 5, 1)).label, '2026/05/01 之前');
    });
  });

  group('预设区间', () {
    test('本月是 1 号到今天', () {
      final r = DateRange.thisMonth(DateTime(2026, 10, 18, 9));
      expect(r.startInclusive, DateTime(2026, 10, 1));
      expect(r.endExclusive, DateTime(2026, 10, 19));
    });

    test('上个月整月，31 天的大月不差一天', () {
      final r = DateRange.lastMonth(DateTime(2026, 11, 5));
      expect(r.startInclusive, DateTime(2026, 10, 1));
      expect(r.endExclusive, DateTime(2026, 11, 1));
      expect(r.endExclusive!.difference(r.startInclusive!).inDays, 31);
    });

    test('上个月跨年：1 月的上个月是去年 12 月', () {
      final r = DateRange.lastMonth(DateTime(2026, 1, 15));
      expect(r.startInclusive, DateTime(2025, 12, 1));
      expect(r.endExclusive, DateTime(2026, 1, 1));
      expect(r.label, '2025/12/01 – 2025/12/31');
    });

    test('上个月遇上 2 月：平年 28 天', () {
      final r = DateRange.lastMonth(DateTime(2026, 3, 10));
      expect(r.endExclusive!.difference(r.startInclusive!).inDays, 28);
      expect(r.label, '2026/02/01 – 2026/02/28');
    });

    test('最近 7 天含今天，共 7 天', () {
      final r = DateRange.lastDays(DateTime(2026, 10, 18), 7);
      expect(r.startInclusive, DateTime(2026, 10, 12));
      expect(r.endExclusive!.difference(r.startInclusive!).inDays, 7);
    });

    test('最近 1 天就是今天一天', () {
      final r = DateRange.lastDays(DateTime(2026, 10, 18), 1);
      expect(r.endExclusive!.difference(r.startInclusive!).inDays, 1);
      expect(r.startInclusive, DateTime(2026, 10, 18));
    });

    test('今年是 1 月 1 日到今天', () {
      final r = DateRange.thisYear(DateTime(2026, 7, 4, 8));
      expect(r.startInclusive, DateTime(2026, 1, 1));
      expect(r.endExclusive, DateTime(2026, 7, 5));
    });
  });

  group('相等性', () {
    test('同一天的不同时刻视为同一区间', () {
      final a = DateRange(
        from: DateTime(2026, 1, 1, 8),
        to: DateTime(2026, 1, 31, 20),
      );
      final b = DateRange(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('端点不同的区间不相等', () {
      expect(
        DateRange(from: DateTime(2026, 1, 1)),
        isNot(DateRange(from: DateTime(2026, 1, 2))),
      );
    });
  });

  test('DateField 的标签覆盖买卖两种口径', () {
    expect(DateField.buy.label, '买入日期');
    expect(DateField.sell.label, '卖出日期');
  });
}
