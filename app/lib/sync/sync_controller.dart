import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart'
    show TableUpdate, TableUpdateQuery, ResultSetImplementation;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/db/app_database.dart';
import 'auto_sync.dart';
import 'host_server.dart';

/// 全局同步调度器：什么时候连、连谁、连完通知谁。
///
/// 三类触发：
/// 1. **启动时一次**（[attach]）——打开就追平对方；
/// 2. **本地一有写入就同步**（[markDirty]，1.2 秒防抖）——改价格、新增、
///    改状态、加图片、改字典都算。这是「改完就能在另一台看到」的关键；
/// 3. **每 [_pollInterval] 兜底拉一次** —— 万一某次写入没被监听到
///    （比如库被外部工具改过），最多 25 秒后还是会同步上。
///
/// 为什么要两端都监听 8787：同步只能由一端发起。如果只有 A 主动连 B，
/// 那么 A 先开机、B 后开机时，A 早试过一次就不再试了，B 永远追不上。
/// 所以两端都在自己机器上监听，谁先起来都能被对方连上。
class SyncController extends ChangeNotifier {
  SyncController(this._ref);

  final Ref _ref;

  /// 一次改动之后多久才真正发起同步。太短会在连续输入时反复触发，
  /// 太长又让人觉得「改完没反应」。
  static const debounce = Duration(milliseconds: 1200);

  /// 兜底轮询间隔。同步本身是幂等的，多跑一次没有副作用。
  static const pollInterval = Duration(seconds: 25);

  /// 同步刚结束时库里的写入是自己造成的，忽略这段时间内的表更新通知，
  /// 否则 A 推 B、B 收到又推 A，两台机器会来回空转。
  static const _quietAfterSync = Duration(seconds: 2);

  /// 需要监听的表；必须与 [MergeService.syncedTables] 一一对应。
  ///
  /// 少一张的后果不是「不同步」，而是「改了不触发」—— 数据最终还是会被
  /// 25 秒的兜底轮询带走，但用户会觉得「我这边改了，对面半天没反应」。
  /// operating_costs 就这么漏过一次。
  static List<ResultSetImplementation> watchedTables(AppDatabase db) => [
    db.items,
    db.expenses,
    db.attachments,
    db.dictEntries,
    db.operatingCosts,
  ];

  bool _attached = false;
  bool _syncing = false;
  Timer? _debounceTimer;
  Timer? _pollTimer;
  StreamSubscription<Set<TableUpdate>>? _tableSub;
  SyncHost? _host;

  /// 连不上的对端，本进程内跳过。放在 controller 而不是 [AutoSyncService]：
  /// 那个 service 每次同步都新建，记不住上次连谁失败了。
  final _failedPeers = <String>{};
  DateTime? _quietUntil;
  DateTime? _lastSyncAt;
  AutoSyncResult? _lastResult;
  String? _lastError;
  String? _hostError;

  bool get syncing => _syncing;
  bool get hosting => _host != null;
  String? get pairCode => _host?.pairCode;
  int? get port => _host?.port;

  /// 上一次开启主机监听失败的原因（端口被占、系统拒绝监听……）。
  ///
  /// 以前这里是 `catch (_) {}` 全静默，用户点了「开启」没任何反应，
  /// 只能看到按钮还是「开启」，根本无从判断是被占用还是没权限。
  String? get hostError => _hostError;
  DateTime? get lastSyncAt => _lastSyncAt;
  AutoSyncResult? get lastResult => _lastResult;
  String? get lastError => _lastError;

  /// 「3 分钟前 / 2 小时前 / 昨天」这种相对时间，给按钮 tooltip 用。
  String get lastSyncLabel {
    final at = _lastSyncAt;
    if (at == null) return '从未同步';
    final d = DateTime.now().difference(at);
    if (d.inSeconds < 45) return '刚刚同步';
    if (d.inMinutes < 60) return '${d.inMinutes} 分钟前同步';
    if (d.inHours < 24) return '${d.inHours} 小时前同步';
    if (d.inDays == 1) return '昨天同步';
    return '${d.inDays} 天前同步';
  }

  /// 由 `home_shell` 在首帧之后调一次。
  Future<void> attach() async {
    if (_attached) return;
    _attached = true;

    final db = _ref.read(databaseProvider);

    // 监听所有会参与同步的表。syncStates 故意排除 —— 它记的是同步自己的
    // 时间戳，把它算进来等于自己触发自己。
    _tableSub = db
        .tableUpdates(TableUpdateQuery.onAllTables(watchedTables(db)))
        .listen((_) => markDirty());

    unawaited(_ensureHost());
    await syncNow();
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(syncNow()));
  }

  /// 任何本地写入后调用。多次写入在 [debounce] 内只同步一次。
  void markDirty() {
    if (!_attached || _syncing) return;
    final quiet = _quietUntil;
    if (quiet != null && DateTime.now().isBefore(quiet)) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(syncNow()));
  }

  /// 立刻同步一次。UI 的同步按钮和所有定时触发都走这里。
  Future<AutoSyncResult?> syncNow() async {
    if (_syncing) return null;
    _syncing = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    notifyListeners();

    try {
      final db = _ref.read(databaseProvider);
      final service = AutoSyncService(
        db: db,
        deviceId: _ref.read(deviceIdProvider),
        deviceName: _selfName,
        skipPeers: Set<String>.of(_failedPeers),
      );
      final result = await service.tryOnce();
      _lastResult = result;
      final tried = service.attemptedPeerId;
      if (tried != null) {
        if (result.ok) {
          _failedPeers.clear();
        } else if (result.status == AutoSyncStatus.offline ||
            result.status == AutoSyncStatus.failed) {
          _failedPeers.add(tried);
        }
      }

      // 同步失败也可能已经动过库：sync 是「先拉后推」，推失败时拉回来的
      // 数据已经合并进本地了。所以刷新不能只在成功分支做。
      // 连不上和没配对不算 —— 那种情况库根本没碰，白刷一次报表而已。
      final attempted =
          result.status != AutoSyncStatus.noPeer &&
          result.status != AutoSyncStatus.offline;
      if (attempted) {
        // 先捅一下计数器：报表、文件体积这类 FutureProvider 不是 drift 的
        // stream，合并改了库它们不会自己重算。
        _ref.read(syncTickProvider.notifier).bump();
        _ref.invalidate(profitSummaryProvider);
        _ref.invalidate(categoryStatsProvider);
        _ref.invalidate(platformStatsProvider);
        // 下面这几个是 `FutureProvider.family` —— 不是 drift 的 stream，
        // `markTablesUpdated` 管不到它们。不显式失效的话，详情页、费用列表、
        // 附件缩略图都会拿着合并前的旧值不刷新，用户看到的就是「同步了但没变」。
        _ref.invalidate(itemDetailProvider);
        _ref.invalidate(itemProfitLineProvider);
        _ref.invalidate(itemAttachmentsProvider);
        _ref.invalidate(attachmentThumbProvider);
      }

      if (result.ok) {
        _lastSyncAt = DateTime.now();
        _lastError = null;
      } else if (attempted) {
        // 连不上属于日常，不打扰；其它失败留一句说明，设置页显示得出来。
        _lastError = result.describe();
      }
      return result;
    } finally {
      _quietUntil = DateTime.now().add(_quietAfterSync);
      _syncing = false;
      notifyListeners();
    }
  }

  String get _selfName {
    var name = _ref.read(deviceNameProvider);
    final row = _ref.read(localDeviceProvider).value;
    if (row != null) name = row.name;
    return name;
  }

  /// 开门等对方连过来。
  ///
  /// [manual] 区分「自动」和「用户点按钮」两条路：
  /// - 自动（启动时 / 刚配对完）只在**已有对端**时才监听 —— 全新安装不该占
  ///   8787、也不该弹系统防火墙；
  /// - 手动点「开启」时必须无条件起监听。否则会出现一个死锁：两台全新设备
  ///   互配，A 得先开启监听才能拿到配对码给 B 填，而 A 没有对端就永远开不了。
  ///   没对端时 `_tokens` 是空的、`_pairCode` 照样生成，`/v1/pair` 完全可用。
  Future<void> _ensureHost({bool manual = false}) async {
    if (_host != null) return;
    final db = _ref.read(databaseProvider);
    if (!manual) {
      final peers = await db.select(db.syncStates).get();
      if (peers.isEmpty) return;
    }

    final host = SyncHost(
      db: db,
      deviceId: _ref.read(deviceIdProvider),
      deviceName: _selfName,
    );
    try {
      await host.start();
      _host = host;
      _hostError = null;
      notifyListeners();
    } catch (e) {
      // 端口被占（比如同一台机器开了两份）、或者系统不给监听权限。
      // 这时候对方连不进来，但本机仍然能主动连出去，所以不抛给上层；
      // 原因必须留下来，让手动开启的一方看到到底为什么失败。
      _hostError = _describeHostError(e);
      notifyListeners();
    }
  }

  static String _describeHostError(Object e) {
    if (e is SocketException) {
      final code = e.osError?.errorCode;
      final detail = e.osError?.message ?? e.message;
      // 10048 / 98 = 端口已被占用；10013 / 13 = 权限不足。
      if (code == 10048 || code == 98) {
        return '端口 ${SyncHost.defaultPort} 已被占用（可能另一份程序还在运行）';
      }
      if (code == 10013 || code == 13) {
        return '系统不允许监听端口 ${SyncHost.defaultPort}（权限不足）';
      }
      return '监听端口 ${SyncHost.defaultPort} 失败：$detail';
    }
    return '开启同步主机失败：$e';
  }

  /// 刚配对完就调一次：这时候才第一次有对端，之前 `_ensureHost` 是空转。
  Future<void> refreshHost() async {
    await _ensureHost();
    notifyListeners();
  }

  /// 用户手动关掉/开启主机监听时用。
  ///
  /// 返回 `null` 表示成功，否则是给用户看的失败原因 —— 调用方必须展示出来，
  /// 别再让「点了没反应」成为唯一反馈。
  Future<String?> toggleHost() async {
    if (_host != null) {
      await _host!.stop();
      _host = null;
      _hostError = null;
      notifyListeners();
      return null;
    }
    _hostError = null;
    await _ensureHost(manual: true);
    return _host == null ? (_hostError ?? '开启同步主机失败') : null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pollTimer?.cancel();
    _tableSub?.cancel();
    unawaited(_host?.stop());
    _host = null;
    super.dispose();
  }
}
