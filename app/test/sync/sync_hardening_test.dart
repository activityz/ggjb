// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/sync/auto_sync.dart';
import 'package:ggjb/sync/client.dart';
import 'package:ggjb/sync/host_server.dart';
import 'package:ggjb/sync/merge.dart';
import 'package:ggjb/sync/sync_controller.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _TempPath extends PathProviderPlatform {
  _TempPath(this.root);
  final String root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

Future<AppDatabase> _db() async {
  final db = AppDatabase(NativeDatabase.memory());
  await db.customSelect('SELECT 1').get();
  return db;
}

void main() {
  test('自动同步监听的表必须覆盖合并同步的全部表', () async {
    final db = await _db();
    final watched = SyncController.watchedTables(db);
    expect(watched.length, MergeService.syncedTables.length);
    // 逐张点名：少一张就会出现「改了不触发，要等 25 秒轮询」。
    expect(watched, contains(db.items));
    expect(watched, contains(db.expenses));
    expect(watched, contains(db.attachments));
    expect(watched, contains(db.dictEntries));
    expect(watched, contains(db.operatingCosts));
    await db.close();
  });

  test('推送失败不会在临时目录留下整库文件', () async {
    final dir = await Directory.systemTemp.createTemp('ggjb_tmp_');
    PathProviderPlatform.instance = _TempPath(dir.path);
    final db = await _db();
    await db
        .into(db.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            peerId: 'peer-x',
            peerToken: const Value('tok-bad'),
            pairedAt: DateTime(2026, 1, 1),
          ),
        );
    final host = SyncHost(db: db, deviceId: 'host', deviceName: '主机');
    final port = await host.start(port: 0);

    final resp = await http.post(
      Uri.parse('http://127.0.0.1:$port/v1/snapshot'),
      headers: {
        'authorization': 'Bearer tok-bad',
        'content-type': 'application/octet-stream',
      },
      body: [1, 2, 3, 4, 5],
    );
    expect(resp.statusCode, 500);

    final leftover = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('ggjb_'))
        .toList();
    expect(leftover, isEmpty, reason: '失败的合并留下 $leftover');

    await host.stop();
    await db.close();
    await dir.delete(recursive: true);
  });

  test('解绑后对端的令牌立即失效', () async {
    final dir = await Directory.systemTemp.createTemp('ggjb_tmp_');
    PathProviderPlatform.instance = _TempPath(dir.path);
    final db = await _db();
    await db
        .into(db.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            peerId: 'peer-x',
            peerToken: const Value('tok-unpair'),
            pairedAt: DateTime(2026, 1, 1),
          ),
        );
    final host = SyncHost(db: db, deviceId: 'host', deviceName: '主机');
    final port = await host.start(port: 0);
    final client = SyncClient(db: db, deviceId: 'me', deviceName: '本机');

    final before = await http.get(
      Uri.parse('http://127.0.0.1:$port/v1/snapshot'),
      headers: {'authorization': 'Bearer tok-unpair'},
    );
    expect(before.statusCode, 200);

    await client.unpair(host: '127.0.0.1', port: port, token: 'tok-unpair');

    final after = await http.get(
      Uri.parse('http://127.0.0.1:$port/v1/snapshot'),
      headers: {'authorization': 'Bearer tok-unpair'},
    );
    expect(after.statusCode, 401);

    await host.stop();
    await db.close();
    await dir.delete(recursive: true);
  });
  test('一台连不上时下一次会换另一台', () async {
    final dir = await Directory.systemTemp.createTemp('ggjb_hard_');
    PathProviderPlatform.instance = _TempPath(dir.path);
    final db = await _db();

    final server = await shelf_io.serve(
      (Request req) async {
        if (req.url.path == 'v1/info') {
          return Response.ok(jsonEncode({'schema_version': db.schemaVersion}));
        }
        if (req.method == 'GET') {
          final tmp = File(
            '${dir.path}/snap_${DateTime.now().microsecondsSinceEpoch}.db',
          );
          final other = AppDatabase(NativeDatabase(tmp));
          await other.customSelect('SELECT 1').get();
          await other.close();
          final bytes = await tmp.readAsBytes();
          await tmp.delete();
          return Response.ok(bytes);
        }
        return Response.ok(jsonEncode({'ok': true, 'items_inserted': 0}));
      },
      '127.0.0.1',
      0,
    );

    final probe = await ServerSocket.bind('127.0.0.1', 0);
    final deadPort = probe.port;
    await probe.close();

    await db
        .into(db.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            peerId: 'peer-A',
            peerName: const Value('旧电脑'),
            peerToken: const Value('tok-a'),
            peerHost: const Value('127.0.0.1'),
            peerPort: Value(deadPort),
            pairedAt: DateTime(2025, 1, 1),
            lastSyncAt: Value(DateTime(2026, 3, 1)),
          ),
        );
    await db
        .into(db.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            peerId: 'peer-B',
            peerName: const Value('新电脑'),
            peerToken: const Value('tok-b'),
            peerHost: const Value('127.0.0.1'),
            peerPort: Value(server.port),
            pairedAt: DateTime(2025, 1, 1),
            lastSyncAt: Value(DateTime(2026, 2, 1)),
          ),
        );

    final first = AutoSyncService(db: db, deviceId: 'me', deviceName: '本机');
    final r1 = await first.tryOnce();
    expect(r1.status, AutoSyncStatus.offline);
    expect(first.attemptedPeerId, 'peer-A');

    final second = AutoSyncService(
      db: db,
      deviceId: 'me',
      deviceName: '本机',
      skipPeers: {first.attemptedPeerId!},
    );
    final r2 = await second.tryOnce();
    expect(second.attemptedPeerId, 'peer-B');
    expect(r2.ok, isTrue, reason: r2.describe());

    await server.close(force: true);
    await db.close();
    await dir.delete(recursive: true);
  });
  test('配对码连错多次会被限速', () async {
    final dir = await Directory.systemTemp.createTemp('ggjb_tmp_');
    PathProviderPlatform.instance = _TempPath(dir.path);
    final db = await _db();
    final host = SyncHost(
      db: db,
      deviceId: 'host',
      deviceName: '主机',
      maxPairAttempts: 3,
    );
    final port = await host.start(port: 0);

    final codes = <int>[];
    for (var i = 0; i < 4; i++) {
      final r = await http.post(
        Uri.parse('http://127.0.0.1:$port/v1/pair'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'code': '000000', 'device_id': 'attacker'}),
      );
      codes.add(r.statusCode);
    }
    expect(codes.take(3), everyElement(403));
    expect(codes.last, 429, reason: '错满之后要挡住在猜的那一端');

    await host.stop();
    await db.close();
    await dir.delete(recursive: true);
  });

  test('超过体积上限的快照被拒且不留临时文件', () async {
    final dir = await Directory.systemTemp.createTemp('ggjb_tmp_');
    PathProviderPlatform.instance = _TempPath(dir.path);
    final db = await _db();
    await db
        .into(db.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            peerId: 'peer-x',
            peerToken: const Value('tok-big'),
            pairedAt: DateTime(2026, 1, 1),
          ),
        );
    final host = SyncHost(
      db: db,
      deviceId: 'host',
      deviceName: '主机',
      maxSnapshotBytes: 1024,
    );
    final port = await host.start(port: 0);

    final resp = await http.post(
      Uri.parse('http://127.0.0.1:$port/v1/snapshot'),
      headers: {
        'authorization': 'Bearer tok-big',
        'content-type': 'application/octet-stream',
      },
      body: List<int>.filled(4096, 7),
    );
    expect(resp.statusCode, 413);
    expect(
      dir.listSync().whereType<File>().where(
        (f) => f.uri.pathSegments.last.startsWith('ggjb_'),
      ),
      isEmpty,
    );

    await host.stop();
    await db.close();
    await dir.delete(recursive: true);
  });
}
