import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../data/db/app_database.dart';
import 'merge.dart';

/// 局域网同步的「服务端」：任意一端都能当 Host。
///
/// 协议刻意做成「整库快照交换」而不是记录级增量：
/// - 少一套容易出错的增删改协议，两端都只依赖 [MergeService] 的合并语义；
/// - 个人库规模（千级记录）下 VACUUM 出的快照只有几 MB，传一次几秒；
/// - 图片跟着库走，不需要单独的附件通道。
///
/// 代价是每次同步要传全库。以后库变大再加「仅文本」开关。
class SyncHost {
  SyncHost({
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

  HttpServer? _server;
  String? _pairCode;
  final _tokens = <String>{};
  final _random = Random.secure();

  bool get isRunning => _server != null;
  int? get port => _server?.port;

  /// 当前的有效配对码；只有处于监听状态时才存在。
  String? get pairCode => _pairCode;

  Future<int> start({int port = 8787}) async {
    if (_server != null) return _server!.port;

    // 重启后旧对端手里的令牌必须仍然有效，否则「下次自动同步」永远连不通。
    final saved = await _db.select(_db.syncStates).get();
    _tokens
      ..clear()
      ..addAll(
        saved
            .map((row) => row.peerToken)
            .whereType<String>()
            .where((t) => t.isNotEmpty),
      );

    _pairCode = (100000 + _random.nextInt(900000)).toString();

    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware)
        .addHandler(_router().call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    return _server!.port;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _pairCode = null;
    _tokens.clear();
  }

  Router _router() {
    final router = Router();

    router.get('/v1/info', (Request req) {
      return _json({
        'device_id': _deviceId,
        'device_name': _deviceName,
        'schema_version': _db.schemaVersion,
        'pairing_required': true,
      });
    });

    router.post('/v1/pair', (Request req) async {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final code = body['code']?.toString();
      if (code == null || code != _pairCode) {
        return _json({'error': '配对码不正确'}, status: 403);
      }
      final token = _newToken();
      _tokens.add(token);

      // 记住对端身份，把令牌落盘 —— 只放内存的话进程一退出就全失效。
      final peerId = body['device_id']?.toString();
      if (peerId != null && peerId.isNotEmpty) {
        // 连 peerHost / peerPort 一起记。`AutoSyncService._pickPeer()` 要求
        // host、port、token 三者齐全，缺一个就当「没配对」——只记 token 的话，
        // 被配对的这一端永远不知道该往哪连，于是「电脑端不会自动同步」。
        final conn = req.context['shelf.io.connection_info'];
        var remoteHost =
            conn is HttpConnectionInfo ? conn.remoteAddress.address : null;
        // Windows 上常拿到 IPv4-mapped IPv6（::ffff:192.168.1.5），
        // 直接用会让 HttpClient 连得很慢甚至失败，拆成纯 v4。
        if (remoteHost != null && remoteHost.startsWith('::ffff:')) {
          remoteHost = remoteHost.substring(7);
        }
        if (remoteHost == '::1') remoteHost = '127.0.0.1';

        await _db.into(_db.syncStates).insertOnConflictUpdate(
              SyncStatesCompanion.insert(
                peerId: peerId,
                peerName: Value(body['device_name']?.toString()),
                peerToken: Value(token),
                peerHost: Value(remoteHost),
                // 对端监听的端口：两端都按约定用 8787（SyncHost.start 的默认值）。
                peerPort: const Value(8787),
                pairedAt: DateTime.now(),
              ),
            );
      }

      return _json({
        'peer_token': token,
        'device_id': _deviceId,
        'device_name': _deviceName,
      });
    });

    router.get('/v1/snapshot', (Request req) async {
      if (!_authorized(req)) return _json({'error': '缺少或无效的令牌'}, status: 401);
      try {
        final file = await _makeSnapshot();
        final bytes = await file.readAsBytes();
        await file.delete();
        return Response.ok(
          bytes,
          headers: {
            'content-type': 'application/octet-stream',
            'content-length': '${bytes.length}',
          },
        );
      } catch (e) {
        return _json({'error': '生成快照失败：$e'}, status: 500);
      }
    });

    router.post('/v1/snapshot', (Request req) async {
      if (!_authorized(req)) return _json({'error': '缺少或无效的令牌'}, status: 401);
      try {
        final chunks = await req.read().expand((c) => c).toList();
        final tmp = await _tempFile('incoming');
        await tmp.writeAsBytes(chunks, flush: true);
        final report = await _merge.mergeFromFile(tmp.path);
        await tmp.delete();
        return _json({
          'ok': true,
          'items_inserted': report.itemsInserted,
          'items_replaced': report.itemsReplaced,
          'expenses_inserted': report.expensesInserted,
          'expenses_replaced': report.expensesReplaced,
          'attachments_inserted': report.attachmentsInserted,
          'attachments_replaced': report.attachmentsReplaced,
        });
      } catch (e) {
        return _json({'error': '合并失败：$e'}, status: 500);
      }
    });

    return router;
  }

  bool _authorized(Request req) {
    final auth = req.headers['authorization'];
    if (auth == null || !auth.startsWith('Bearer ')) return false;
    return _tokens.contains(auth.substring(7));
  }

  Future<File> _makeSnapshot() async {
    final tmp = await _tempFile('outgoing');
    if (await tmp.exists()) await tmp.delete();
    await _db.vacuumInto(tmp.path);
    return tmp;
  }

  Future<File> _tempFile(String prefix) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return File(p.join(dir.path, 'ggjb_${prefix}_$stamp.db'));
  }

  String _newToken() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static Response _json(Map<String, dynamic> body, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  /// 手机浏览器手输地址时免不了跨域预检，这里统一放行本机使用场景。
  static Handler _corsMiddleware(Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await inner(request);
      return response.change(headers: _corsHeaders);
    };
  }

  static const _corsHeaders = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
  };
}
