/// Excel 导入导出的表头与取值映射。
///
/// 这一层单独存在的理由：导入与导出必须共用同一份表头定义，
/// 否则改了一边忘了另一边，导出的文件自己都导不回来。
///
/// **定位列一律按表头名，不按列号。** 用户在 Excel 里插一列、删一列、
/// 换个顺序，列号就全错了，而表头名还是稳的。
library;

import '../../domain/enums.dart';

class ExcelSchema {
  ExcelSchema._();

  static const String sheetItems = '商品';
  static const String sheetExpenses = '费用明细';

  // -------------------------------------------------------------------
  // 商品表头。顺序即导出顺序；导出的第一行就是这张表。
  // -------------------------------------------------------------------
  static const String id = 'id';
  static const String title = '名称';
  static const String category = '分类';
  static const String brand = '品牌';
  static const String model = '型号';
  static const String storage = '内存';
  static const String color = '颜色';
  static const String status = '状态';
  static const String buyPrice = '买入价';
  static const String buyDate = '买入日期';
  static const String sourcePlatform = '买入来源';
  static const String conditionBought = '买入成色';
  static const String sellPrice = '卖出价';
  static const String sellDate = '卖出日期';
  static const String sellPlatform = '卖出渠道';
  static const String conditionSold = '卖出成色';

  /// 电池健康百分比（0–100 整数）。
  static const String batteryHealth = '电池健康';

  /// 置换时的挂牌价（原始要价）。实收写「卖出价」。
  static const String listPrice = '挂牌价';

  /// 置换时买家旧机折的价。只记录，不进利润。
  static const String tradeIn = '旧机抵扣';

  static const String expenseTotal = '费用合计';
  static const String totalCost = '总投入';

  /// 单笔利润。v4 起「毛利」改名「利润」（口径本来就一样，只是名字统一）。
  static const String profitAmount = '利润';
  static const String profitRate = '利润率';
  static const String note = '备注';
  static const String lotId = '批次号';

  static const List<String> itemHeaders = <String>[
    id,
    title,
    category,
    brand,
    model,
    storage,
    color,
    status,
    buyPrice,
    buyDate,
    sourcePlatform,
    conditionBought,
    sellPrice,
    sellDate,
    sellPlatform,
    conditionSold,
    batteryHealth,
    listPrice,
    tradeIn,
    expenseTotal,
    totalCost,
    profitAmount,
    profitRate,
    note,
    lotId,
  ];

  /// 只读列：导出时算好写死，导入时直接忽略用户改的值。
  ///
  /// 这些数字是 [ProfitLine] 的产物，导入时若采纳用户改过的值，
  /// 就会出现「表里写赚 500、库里算出来赚 300」的两套账。
  static const Set<String> computedHeaders = <String>{
    expenseTotal,
    totalCost,
    profitAmount,
    profitRate,
  };

  // -------------------------------------------------------------------
  // 费用表头
  // -------------------------------------------------------------------
  /// 费用自己的 id。有了它，导入才能原地覆盖而不是每次都插新行。
  static const String expenseId = '费用id';
  static const String expenseItemId = '商品id';
  static const String expenseItemTitle = '商品名称';
  static const String expenseKind = '种类';
  static const String expenseSide = '侧别';
  static const String expenseAmount = '金额';
  static const String expenseDate = '发生日期';
  static const String expenseNote = '备注';

  static const List<String> expenseHeaders = <String>[
    expenseId,
    expenseItemId,
    expenseItemTitle,
    expenseKind,
    expenseSide,
    expenseAmount,
    expenseDate,
    expenseNote,
  ];

  /// 日期列的书写格式。导入时也认 `2024/01/05` 与 `2024.1.5`。
  static const String datePattern = 'yyyy-MM-dd';

  // -------------------------------------------------------------------
  // 枚举 <-> 中文标签
  //
  // 导出写中文（人要看），导入同时认中文标签与 dbValue（人可能手敲
  // `sold`，也可能是脚本生成的表）。
  // -------------------------------------------------------------------
  static String statusLabel(ItemStatus value) => value.label;

  static ItemStatus? statusFromLabel(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    for (final value in ItemStatus.values) {
      if (value.label == text) return value;
    }
    for (final value in ItemStatus.values) {
      if (value.dbValue == text) return value;
    }
    return null;
  }

  static String kindLabel(ExpenseKind value) => value.label;

  static ExpenseKind? kindFromLabel(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    for (final value in ExpenseKind.values) {
      if (value.label == text) return value;
    }
    for (final value in ExpenseKind.values) {
      if (value.dbValue == text) return value;
    }
    return null;
  }

  static String sideLabel(ExpenseSide value) => value.label;

  static ExpenseSide? sideFromLabel(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    for (final value in ExpenseSide.values) {
      if (value.label == text) return value;
    }
    for (final value in ExpenseSide.values) {
      if (value.dbValue == text) return value;
    }
    return null;
  }
}
