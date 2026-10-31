import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate, TableUpdateQuery, ResultSetImplementation;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
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

  bool _attached = false;
  bool _syncing = false;
  Timer? _debounceTimer;
  Timer? _pollTimer;
  StreamSubscription<Set<TableUpdate>>? _tableSub;
  SyncHost? _host;
  DateTime? _quietUntil;
  DateTime? _lastSyncAt;
  AutoSyncResult? _lastResult;
  String? _lastError;

  bool get syncing => _syncing;
  bool get hosting => _host != null;
  String? get pairCode => _host?.pairCode;
  int? get port => _host?.port;
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
        .tableUpdates(
          TableUpdateQuery.onAllTables(<ResultSetImplementation>[
            db.items,
            db.expenses,
            db.attachments,
            db.dictEntries,
          ]),
        )
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
      );
      final result = await service.tryOnce();
      _lastResult = result;

      if (result.ok) {
        _lastSyncAt = DateTime.now();
        _lastError = null;
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
      } else if (result.shouldNotify) {
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

  /// 只要配对过就自动开门等着对方连，这样谁先开机都能同步上。
  /// 没配对过就不占端口 —— 全新安装的用户不该看到防火墙弹窗。
  Future<void> _ensureHost() async {
    if (_host != null) return;
    final db = _ref.read(databaseProvider);
    final peers = await db.select(db.syncStates).get();
    if (peers.isEmpty) return;

    final host = SyncHost(
      db: db,
      deviceId: _ref.read(deviceIdProvider),
      deviceName: _selfName,
    );
    try {
      await host.start();
      _host = host;
      notifyListeners();
    } catch (_) {
      // 端口被占（比如同一台机器开了两份）、或者系统不给监听权限。
      // 这种情况下对方连不进来，但本机仍然能主动连出去，所以不报错。
    }
  }

  /// 刚配对完就调一次：这时候才第一次有对端，之前 `_ensureHost` 是空转。
  Future<void> refreshHost() async {
    await _ensureHost();
    notifyListeners();
  }
  /// 用户手动关掉/开启主机监听时用。
  Future<void> toggleHost() async {
    if (_host != null) {
      await _host!.stop();
      _host = null;
      notifyListeners();
      return;
    }
    await _ensureHost();
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
