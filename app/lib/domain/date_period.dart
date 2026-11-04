/// 时间区间的唯一实现。
///
/// 明细页与看板的时间筛选共用这一套区间计算，否则两处各自拼
/// `DateTime(y, m, 1)`，迟早差一天或差一个时区。
///
/// 约定：对外是**闭区间**（选了 10-01 到 10-31 含这两天整天），
/// 转给 SQL 时用 `[startInclusive, endExclusive)` 半开写。
/// 用右闭会踩两个坑：`DateTime(y, m, 31, 23, 59, 59)` 丢掉 59.999 秒的数据；
/// 月底没有 31 号时 `DateTime(y, m + 1, 0)` 又容易算错。
library;

/// 按哪一列筛。
enum DateField {
  buy('买入日期'),
  sell('卖出日期');

  const DateField(this.label);

  final String label;
}

/// 自定义时间段。
///
/// 两端都可以为空 —— 空即「不限」，所以「全部时间」就是一个两端都空的区间。
/// 这样页面不必额外维护「有没有在筛」这个状态：`isEmpty` 就是答案。
class DateRange {
  const DateRange({this.from, this.to});

  /// 不限时间。
  static const DateRange all = DateRange();

  final DateTime? from;
  final DateTime? to;

  bool get isEmpty => from == null && to == null;

  /// 起点（含）。截到当天 0 点。
  DateTime? get startInclusive =>
      from == null ? null : DateTime(from!.year, from!.month, from!.day);

  /// 终点（不含）。选了 10-31 就是 11-01 00:00 作上界。
  DateTime? get endExclusive =>
      to == null ? null : DateTime(to!.year, to!.month, to!.day + 1);

  DateRange withFrom(DateTime? value) => DateRange(from: value, to: to);

  DateRange withTo(DateTime? value) => DateRange(from: from, to: value);

  static String _two(int v) => v < 10 ? '0$v' : '$v';

  static String formatDate(DateTime d) =>
      '${d.year}/${_two(d.month)}/${_two(d.day)}';

  String get label {
    final f = from;
    final t = to;
    if (f == null && t == null) return '全部时间';
    if (f != null && t != null) {
      if (f.year == t.year && f.month == t.month && f.day == t.day) {
        return formatDate(f);
      }
      return '${formatDate(f)} – ${formatDate(t)}';
    }
    if (f != null) return '${formatDate(f)} 之后';
    return '${formatDate(t!)} 之前';
  }

  /// 本月：1 号到今天。
  static DateRange thisMonth(DateTime now) =>
      DateRange(from: DateTime(now.year, now.month), to: now);

  /// 上个月整月。
  static DateRange lastMonth(DateTime now) {
    final first = DateTime(now.year, now.month - 1);
    // DateTime(y, m, 0) 是上个月最后一天，用它避开大小月。
    final last = DateTime(now.year, now.month, 0);
    return DateRange(from: first, to: last);
  }

  /// 最近 N 天（含今天）。
  static DateRange lastDays(DateTime now, int days) =>
      DateRange(from: now.subtract(Duration(days: days - 1)), to: now);

  /// 今年：1 月 1 日到今天。
  static DateRange thisYear(DateTime now) =>
      DateRange(from: DateTime(now.year), to: now);

  @override
  bool operator ==(Object other) =>
      other is DateRange &&
      other.startInclusive == startInclusive &&
      other.endExclusive == endExclusive;

  @override
  int get hashCode => Object.hash(startInclusive, endExclusive);

  @override
  String toString() => 'DateRange($label)';
}
