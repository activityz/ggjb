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
