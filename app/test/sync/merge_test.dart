import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/sync/merge.dart';

/// seam: MergeService —— 跨设备整库合并的冲突裁决。
/// 规则：(updated_at, device_id) 全序取大者胜；完全相等则保留本地。
void main() {
  late Directory dir;
  late String localPath;
  late String remotePath;
  late AppDatabase local;
  late AppDatabase remote;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ggjb_merge_');
    localPath = '${dir.path}/local.sqlite';
    remotePath = '${dir.path}/remote.sqlite';
    local = AppDatabase(NativeDatabase(File(localPath)));
    remote = AppDatabase(NativeDatabase(File(remotePath)));
    // 先把 schema 建出来，ATTACH 后 PRAGMA table_info 才读得到列
    await local.customSelect('SELECT 1').get();
    await remote.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await local.close();
    await remote.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> put(
    AppDatabase db,
    String id, {
    required String title,
    DateTime? updatedAt,
    String deviceId = 'dev-a',
    ItemStatus status = ItemStatus.inStock,
  }) async {
    final created = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: title,
            buyPriceCents: 100000,
            createdAt: created,
            updatedAt: updatedAt ?? created,
            deviceId: deviceId,
            status: Value(status),
          ),
        );
  }

  test('远端独有的行会被插入，本地原有行不动', () async {
    await put(local, 'a', title: '本地机');
    await put(remote, 'b', title: '远端机');
    await remote.close();

    final report = await MergeService(local).mergeFromFile(remotePath);

    expect(report.itemsInserted, 1);
    expect(report.itemsReplaced, 0);
    expect(report.totalChanged, greaterThan(0));

    final titles = await local
        .customSelect('SELECT id, title FROM items ORDER BY id')
        .get()
        .then((r) => r.map((x) => x.data['title'] as String).toList());
    expect(titles, ['本地机', '远端机']);
  });

  test('同一行远端更新时，远端覆盖本地', () async {
    await put(local, 'a', title: '旧标题', updatedAt: DateTime(2026, 1, 1));
    await put(remote, 'a', title: '新标题', updatedAt: DateTime(2026, 2, 1));
    await remote.close();

    final report = await MergeService(local).mergeFromFile(remotePath);

    expect(report.itemsInserted, 0);
    expect(report.itemsReplaced, 1);
    final title = await local
        .customSelect("SELECT title FROM items WHERE id = 'a'")
        .getSingle()
        .then((r) => r.data['title'] as String);
    expect(title, '新标题');
  });

  test('本地更新时保留本地，远端旧版本不进库', () async {
    await put(local, 'a', title: '本地新版', updatedAt: DateTime(2026, 3, 1));
    await put(remote, 'a', title: '远端旧版', updatedAt: DateTime(2026, 2, 1));
    await remote.close();

    final report = await MergeService(local).mergeFromFile(remotePath);

    expect(report.itemsReplaced, 1, reason: '两边都有，算覆盖口径');
    final title = await local
        .customSelect("SELECT title FROM items WHERE id = 'a'")
        .getSingle()
        .then((r) => r.data['title'] as String);
    expect(title, '本地新版', reason: '较旧的一方不该覆盖较新的');
  });

  test('updated_at 相同时 device_id 大者胜', () async {
    final same = DateTime(2026, 5, 1);
    await put(local, 'a', title: 'dev-a 版', updatedAt: same, deviceId: 'dev-a');
    await put(
      remote,
      'a',
      title: 'dev-z 版',
      updatedAt: same,
      deviceId: 'dev-z',
    );
    await remote.close();

    await MergeService(local).mergeFromFile(remotePath);

    final title = await local
        .customSelect("SELECT title FROM items WHERE id = 'a'")
        .getSingle()
        .then((r) => r.data['title'] as String);
    expect(title, 'dev-z 版');
  });

  test('updated_at 与 device_id 都相同则保留本地，不报错', () async {
    final same = DateTime(2026, 5, 1);
    await put(local, 'a', title: '本地', updatedAt: same, deviceId: 'dev-a');
    await put(remote, 'a', title: '远端', updatedAt: same, deviceId: 'dev-a');
    await remote.close();

    final report = await MergeService(local).mergeFromFile(remotePath);

    expect(report.itemsReplaced, 1);
    final title = await local
        .customSelect("SELECT title FROM items WHERE id = 'a'")
        .getSingle()
        .then((r) => r.data['title'] as String);
    expect(title, '本地');
  });

  test('文件不存在时抛 MergeException', () async {
    await expectLater(
      MergeService(local).mergeFromFile('${dir.path}/nope.sqlite'),
      throwsA(isA<MergeException>()),
    );
  });

  test('合并完成后 drift 的 stream 能读到新数据', () async {
    await put(remote, 'x', title: '远端独有');
    await remote.close();

    final stream = local.select(local.items).watch();
    final first = await stream.first;
    expect(first, isEmpty);

    await MergeService(local).mergeFromFile(remotePath);

    final rows = await local.select(local.items).get();
    expect(rows.map((r) => r.title), contains('远端独有'));
  });
}
