/// 商家保修（店内承诺）的两个纯函数：默认到期日与「卖出必填」判据。
///
/// 商家保修与厂家保修是两套信息：前者是店主对买家承诺的区间，出货时才产生；
/// 后者是厂商剩余保修，收货议价时记录。两者的口径与约束都不共用。
library;

import 'enums.dart';

/// 开始日加一年。
///
/// 2 月 29 日加一年会落到不存在的日期。这里取该年当月的最后一天
/// （2028-02-29 → 2029-02-28），而不是让 `DateTime` 自己滚到 3 月 1 日：
/// 保修承诺宁可少一天，也不要凭空多出一天。
DateTime addOneYear(DateTime date) {
  final year = date.year + 1;
  // day = 0 会回退到上个月最后一天：DateTime(2029, 3, 0) == 2029-02-28。
  final lastDayOfMonth = DateTime(year, date.month + 1, 0).day;
  final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
  return DateTime(year, date.month, day);
}

/// 判断「卖出时商家保修是否填全」。
///
/// 返回 `null` 表示通过，否则是直接给用户看的错误文案。
/// 只在状态已跨过卖出线（已卖出 / 已到账）时要求；退货、报废、在库、已上架都不要求。
/// 日期顺序（到期早于开始）不拦：自用工具不替用户改写事实，与厂家保修同一口径。
String? merchantWarrantyError(
  ItemStatus status,
  DateTime? start,
  DateTime? end,
) {
  if (!status.isRealized) return null;
  if (start == null) return '商家保修开始日期必填';
  if (end == null) return '商家保修到期日期必填';
  return null;
}
