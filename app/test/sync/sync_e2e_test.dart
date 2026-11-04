// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/sync/client.dart';
import 'package:ggjb/sync/host_server.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

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

/// seam: SyncHost 与 SyncClient 的真实 HTTP 往返。
///
/// 不 mock http：这一层唯一的价值就是「两端真的能连上并把数据搬过去」，
/// 用假 client 测等于把要验的东西替换掉了。
void main() {
  late Directory tmpDir;
  late AppDatabase hostDb;
  late AppDatabase clientDb;
  late SyncHost host;
  late SyncClient client;
  late int port;

  const token = 'tok-e2e';

  setUpAll(() {
    tmpDir = Directory.systemTemp.createTempSync('ggjb_sync_');
    PathProviderPlatform.instance = _TempPathProvider(tmpDir.path);
  });

  setUp(() async {
    hostDb = AppDatabase(NativeDatabase.memory());
    clientDb = AppDatabase(NativeDatabase.memory());

    // SyncHost.start() 会从 sync_states 里加载已发出的令牌，
    // 预置一条等于「对方早就配过对」。
    await hostDb
        .into(hostDb.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            peerId: 'client-device',
            peerName: const Value('客户端'),
            peerToken: const Value(token),
            pairedAt: DateTime(2026, 1, 1),
          ),
        );

    host = SyncHost(db: hostDb, deviceId: 'host-device', deviceName: '主机');
    client = SyncClient(
      db: clientDb,
      deviceId: 'client-device',
      deviceName: '客户端',
    );
    port = await host.start(port: 0);
  });

  tearDown(() async {
    await host.stop();
    await clientDb.close();
    await hostDb.close();
  });

  tearDownAll(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  Future<void> putItem(
    AppDatabase db,
    String id, {
    String title = '测试机',
  }) async {
    final now = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: title,
            buyPriceCents: 100000,
            createdAt: now,
            updatedAt: now,
            deviceId: 'dev-test',
            status: const Value(ItemStatus.inStock),
          ),
        );
  }

  test('ping 不需要令牌，返回设备信息与 schema 版本', () async {
    final info = await client.ping('127.0.0.1', port);
    expect(info['device_id'], 'host-device');
    expect(info['device_name'], '主机');
    expect((info['schema_version'] as num).toInt(), hostDb.schemaVersion);
    expect(info['pairing_required'], isTrue);
  });

  test('配对码不对时报「配对码不正确」', () async {
    await expectLater(
      client.pair('127.0.0.1', port, '000000'),
      throwsA(
        isA<SyncException>().having((e) => e.message, 'message', '配对码不正确'),
      ),
    );
  });

  test('没有令牌时拉快照被拒', () async {
    await expectLater(
      client.pullAndMerge(host: '127.0.0.1', port: port, token: 'bad'),
      throwsA(
        isA<SyncException>().having((e) => e.message, 'message', '缺少或无效的令牌'),
      ),
    );
  });

  test('pullAndMerge 把对方数据搬进本地', () async {
    await putItem(hostDb, 'h1', title: '主机上的机器');

    final report = await client.pullAndMerge(
      host: '127.0.0.1',
      port: port,
      token: token,
    );
    expect(report.itemsInserted + report.itemsReplaced, 1);

    final rows = await clientDb.select(clientDb.items).get();
    expect(rows.single.id, 'h1');
    expect(rows.single.title, '主机上的机器');
  });

  test('pushTo 把本地数据推到对方', () async {
    await putItem(clientDb, 'c1', title: '客户端上的机器');

    final report = await client.pushTo(
      host: '127.0.0.1',
      port: port,
      token: token,
    );
    expect(report.itemsInserted + report.itemsReplaced, 1);

    final rows = await hostDb.select(hostDb.items).get();
    expect(rows.single.id, 'c1');
  });

  test('sync 先拉后推，两边都拿到对方的数据', () async {
    await putItem(hostDb, 'h1');
    await putItem(clientDb, 'c1');

    await client.sync(host: '127.0.0.1', port: port, token: token);

    expect((await clientDb.select(clientDb.items).get()).length, 2);
    expect((await hostDb.select(hostDb.items).get()).length, 2);
  });

  test('两端 schema 版本一致时才继续，不一致直接报升级', () async {
    // 同一份 AppDatabase 定义下版本必然相同，这里验证「一致就通过」这一半；
    // 不一致的分支由 auto_sync_test 用假服务端覆盖。
    final info = await client.ping('127.0.0.1', port);
    expect((info['schema_version'] as num).toInt(), clientDb.schemaVersion);
    await client.sync(host: '127.0.0.1', port: port, token: token);
  });

  test('拉快照时远端独有行应算「新增」而不是「覆盖」', () async {
    await putItem(hostDb, 'h1');
    final report = await client.pullAndMerge(
      host: '127.0.0.1',
      port: port,
      token: token,
    );
    expect(report.itemsInserted, 1);
    expect(report.itemsReplaced, 0);
  });

  test('推快照时对方也应报「新增」', () async {
    await putItem(clientDb, 'c1');
    final report = await client.pushTo(
      host: '127.0.0.1',
      port: port,
      token: token,
    );
    expect(report.itemsInserted, 1);
    expect(report.itemsReplaced, 0);
  });

  test('stop 之后连不上', () async {
    await host.stop();
    await expectLater(client.ping('127.0.0.1', port), throwsA(anything));
  });

  test('配对成功会记住对端地址与令牌', () async {
    // 配对码是启动时随机生成的，测试无法预知；这里验证「记住对端」这条
    // 由 rememberPeer 承担的逻辑，直接调它再读库。
    await client.rememberPeer(
      host: '192.168.1.9',
      port: 8787,
      peer: PairResult(
        token: 'tok-remember',
        deviceId: 'host-device',
        deviceName: '主机',
      ),
    );

    final row = await (clientDb.select(
      clientDb.syncStates,
    )..where((t) => t.peerId.equals('host-device'))).getSingle();
    expect(row.peerToken, 'tok-remember');
    expect(row.peerHost, '192.168.1.9');
    expect(row.peerPort, 8787);
  });

  test('CORS 头存在，浏览器端也能读', () async {
    final client0 = HttpClient();
    final req = await client0.getUrl(
      Uri.parse('http://127.0.0.1:$port/v1/info'),
    );
    final resp = await req.close();
    await resp.drain<void>();
    expect(resp.headers.value('access-control-allow-origin'), '*');
    client0.close();
  });

  test('错误响应的 body 是 JSON，能被 client 解析成中文提示', () async {
    final client0 = HttpClient();
    final req = await client0.postUrl(
      Uri.parse('http://127.0.0.1:$port/v1/pair'),
    );
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'code': '12345', 'device_id': 'x'}));
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    expect(resp.statusCode, 403);
    expect((jsonDecode(body) as Map)['error'], '配对码不正确');
    client0.close();
  });
}
