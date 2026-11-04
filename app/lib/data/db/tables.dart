import 'package:drift/drift.dart';

import '../../domain/enums.dart';

/// 商品（一次买入记录 = 一行）。
///
/// `sellPriceCents` 为 null 表示尚未卖出；售出但未填价格用 0 表示「白送/赠出」。
/// 所有跨端同步的表都带 [createdAt] / [updatedAt] / [deletedAt] / [deviceId]。
class Items extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();
  TextColumn get category => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();

  /// 内存规格（如 `12+256`），来自字典 `dict_entries.kind = 'storage'`。
  TextColumn get storage => text().nullable()();

  /// 颜色，来自字典 `dict_entries.kind = 'color'`。
  TextColumn get color => text().nullable()();

  /// 买入时成色描述，自由文本（如「95新」「有划痕」）。
  TextColumn get conditionBought => text().nullable()();

  /// 卖出时成色描述。
  TextColumn get conditionSold => text().nullable()();

  TextColumn get status =>
      text().map(const ItemStatusConverter()).withDefault(
            Constant(ItemStatus.inStock.dbValue),
          )();

  /// 买入来源：闲鱼/转转/朋友/线下店……
  TextColumn get sourcePlatform => text().nullable()();
  DateTimeColumn get buyDate => dateTime().nullable()();

  IntColumn get buyPriceCents => integer()();

  DateTimeColumn get sellDate => dateTime().nullable()();
  IntColumn get sellPriceCents => integer().nullable()();
  TextColumn get sellPlatform => text().nullable()();

  /// 打包买卖时，同批商品共享一个 lotId；单独交易为 null。
  TextColumn get lotId => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  // -------------------------------------------------------------------
  // v4 新增列。
  //
  // **必须声明在表定义的最后。** SQLite 的 `ALTER TABLE ADD COLUMN` 只能
  // 把列追加到末尾，而 drift 建新库时按声明顺序排。这三位如果写在中间，
  // 「全新安装的库」和「v3 升级上来的库」列顺序就会不一样，
  // 同步时 merge.dart 的 `_verifySchema` 会直接判为两端不兼容。
  // -------------------------------------------------------------------

  /// 电池健康百分比（0–100 整数）。null = 没测或没填。
  ///
  /// 用整数而不是「95新」这类文本：以后要按它排序、算均值、看衰减曲线，
  /// 文本没法比大小。
  IntColumn get batteryHealth => integer().nullable()();

  /// 置换时的挂牌价（分）。例：挂牌 1000、旧机抵 600、实收 400。
  ///
  /// [sellPriceCents] 存的是**实收**（参与利润），这里只做记录，
  /// 两者之差就是抵扣额。挂牌价为空表示普通交易。
  IntColumn get listPriceCents => integer().nullable()();

  /// 置换时买家旧机折的价（分）。
  ///
  /// **当前不参与利润计算**：旧机的价值要等它作为新商品再卖出去才结算，
  /// 否则同一笔 600 元会被算两次。只单独展示。
  IntColumn get tradeInCents => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 费用（运费、手续费、维修、包装……），挂在某个商品上。
class Expenses extends Table {
  TextColumn get id => text()();

  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();

  TextColumn get kind => text().map(const ExpenseKindConverter())();
  TextColumn get side => text().map(const ExpenseSideConverter())();

  IntColumn get amountCents => integer()();
  DateTimeColumn get incurredAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 图片附件。图片二进制直接进库（BLOB），不存外部路径。
///
/// [thumb] 是长边 300px 的缩略图，列表页只读这一列，避免把原图拉进内存。
class Attachments extends Table {
  TextColumn get id => text()();

  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();

  TextColumn get role => text().map(const AttachmentRoleConverter())();

  TextColumn get mime => text().withDefault(const Constant('image/jpeg'))();

  BlobColumn get bytes => blob()();
  BlobColumn get thumb => blob().nullable()();

  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 已配对设备与上次同步水位。
///
/// 一台设备可能有多个对端，但个人使用场景里通常就两台机器，
/// 所以 [peerId] 是主键，每一行代表「我和某个对端」的同步状态。
class SyncStates extends Table {
  TextColumn get peerId => text()();
  TextColumn get peerName => text().nullable()();
  DateTimeColumn get lastPullAt => dateTime().nullable()();
  DateTimeColumn get lastPushAt => dateTime().nullable()();
  DateTimeColumn get pairedAt => dateTime()();

  /// 配对时对端签发的 Bearer 凭证。持久化它，重启后才能自动同步
  /// —— 只放内存的话，进程一退出旧 token 就全失效，自动同步永远失败。
  TextColumn get peerToken => text().nullable()();

  /// 对端地址与端口，自动同步时直接拿来 ping，不用再问用户。
  TextColumn get peerHost => text().nullable()();
  IntColumn get peerPort => integer().nullable()();

  /// 上次**成功**同步完成的时刻。冲突判据（「同步之后两边都改过」）靠它。
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  /// 是否在启动时自动连这台对端：1 开（默认）、0 关。
  IntColumn get autoSync => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {peerId};
}

/// 本机身份，只应有一行。
class LocalDevices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 主题偏好：`light` / `dark` / `system`，缺省亮色。
  ///
  /// 放在这张表而不是 [SyncStates]：主题是**设备本地偏好**，
  /// 电脑上想用深色不代表手机上也要深色，不该跟着同步跑。
  TextColumn get themeMode =>
      text().withDefault(const Constant('light'))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 字典项：品牌 / 机型 / 内存规格 / 颜色……统一在这一张表里维护。
///
/// - [kind] 区分类别，取值见 `DictSeeds.kindBrand` 等常量。
/// - 机型通过 [parentId] 挂在品牌下，选品牌后机型列表才有意义；
///   其他类别 [parentId] 为 null。
/// - [builtIn] = 1 表示随 App 预置的，只是用来区分「系统给的」和「自己加的」，
///   并不禁止删除 —— 这是自用工具，用户想删就删。
/// - 字典项同样参与两端同步，所以带同步四列。
class DictEntries extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get label => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get builtIn => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 运营成本：不挂在任何一个商品上的支出。
///
/// 和 [Expenses] 的区别是「能不能摊到某一单」—— 运费、平台手续费、
/// 维修费摊得到，所以记在费用表里直接扣进那一单的利润；房租、包材、
/// 软件订阅摊不到，单独记在这里，看板按「总利润 − 运营成本」算净利。
///
/// 刻意不复用 `expenses` 加一列 `item_id` 可空：那会让「费用合计」
/// 聚合到处都要多一个 `item_id IS NOT NULL`，漏一处就把房租算进单笔利润。
class OperatingCosts extends Table {
  TextColumn get id => text()();

  /// 发生日期。看板按它做时间筛选，必填（默认今天）。
  DateTimeColumn get spentAt => dateTime()();

  /// 类别文本快照，来自字典 `dict_entries.kind = 'operating'`。
  ///
  /// 存文本不存外键，和商品表的品牌/分类一致：字典改名不回写历史。
  TextColumn get kind => text()();

  IntColumn get amountCents => integer()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}
