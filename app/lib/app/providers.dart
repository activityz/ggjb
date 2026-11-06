import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dao/attachment_dao.dart';
import '../data/dao/dict_dao.dart';
import '../data/dao/item_dao.dart';
import '../data/dao/operating_dao.dart';
import '../data/dao/stat_dao.dart';
import '../sync/sync_controller.dart';
import '../data/db/app_database.dart';
import '../data/repo/item_repository.dart';
import '../domain/date_period.dart';
import '../domain/enums.dart';
import '../domain/profit.dart';

/// 数据库实例。在 `main()` 里 override 成真实实例。
///
/// 全 App 只应存在一个 [AppDatabase]；SQLite 单写者模型下开两个连接
/// 会直接撞 SQLITE_BUSY。
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider 必须在 main() 中 override'),
);

/// 本机 id，用于同步冲突决胜。
final deviceIdProvider = Provider<String>(
  (ref) => throw UnimplementedError('deviceIdProvider 必须在 main() 中 override'),
);

final deviceNameProvider = Provider<String>(
  (ref) => throw UnimplementedError('deviceNameProvider 必须在 main() 中 override'),
);

/// 是否提供摄像头扫码入口。
///
/// `mobile_scanner` 的插件平台只有 android / ios / macos / web，**没有
/// Windows**。桌面端不展示入口，避免出现「按钮在但点了没反应」的假入口。
///
/// 用 provider 而不是在 widget 里直接判平台：widget 测试跑在桌面宿主上，
/// 写死平台会让「Android 上应有按钮」这条规格没法测；这里可以 override。
final scanAvailableProvider = Provider<bool>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);

/// 本机设备行。设备名可改，所以走 DB 流让 UI 跟着变。
final localDeviceProvider = StreamProvider<LocalDevice>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.localDevices).watchSingle();
});

final itemDaoProvider = Provider<ItemDao>(
  (ref) => ItemDao(ref.watch(databaseProvider)),
);

final attachmentDaoProvider = Provider<AttachmentDao>(
  (ref) => AttachmentDao(ref.watch(databaseProvider)),
);

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(
    db: ref.watch(databaseProvider),
    itemDao: ref.watch(itemDaoProvider),
    attachmentDao: ref.watch(attachmentDaoProvider),
    deviceId: ref.watch(deviceIdProvider),
  ),
);

/// 列表筛选条件。必须实现 == / hashCode，否则 family 无法命中缓存，
/// 每次重建都会重新订阅数据库。
class ItemFilter {
  const ItemFilter({
    this.status,
    this.statuses,
    this.keyword = '',
    this.dateField,
    this.range = DateRange.all,
  });

  final ItemStatus? status;

  /// 跨状态的一组筛选。看板上「已卖出 / 待收 / 未卖」点进来就是这里：
  /// 已卖出 = sold + completed，未卖 = inStock + listed。
  ///
  /// null 或空集 = 不按状态筛；和 [status] 同时给时以这里为准。
  final Set<ItemStatus>? statuses;

  final String keyword;

  /// 日期筛选按哪一列。null = 不按日期筛。
  final DateField? dateField;

  /// 日期区间。两端都可能为空（只填一头也算筛）。
  final DateRange range;

  /// 是否真的在按日期筛。UI 上用来显示「清除」按钮。
  bool get hasDateFilter => dateField != null && !range.isEmpty;

  /// 是否在按状态筛（单状态或一组）。空态文案用它判断「是不是筛空了」。
  bool get hasStatusFilter => status != null || statuses?.isNotEmpty == true;

  ItemFilter copyWith({
    ItemStatus? status,
    Set<ItemStatus>? statuses,
    String? keyword,
    bool clearStatus = false,
    bool clearStatuses = false,
    DateField? dateField,
    DateRange? range,
    bool clearDate = false,
  }) => ItemFilter(
    status: clearStatus ? null : (status ?? this.status),
    statuses: clearStatuses ? null : (statuses ?? this.statuses),
    keyword: keyword ?? this.keyword,
    dateField: clearDate ? null : (dateField ?? this.dateField),
    range: clearDate ? DateRange.all : (range ?? this.range),
  );

  @override
  bool operator ==(Object other) =>
      other is ItemFilter &&
      other.status == status &&
      other.keyword == keyword &&
      other.dateField == dateField &&
      other.range == range &&
      _sameStatuses(other.statuses, statuses);

  @override
  int get hashCode =>
      Object.hash(status, keyword, dateField, range, _statusesHash(statuses));
}

/// Set 的 == 走引用比较，family 会因此每次都重新订阅数据库。
/// 这里按内容比较 + 按枚举声明顺序算哈希，让 {sold, completed} 命中缓存。
bool _sameStatuses(Set<ItemStatus>? a, Set<ItemStatus>? b) {
  final leftEmpty = a == null || a.isEmpty;
  final rightEmpty = b == null || b.isEmpty;
  if (leftEmpty || rightEmpty) return leftEmpty == rightEmpty;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

int _statusesHash(Set<ItemStatus>? statuses) {
  if (statuses == null || statuses.isEmpty) return 0;
  return Object.hashAll(ItemStatus.values.where(statuses.contains));
}

/// 列表数据流。
final itemListProvider = StreamProvider.family<List<ItemListRow>, ItemFilter>((
  ref,
  filter,
) {
  return ref
      .watch(itemRepositoryProvider)
      .watchList(
        status: filter.status,
        statuses: filter.statuses,
        keyword: filter.keyword,
        dateField: filter.dateField,
        range: filter.range,
      );
});

/// 看板的筛选条件：只看时间段。
///
/// 分类筛选已移除：看板是「一眼看到赚了多少」，不该先让人选分类。
/// 「按分类」区块仍然存在，那是展示维度，不是筛选。
///
/// 默认 `DateField.sell` + 空区间 = 「全部时间」，也就是没筛。
/// 之所以默认按**卖出日期**：看板讲的是「这段时间卖掉的货赚了多少」，
/// 和「每月卖出」图表同口径；换成买入日期就是另一种问题了。
class DashboardFilter {
  const DashboardFilter({
    this.dateField = DateField.sell,
    this.range = DateRange.all,
  });

  /// 不筛。
  static const DashboardFilter all = DashboardFilter();

  final DateField dateField;
  final DateRange range;

  bool get isAll => range.isEmpty;

  DashboardFilter copyWith({DateField? dateField, DateRange? range}) =>
      DashboardFilter(
        dateField: dateField ?? this.dateField,
        range: range ?? this.range,
      );

  @override
  bool operator ==(Object other) =>
      other is DashboardFilter &&
      other.dateField == dateField &&
      other.range == range;

  @override
  int get hashCode => Object.hash(dateField, range);
}

/// 看板汇总。带参数 = 只算筛选范围内的单子。
///
/// 顺带把同区间的运营成本查出来挂到 aggregate 上：总利润要减掉它（用户口径 A），
/// 但扣减发生在展示层（`netAfterOperatingCents`），不改 [ProfitSummary] 里
/// 「卖货挣了多少」那个数 —— 列表页和 Excel 导出的口径不能跟着变。
final profitSummaryProvider =
    FutureProvider.family<ProfitAggregate, DashboardFilter>((
      ref,
      filter,
    ) async {
      ref.watch(syncTickProvider);
      final agg = await ref
          .watch(itemRepositoryProvider)
          .aggregate(
            dateField: filter.range.isEmpty ? null : filter.dateField,
            range: filter.range,
          );
      final operating = await ref
          .watch(operatingDaoProvider)
          .watchTotalCents(
            from: filter.range.startInclusive,
            to: filter.range.endExclusive,
          )
          .first;
      return agg.withOperatingCost(operating);
    });

final statDaoProvider = Provider<StatDao>(
  (ref) => StatDao(ref.watch(databaseProvider)),
);

final operatingDaoProvider = Provider<OperatingDao>(
  (ref) => OperatingDao(ref.watch(databaseProvider)),
);

/// 运营成本列表（按时间段筛）。
final operatingCostsProvider =
    FutureProvider.family<List<OperatingCost>, DashboardFilter>((
      ref,
      filter,
    ) async {
      ref.watch(syncTickProvider);
      return ref
          .watch(operatingDaoProvider)
          .watch(
            from: filter.range.startInclusive,
            to: filter.range.endExclusive,
          )
          .first;
    });

/// 运营成本区间合计（分）。看板「总利润」下面那行小字用它。
final operatingTotalProvider = FutureProvider.family<int, DashboardFilter>((
  ref,
  filter,
) async {
  ref.watch(syncTickProvider);
  return ref
      .watch(operatingDaoProvider)
      .watchTotalCents(
        from: filter.range.startInclusive,
        to: filter.range.endExclusive,
      )
      .first;
});

/// 按分类聚合。口径与看板一致，都从 [ProfitLine] 走。
final categoryStatsProvider =
    FutureProvider.family<List<GroupStat>, DashboardFilter>((
      ref,
      filter,
    ) async {
      ref.watch(syncTickProvider);
      return ref
          .watch(statDaoProvider)
          .byCategory(
            dateField: filter.range.isEmpty ? null : filter.dateField,
            range: filter.range,
          );
    });

/// 按卖出渠道聚合。
final platformStatsProvider =
    FutureProvider.family<List<GroupStat>, DashboardFilter>((
      ref,
      filter,
    ) async {
      ref.watch(syncTickProvider);
      return ref
          .watch(statDaoProvider)
          .bySellPlatform(
            dateField: filter.range.isEmpty ? null : filter.dateField,
            range: filter.range,
          );
    });

/// 近 12 个月每月卖出几台。看板「按月卖出」区块用。
///
/// 跟着 [syncTickProvider] 一起刷新，否则同步拉下来的新单子不出现在图表里
/// ——看板其他数字都是 FutureProvider，同步后是手工 invalidate 的，这里复用同一套。
///
/// 也接受看板的筛选：区间为空就是全部账（仍然是近 12 个月），
/// 有区间就只数区间内的单子。
final monthlySoldProvider =
    FutureProvider.family<List<MonthlySoldCount>, DashboardFilter>((
      ref,
      filter,
    ) async {
      ref.watch(syncTickProvider);
      return ref
          .watch(statDaoProvider)
          .monthlySoldCounts(range: filter.range.isEmpty ? null : filter.range);
    });

/// 单件商品详情。
final itemDetailProvider = FutureProvider.family<ItemWithExpenses?, String>((
  ref,
  id,
) async {
  return ref.watch(itemRepositoryProvider).load(id);
});

/// 单件商品的全部利润行（详情页展示利润率用）。
final itemProfitLineProvider = FutureProvider.family<ProfitLine?, String>((
  ref,
  id,
) async {
  final detail = await ref.watch(itemDetailProvider(id).future);
  return detail?.toProfitLine();
});

/// 某件商品的附件元数据列表。
final itemAttachmentsProvider =
    FutureProvider.family<List<AttachmentMeta>, String>((ref, id) async {
      return ref.watch(itemRepositoryProvider).attachmentsOf(id);
    });

/// 附件缩略图字节。
final attachmentThumbProvider = FutureProvider.family<List<int>?, String>((
  ref,
  id,
) async {
  return ref.watch(itemRepositoryProvider).thumbImage(id);
});

/// 附件原图字节。
final attachmentBytesProvider = FutureProvider.family<List<int>?, String>((
  ref,
  id,
) async {
  return ref.watch(itemRepositoryProvider).fullImage(id);
});

final dictDaoProvider = Provider<DictDao>(
  (ref) => DictDao(ref.watch(databaseProvider)),
);

/// 全量字典（字典管理页用）。
final allDictProvider = StreamProvider<List<DictEntry>>(
  (ref) => ref.watch(dictDaoProvider).watchAll(),
);

/// 字典查询条件。用 record 做 family 键 —— record 自带 == / hashCode，
/// 相同参数会命中同一份缓存，不会反复重新订阅数据库。
///
/// [parentLabel] 只对机型有意义：机型挂在品牌下，而商品表存的是品牌文本，
/// 所以按 label 反查父项 id 再过滤（见 `DictDao.watchKindUnderLabel`）。
typedef DictQuery = ({String kind, String? parentLabel, String? parentKind});

/// 某一类字典项的实时列表。
final dictEntriesProvider = StreamProvider.family<List<DictEntry>, DictQuery>((
  ref,
  query,
) {
  final dao = ref.watch(dictDaoProvider);
  final label = query.parentLabel;
  if (label != null && label.isNotEmpty && query.parentKind != null) {
    return dao.watchKindUnderLabel(
      query.kind,
      parentKind: query.parentKind!,
      parentLabel: label,
    );
  }
  return dao.watchKind(query.kind);
});

/// 主题偏好。默认亮色（`LocalDevices.themeMode` 的列默认值就是 `light`）。
///
/// 走 DB 流而不是纯内存：改完必须重启还在。
final themeModeProvider = StreamProvider<ThemeMode>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.localDevices).watchSingle().map(_parseThemeMode);
});

ThemeMode _parseThemeMode(LocalDevice row) {
  switch (row.themeMode) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.light;
  }
}

/// 所有已配对的对端（同步状态流）。
final peersProvider = StreamProvider<List<SyncState>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.syncStates).watch();
});

/// 每次同步成功 +1。
///
/// 为什么需要它：drift 的 stream 查询能自己发现表被改（`markTablesUpdated`），
/// 但 `FutureProvider` 里那些「算出来」的东西 —— 报表汇总、文件体积、分组统计
/// —— 不会。它们 watch 这个计数器，同步一成功就自动重算。
///
/// 用 `Notifier` 而不是 `StateProvider`：riverpod 3.x 已经把 `StateProvider`
/// 挪进 legacy 包，`Notifier` 才是这一代的正统写法。
class SyncTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final syncTickProvider = NotifierProvider<SyncTickNotifier, int>(
  SyncTickNotifier.new,
);

/// 全局同步调度器：启动同步一次、任何本地写入后防抖同步、定时兜底拉取。
///
/// 用普通 `Provider` 包 `ChangeNotifier` —— riverpod 3.x 把
/// `ChangeNotifierProvider` 挪进了 legacy 包，而 `ListenableBuilder`
/// 是 Flutter 自带的，直接组合更省事。
final syncControllerProvider = Provider<SyncController>((ref) {
  final controller = SyncController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
