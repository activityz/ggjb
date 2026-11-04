import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;

import '../data/db/app_database.dart';
import 'client.dart';

/// 自动同步的结局。UI 只按这个枚举决定要不要打扰用户。
enum AutoSyncStatus {
  /// 还没配对过，静默跳过。
  noPeer,

  /// 配对过但连不上（对方没开机 / 不在同一个网）。静默。
  offline,

  /// 令牌失效了，需要重新输一次配对码。
  tokenExpired,

  /// 两端 schema 不一致，必须升级到同一个包。
  versionMismatch,

  /// 其它失败（合并出错、磁盘满……）。
  failed,

  ok,
}

/// [AutoSyncService.tryOnce] 的返回值。
class AutoSyncResult {
  const AutoSyncResult({
    required this.status,
    this.message,
    this.outcome,
    this.peerName,
  });

  final AutoSyncStatus status;
  final String? message;
  final SyncOutcome? outcome;
  final String? peerName;

  bool get ok => status == AutoSyncStatus.ok;

  /// 是否需要主动告知用户。连不上和没配对都属于「日常」，不打扰。
  bool get shouldNotify =>
      status == AutoSyncStatus.versionMismatch ||
      status == AutoSyncStatus.tokenExpired;

  String describe() {
    switch (status) {
      case AutoSyncStatus.noPeer:
        return '还没有配对过设备';
      case AutoSyncStatus.offline:
        return '连不上${peerName ?? '对方设备'}';
      case AutoSyncStatus.tokenExpired:
        return '${peerName ?? '对方设备'}的配对已失效，请重新配对';
      case AutoSyncStatus.versionMismatch:
        return message ?? '两端版本不一致';
      case AutoSyncStatus.failed:
        return message ?? '同步失败';
      case AutoSyncStatus.ok:
        return '已同步 ${peerName ?? '对方设备'}：'
            '合入 ${outcome!.pulled.totalChanged} 条，'
            '推送 ${outcome!.pushed.totalChanged} 条';
    }
  }
}

/// 启动时自动连一次已配对的设备。
///
/// 设计取舍：
/// - **不弹窗、不阻塞启动**。`tryOnce()` 由 `home_shell` 在首帧之后触发，
///   用户已经能看到界面；
/// - **3 秒硬超时**。同一局域网连不上就是连不上，等下去只会让人以为卡死；
/// - **只在「需要人处理」时提示**：版本不一致、令牌失效。连不上静默，
///   对方关机是很正常的事。
class AutoSyncService {
  AutoSyncService({
    required AppDatabase db,
    required String deviceId,
    required String deviceName,
    Set<String>? skipPeers,
  }) : _db = db,
       _skipPeers = skipPeers ?? const <String>{},
       _client = SyncClient(db: db, deviceId: deviceId, deviceName: deviceName);

  final AppDatabase _db;
  final SyncClient _client;

  /// 本次会话里已经连不上的对端。常关机的电脑不该把另一台堵死。
  final Set<String> _skipPeers;

  /// 最近一次 [tryOnce] 尝试的对端，供调用方记录失败、下次跳过。
  String? attemptedPeerId;

  Future<AutoSyncResult> tryOnce() async {
    final peer = await _pickPeer();
    if (peer == null) {
      return const AutoSyncResult(status: AutoSyncStatus.noPeer);
    }

    attemptedPeerId = peer.peerId;
    final name = peer.peerName ?? '对方设备';
    final host = peer.peerHost!;
    final port = peer.peerPort!;

    // 1) 探活。连不上是最常见的结局，必须快速返回。
    Map<String, dynamic> info;
    try {
      info = await _client.ping(host, port).timeout(SyncClient.probeTimeout);
    } on TimeoutException {
      return AutoSyncResult(status: AutoSyncStatus.offline, peerName: name);
    } on SocketException {
      return AutoSyncResult(status: AutoSyncStatus.offline, peerName: name);
    } catch (_) {
      return AutoSyncResult(status: AutoSyncStatus.offline, peerName: name);
    }

    // 2) 版本。差一代就没法合，早说早解决。
    final remote = (info['schema_version'] as num?)?.toInt();
    if (remote != null && remote != _db.schemaVersion) {
      return AutoSyncResult(
        status: AutoSyncStatus.versionMismatch,
        peerName: name,
        message:
            '两端版本不一致：本机 v${_db.schemaVersion}，对方 v$remote。\n'
            '请把两台设备都升级到同一个安装包后再同步。',
      );
    }

    // 3) 同步。
    try {
      final outcome = await _client.sync(
        host: host,
        port: port,
        token: peer.peerToken!,
      );
      final now = DateTime.now();
      await (_db.update(
        _db.syncStates,
      )..where((t) => t.peerId.equals(peer.peerId))).write(
        SyncStatesCompanion(
          lastPullAt: Value(now),
          lastPushAt: Value(now),
          lastSyncAt: Value(now),
        ),
      );
      return AutoSyncResult(
        status: AutoSyncStatus.ok,
        peerName: name,
        outcome: outcome,
      );
    } on SyncException catch (e) {
      final expired = e.message.contains('令牌') || e.message.contains('401');
      return AutoSyncResult(
        status: expired ? AutoSyncStatus.tokenExpired : AutoSyncStatus.failed,
        peerName: name,
        message: e.message,
      );
    } catch (e) {
      return AutoSyncResult(
        status: AutoSyncStatus.failed,
        peerName: name,
        message: '$e',
      );
    }
  }

  /// 取一台可以自动连的设备。多台时取最近同步过的那台。
  Future<SyncState?> _pickPeer() async {
    // 三个「不为空」条件放在 Dart 侧筛：drift 的 Expression 组合在
    // 只做 show Value 的 import 下拿不到 `&` 运算符，而完整 import 会和
    // 业务类型撞名。行数最多两台设备，内存过滤代价可以忽略。
    final rows = (await _db.select(_db.syncStates).get())
        .where(
          (t) =>
              t.autoSync == 1 &&
              t.peerToken != null &&
              t.peerHost != null &&
              t.peerPort != null,
        )
        .toList();
    if (rows.isEmpty) return null;
    rows.sort((a, b) {
      final x = a.lastSyncAt ?? a.pairedAt;
      final y = b.lastSyncAt ?? b.pairedAt;
      return y.compareTo(x);
    });
    // 跳过这次会话里已经失败的。全都被跳过时回退到原列表 ——
    // 否则对方后来开机了也永远轮不到。
    final fresh = rows.where((r) => !_skipPeers.contains(r.peerId)).toList();
    return (fresh.isEmpty ? rows : fresh).first;
  }
}
