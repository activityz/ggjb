// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/sync/auto_sync.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.dir);

  final String dir;

  @override
  Future<String?> getTemporaryPath() async => dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

/// seam: AutoSyncService.tryOnce —— 启动时那一次静默同步的决策表。
void main() {
  late Directory tmpDir;
  late AppDatabase db;
  late AutoSyncService service;
  HttpServer? server;

  setUpAll(() {
    tmpDir = Directory.systemTemp.createTempSync('ggjb_autosync_');
    PathProviderPlatform.instance = _TempPathProvider(tmpDir.path);
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = AutoSyncService(db: db, deviceId: 'me', deviceName: '本机');
  });

  tearDown(() async {
    if (server != null) {
      await server!.close(force: true);
      server = null;
    }
    await db.close();
  });

  tearDownAll(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  Future<void> putPeer(
    String id, {
    required String host,
    required int port,
    String token = 'tok',
    int autoSync = 1,
    DateTime? lastSyncAt,
  }) async {
    await db
        .into(db.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            peerId: id,
            peerName: Value('对端 $id'),
            peerToken: Value(token),
            peerHost: Value(host),
            peerPort: Value(port),
            autoSync: Value(autoSync),
            lastSyncAt: Value(lastSyncAt),
            pairedAt: DateTime(2026, 1, 1),
          ),
        );
  }

  Future<int> startFake({
    int versionDelta = 0,
    bool rejectSnapshot = false,
    bool failAll = false,
  }) async {
    final served = AppDatabase(NativeDatabase.memory());
    Future<Response> handler(Request req) async {
      Response json(Map<String, dynamic> body, {int status = 200}) => Response(
        status,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

      switch ('${req.method} ${req.url.path}') {
        case 'GET v1/info':
          return json({
            'device_id': 'fake',
            'device_name': '假服务端',
            'schema_version': served.schemaVersion + versionDelta,
            'pairing_required': true,
          });
        case 'GET v1/snapshot':
          if (rejectSnapshot) {
            return json({'error': '缺少或无效的令牌'}, status: 401);
          }
          final tmp = File('${tmpDir.path}/fake_snapshot.db');
          if (tmp.existsSync()) tmp.deleteSync();
          await served.vacuumInto(tmp.path);
          final bytes = await tmp.readAsBytes();
          tmp.deleteSync();
          return Response.ok(
            bytes,
            headers: {'content-type': 'application/octet-stream'},
          );
        case 'POST v1/snapshot':
          if (failAll) return json({'error': '合并失败'}, status: 500);
          return json({
            'ok': true,
            'items_inserted': 0,
            'items_replaced': 0,
            'expenses_inserted': 0,
            'expenses_replaced': 0,
            'attachments_inserted': 0,
            'attachments_replaced': 0,
          });
        default:
          return json({'error': 'not found'}, status: 404);
      }
    }

    server = await shelf_io.serve(handler, '127.0.0.1', 0);
    addTearDown(served.close);
    return server!.port;
  }

  test('没配对过设备时返回 noPeer，且不打扰用户', () async {
    final result = await service.tryOnce();
    expect(result.status, AutoSyncStatus.noPeer);
    expect(result.shouldNotify, isFalse);
    expect(result.describe(), '还没有配对过设备');
  });

  test('autoSync 关掉的设备不参与自动同步', () async {
    final port = await startFake();
    await putPeer('p1', host: '127.0.0.1', port: port, autoSync: 0);

    final result = await service.tryOnce();
    expect(result.status, AutoSyncStatus.noPeer);
  });

  test('对端端口没人听时返回 offline，且不打扰用户', () async {
    final probe = await ServerSocket.bind('127.0.0.1', 0);
    final deadPort = probe.port;
    await probe.close();

    await putPeer('p1', host: '127.0.0.1', port: deadPort);

    final result = await service.tryOnce();
    expect(result.status, AutoSyncStatus.offline);
    expect(result.peerName, '对端 p1');
    expect(result.shouldNotify, isFalse);
  });

  test('两端 schema 版本不一致时返回 versionMismatch 并提示升级', () async {
    final port = await startFake(versionDelta: 1);
    await putPeer('p1', host: '127.0.0.1', port: port);

    final result = await service.tryOnce();
    expect(result.status, AutoSyncStatus.versionMismatch);
    expect(result.shouldNotify, isTrue);
    expect(result.message, contains('v${db.schemaVersion}'));
  });

  test('令牌被对方丢掉时返回 tokenExpired 并提示重新配对', () async {
    final port = await startFake(rejectSnapshot: true);
    await putPeer('p1', host: '127.0.0.1', port: port);

    final result = await service.tryOnce();
    expect(result.status, AutoSyncStatus.tokenExpired);
    expect(result.shouldNotify, isTrue);
    expect(result.describe(), contains('重新配对'));
  });

  test('同步成功后回写 lastSyncAt / lastPullAt / lastPushAt', () async {
    final port = await startFake();
    await putPeer('p1', host: '127.0.0.1', port: port);

    final result = await service.tryOnce();
    expect(result.status, AutoSyncStatus.ok, reason: result.message ?? '');
    expect(result.describe(), contains('已同步'));

    final row = await (db.select(
      db.syncStates,
    )..where((t) => t.peerId.equals('p1'))).getSingle();
    expect(row.lastSyncAt, isNotNull);
    expect(row.lastPullAt, isNotNull);
    expect(row.lastPushAt, isNotNull);
  });

  test('推送阶段出错时返回 failed 并带上原因', () async {
    final port = await startFake(failAll: true);
    await putPeer('p1', host: '127.0.0.1', port: port);

    final result = await service.tryOnce();
    expect(result.status, AutoSyncStatus.failed);
    expect(result.message, isNotNull);
    expect(result.shouldNotify, isFalse);
  });

  test('多台已配对设备时选最近同步过的那台', () async {
    final port = await startFake(rejectSnapshot: true);
    await putPeer(
      'old',
      host: '127.0.0.1',
      port: port,
      lastSyncAt: DateTime(2026, 1, 1),
    );
    await putPeer(
      'new',
      host: '127.0.0.1',
      port: port,
      lastSyncAt: DateTime(2026, 5, 1),
    );

    final result = await service.tryOnce();
    expect(result.peerName, '对端 new');
  });
}
