import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dao/attachment_dao.dart';
import '../data/dao/dict_dao.dart';
import '../data/dao/item_dao.dart';
import '../data/dao/stat_dao.dart';
import '../sync/sync_controller.dart';
import '../data/db/app_database.dart';
import '../data/repo/item_repository.dart';
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
  const ItemFilter({this.status, this.keyword = ''});

  final ItemStatus? status;
  final String keyword;

  ItemFilter copyWith({ItemStatus? status, String? keyword, bool clearStatus = false}) =>
      ItemFilter(
        status: clearStatus ? null : (status ?? this.status),
        keyword: keyword ?? this.keyword,
      );

  @override
  bool operator ==(Object other) =>
      other is ItemFilter && other.status == status && other.keyword == keyword;

  @override
  int get hashCode => Object.hash(status, keyword);
}

/// 列表数据流。
final itemListProvider =
    StreamProvider.family<List<ItemListRow>, ItemFilter>((ref, filter) {
  return ref
      .watch(itemRepositoryProvider)
      .watchList(status: filter.status, keyword: filter.keyword);
});

/// 看板汇总。
final profitSummaryProvider = FutureProvider<ProfitAggregate>((ref) async {
  return ref.watch(itemRepositoryProvider).aggregate();
});

final statDaoProvider = Provider<StatDao>(
  (ref) => StatDao(ref.watch(databaseProvider)),
);

/// 按分类聚合。口径与看板一致，都从 [ProfitLine] 走。
final categoryStatsProvider = FutureProvider<List<GroupStat>>((ref) async {
  return ref.watch(statDaoProvider).byCategory();
});

/// 按卖出渠道聚合。
final platformStatsProvider = FutureProvider<List<GroupStat>>((ref) async {
  return ref.watch(statDaoProvider).bySellPlatform();
});

/// 单件商品详情。
final itemDetailProvider =
    FutureProvider.family<ItemWithExpenses?, String>((ref, id) async {
  return ref.watch(itemRepositoryProvider).load(id);
});

/// 单件商品的全部利润行（详情页展示毛利率用）。
final itemProfitLineProvider =
    FutureProvider.family<ProfitLine?, String>((ref, id) async {
  final detail = await ref.watch(itemDetailProvider(id).future);
  return detail?.toProfitLine();
});

/// 某件商品的附件元数据列表。
final itemAttachmentsProvider =
    FutureProvider.family<List<AttachmentMeta>, String>((ref, id) async {
  return ref.watch(itemRepositoryProvider).attachmentsOf(id);
});

/// 附件缩略图字节。
final attachmentThumbProvider =
    FutureProvider.family<List<int>?, String>((ref, id) async {
  return ref.watch(itemRepositoryProvider).thumbImage(id);
});

/// 附件原图字节。
final attachmentBytesProvider =
    FutureProvider.family<List<int>?, String>((ref, id) async {
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
typedef DictQuery = ({
  String kind,
  String? parentLabel,
  String? parentKind,
});

/// 某一类字典项的实时列表。
final dictEntriesProvider =
    StreamProvider.family<List<DictEntry>, DictQuery>((ref, query) {
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

final syncTickProvider =
    NotifierProvider<SyncTickNotifier, int>(SyncTickNotifier.new);
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