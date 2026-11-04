/// 业务枚举。所有枚举在库中以 snake_case 文本存储，便于直接读懂裸 SQL。
library;

import 'package:drift/drift.dart';

/// 商品状态机：
/// inStock(在库) → listed(已上架) → sold(已卖出) → completed(已到账)
///                                  ↘ returned(已退货) → 回到 inStock 或 listed
///                                  ↘ scrapped(已报废)
///
/// [sold] 与 [completed] 的差别只在「钱到没到手」：货都走了、成交价都定了，
/// 但 sold 的货款还压在买家或平台上，completed 才是真到账。
/// 两者都计入已实现利润；sold 额外贡献「待收款」金额。
enum ItemStatus {
  inStock('in_stock', '在库'),
  listed('listed', '已上架'),
  sold('sold', '已卖出'),
  completed('completed', '已到账'),
  returned('returned', '已退货'),
  scrapped('scrapped', '已报废');

  const ItemStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  /// 是否计入「已实现利润」：卖掉的与钱到手的都算。
  bool get isRealized => this == ItemStatus.sold || this == ItemStatus.completed;

  /// 货款已到手。
  bool get isSettled => this == ItemStatus.completed;

  /// 货已卖出但钱没到，构成「待收款」。
  bool get isReceivable => this == ItemStatus.sold;

  /// 是否属于「在途资金占用」。
  bool get isActive => this == ItemStatus.inStock || this == ItemStatus.listed;

  static ItemStatus fromDb(String value) => values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => ItemStatus.inStock,
      );
}

/// 费用种类。买入侧与卖出侧共用一张表，靠 [ExpenseSide] 区分。
enum ExpenseKind {
  shipping('shipping', '运费'),
  buyFee('buy_fee', '买入手续费'),
  sellFee('sell_fee', '卖出手续费'),
  repair('repair', '维修/清洁'),
  packaging('packaging', '包装'),
  other('other', '其他');

  const ExpenseKind(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ExpenseKind fromDb(String value) => values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => ExpenseKind.other,
      );
}

/// 费用发生在买入侧还是卖出侧。两侧都影响单笔利润，但分开展示便于复盘。
enum ExpenseSide {
  buy('buy', '买入'),
  sell('sell', '卖出');

  const ExpenseSide(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ExpenseSide fromDb(String value) => values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => ExpenseSide.buy,
      );
}

/// 图片用途。
enum AttachmentRole {
  buyShot('buy_shot', '买入图'),
  sellShot('sell_shot', '卖出图'),
  chatScreenshot('chat_screenshot', '聊天截图'),
  serial('serial', '序列号/铭牌'),
  other('other', '其他');

  const AttachmentRole(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static AttachmentRole fromDb(String value) => values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => AttachmentRole.other,
      );
}

// ---------------------------------------------------------------------------
// Drift TypeConverter：枚举 <-> snake_case 文本
// ---------------------------------------------------------------------------

class ItemStatusConverter extends TypeConverter<ItemStatus, String> {
  const ItemStatusConverter();

  @override
  ItemStatus fromSql(String fromDb) => ItemStatus.fromDb(fromDb);

  @override
  String toSql(ItemStatus value) => value.dbValue;
}

class ExpenseKindConverter extends TypeConverter<ExpenseKind, String> {
  const ExpenseKindConverter();

  @override
  ExpenseKind fromSql(String fromDb) => ExpenseKind.fromDb(fromDb);

  @override
  String toSql(ExpenseKind value) => value.dbValue;
}

class ExpenseSideConverter extends TypeConverter<ExpenseSide, String> {
  const ExpenseSideConverter();

  @override
  ExpenseSide fromSql(String fromDb) => ExpenseSide.fromDb(fromDb);

  @override
  String toSql(ExpenseSide value) => value.dbValue;
}

class AttachmentRoleConverter extends TypeConverter<AttachmentRole, String> {
  const AttachmentRoleConverter();

  @override
  AttachmentRole fromSql(String fromDb) => AttachmentRole.fromDb(fromDb);

  @override
  String toSql(AttachmentRole value) => value.dbValue;
}
