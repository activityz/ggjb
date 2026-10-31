import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/db/app_database.dart';
import 'merge.dart';

/// 局域网同步的「客户端」：连上对方的 [SyncHost]，双向交换整库快照。
///
/// 一次完整同步 = 先 pull（拉对方快照并合并进本地）+ 再 push（把本地快照推给对方合并）。
/// 两边合并规则都是「updated_at 较新者胜」，所以顺序无关，重复执行也安全。
class SyncClient {
  SyncClient({
    required AppDatabase db,
    required String deviceId,
    required String deviceName,
    MergeService? mergeService,
  })  : _db = db,
        _deviceId = deviceId,
        _deviceName = deviceName,
        _merge = mergeService ?? MergeService(db);

  final AppDatabase _db;
  final String _deviceId;
  final String _deviceName;
  final MergeService _merge;

  static const _timeout = Duration(seconds: 30);
  static const _transferTimeout = Duration(seconds: 180);

  /// 自动同步的探测超时：只在「同一局域网」场景用，3 秒连不上就当天没戏，
  /// 不该让启动流程干等。
  static const probeTimeout = Duration(seconds: 3);

  Uri _url(String host, int port, String path) =>
      Uri.parse('http://$host:$port$path');

  /// 探测对方是否在线、是不是本应用。
  Future<Map<String, dynamic>> ping(String host, int port) async {
    final resp = await http
        .get(_url(host, port, '/v1/info'))
        .timeout(_timeout);
    if (resp.statusCode != 200) {
      throw SyncException('对方返回 ${resp.statusCode}');
    }
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }

  /// 用 6 位配对码换取令牌。
  ///
  /// 换到的令牌会立刻写进 `sync_states`，重启应用后自动同步直接用它。
  Future<PairResult> pair(String host, int port, String code) async {
    final resp = await http
        .post(
          _url(host, port, '/v1/pair'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'code': code.trim(),
            'device_id': _deviceId,
            'device_name': _deviceName,
          }),
        )
        .timeout(_timeout);

    final body = utf8.decode(resp.bodyBytes);
    if (resp.statusCode != 200) {
      final message = _errorOf(body) ?? '配对失败（${resp.statusCode}）';
      throw SyncException(message);
    }
    final map = jsonDecode(body) as Map<String, dynamic>;
    final result = PairResult(
      token: map['peer_token'] as String,
      deviceId: map['device_id'] as String? ?? '',
      deviceName: map['device_name'] as String? ?? '对方设备',
    );
    await rememberPeer(host: host, port: port, peer: result);
    return result;
  }

  /// 记住对端地址与令牌。下次启动直接连它，不再问用户配对码。
  Future<void> rememberPeer({
    required String host,
    required int port,
    required PairResult peer,
  }) async {
    await _db.into(_db.syncStates).insertOnConflictUpdate(
          SyncStatesCompanion.insert(
            peerId: peer.deviceId.isEmpty ? '$host:$port' : peer.deviceId,
            peerName: Value(peer.deviceName),
            peerToken: Value(peer.token),
            peerHost: Value(host),
            peerPort: Value(port),
            pairedAt: DateTime.now(),
          ),
        );
  }

  /// 拉对方快照并合并进本地库。
  Future<MergeReport> pullAndMerge({
    required String host,
    required int port,
    required String token,
  }) async {
    final resp = await http
        .get(
          _url(host, port, '/v1/snapshot'),
          headers: {'authorization': 'Bearer $token'},
        )
        .timeout(_transferTimeout);

    if (resp.statusCode != 200) {
      throw SyncException(
        _errorOf(utf8.decode(resp.bodyBytes)) ?? '拉取快照失败（${resp.statusCode}）',
      );
    }

    final tmp = await _tempFile('pull');
    try {
      await tmp.writeAsBytes(resp.bodyBytes, flush: true);
      return await _merge.mergeFromFile(tmp.path);
    } finally {
      if (await tmp.exists()) await tmp.delete();
    }
  }

  /// 把本地快照推给对方，让对方合并。返回对方上报的合并计数。
  Future<MergeReport> pushTo({
    required String host,
    required int port,
    required String token,
  }) async {
    final snapshot = await _tempFile('push');
    try {
      if (await snapshot.exists()) await snapshot.delete();
      await _db.vacuumInto(snapshot.path);
      final bytes = await snapshot.readAsBytes();

      final resp = await http
          .post(
            _url(host, port, '/v1/snapshot'),
            headers: {
              'authorization': 'Bearer $token',
              'content-type': 'application/octet-stream',
            },
            body: bytes,
          )
          .timeout(_transferTimeout);

      final text = utf8.decode(resp.bodyBytes);
      if (resp.statusCode != 200) {
        throw SyncException(_errorOf(text) ?? '推送快照失败（${resp.statusCode}）');
      }
      final map = jsonDecode(text) as Map<String, dynamic>;
      return MergeReport(
        itemsInserted: (map['items_inserted'] as num?)?.toInt() ?? 0,
        itemsReplaced: (map['items_replaced'] as num?)?.toInt() ?? 0,
        expensesInserted: (map['expenses_inserted'] as num?)?.toInt() ?? 0,
        expensesReplaced: (map['expenses_replaced'] as num?)?.toInt() ?? 0,
        attachmentsInserted: (map['attachments_inserted'] as num?)?.toInt() ?? 0,
        attachmentsReplaced: (map['attachments_replaced'] as num?)?.toInt() ?? 0,
      );
    } finally {
      if (await snapshot.exists()) await snapshot.delete();
    }
  }

  /// 完整双向同步：先验版本，再拉后推。
  ///
  /// 版本不一致时立刻停下 —— 两端 schema 差一代，合并会撞上
  /// [MergeService] 的列校验，报出来的「列数不一致」对用户毫无意义，
  /// 直接说「升级到同一个包」才可操作。
  Future<SyncOutcome> sync({
    required String host,
    required int port,
    required String token,
  }) async {
    final info = await ping(host, port);
    final remote = (info['schema_version'] as num?)?.toInt();
    if (remote != null && remote != _db.schemaVersion) {
      throw SyncException(
        '两端版本不一致：本机 v${_db.schemaVersion}，对方 v$remote。\n'
        '请把两台设备都升级到同一个安装包后再同步。',
      );
    }
    final pulled = await pullAndMerge(host: host, port: port, token: token);
    final pushed = await pushTo(host: host, port: port, token: token);
    return SyncOutcome(pulled: pulled, pushed: pushed);
  }

  Future<File> _tempFile(String prefix) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return File(p.join(dir.path, 'ggjb_${prefix}_$stamp.db'));
  }

  static String? _errorOf(String body) {
    try {
      final map = jsonDecode(body);
      if (map is Map && map['error'] != null) return map['error'].toString();
    } catch (_) {
      // 不是 JSON 就交给调用方用状态码兜底。
    }
    return null;
  }
}

class SyncException implements Exception {
  SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PairResult {
  PairResult({required this.token, required this.deviceId, required this.deviceName});

  final String token;
  final String deviceId;
  final String deviceName;
}

class SyncOutcome {
  SyncOutcome({required this.pulled, required this.pushed});

  /// 从对方拉回来的记录合并进本地的结果。
  final MergeReport pulled;

  /// 本地推给对方、由对方合并的结果。
  final MergeReport pushed;

  String describe() =>
      '拉取：${pulled.describe()}；推送：${pushed.describe()}';
}
