import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/dict_seeds.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> countOf(String sql) async {
    final row = await db.customSelect(sql).getSingle();
    return row.data.values.first as int;
  }

  Future<List<String>> labelsOf(String kind, {int? limit}) async {
    final rows = await db
        .customSelect(
          'SELECT label FROM dict_entries WHERE kind = ? ORDER BY sort_order, label'
          '${limit == null ? '' : ' LIMIT $limit'}',
          variables: [Variable.withString(kind)],
        )
        .get();
    return rows.map((r) => r.data['label']! as String).toList();
  }

  test('schemaVersion 是 6', () {
    expect(db.schemaVersion, 6);
  });

  test('七张业务表都建出来了', () async {
    const tables = [
      'items',
      'expenses',
      'attachments',
      'sync_states',
      'local_devices',
      'dict_entries',
      'operating_costs',
    ];
    for (final table in tables) {
      final columns = await db.customSelect('PRAGMA table_info($table)').get();
      expect(columns, isNotEmpty, reason: '$table 应该存在');
    }
  });

  test('同步与筛选依赖的索引都建了', () async {
    final rows = await db.customSelect("PRAGMA index_list('items')").get();
    final names = rows.map((r) => r.data['name']! as String).toSet();
    expect(names, contains('idx_items_updated_at'));
    expect(names, contains('idx_items_status'));
    expect(names, contains('idx_items_buy_date'));
    expect(names, contains('idx_items_sell_date'));

    final operating = await db
        .customSelect("PRAGMA index_list('operating_costs')")
        .get();
    final operatingNames = operating
        .map((r) => r.data['name']! as String)
        .toSet();
    expect(operatingNames, contains('idx_operating_spent_at'));
    expect(operatingNames, contains('idx_operating_updated_at'));
  });

  test('每个连接都打开外键校验', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.first, 1);
  });

  test('首次建库把字典种子写进去了', () async {
    expect(
      await countOf('SELECT COUNT(*) AS c FROM dict_entries'),
      greaterThan(0),
    );
    expect(await labelsOf(DictSeeds.kindOperating), DictSeeds.operating);
  });

  test('运营成本字典排在属于自己的类别里', () async {
    final kinds = await db
        .customSelect(
          'SELECT DISTINCT kind FROM dict_entries WHERE kind = ?',
          variables: [Variable.withString(DictSeeds.kindOperating)],
        )
        .get();
    expect(kinds, hasLength(1));
    expect(
      await countOf(
        'SELECT COUNT(*) AS c FROM dict_entries WHERE kind = '
        "'${DictSeeds.kindOperating}'",
      ),
      DictSeeds.operating.length,
    );
  });

  test('v5 新补的渠道用负数排序号排到来源最前', () async {
    final top = await labelsOf(DictSeeds.kindSource, limit: 2);
    expect(top, ['采货侠', '拍机堂']);
  });

  test('字典种子带 built_in 标记，同步时当作内置行', () async {
    expect(
      await countOf(
        'SELECT COUNT(*) AS c FROM dict_entries WHERE built_in = 0',
      ),
      0,
    );
    expect(
      await countOf(
        'SELECT COUNT(*) AS c FROM dict_entries WHERE device_id = '
        "'seed'",
      ),
      greaterThan(0),
    );
  });

  test('v5 旧库升级：三列补在末尾，旧行读出来是无保修', () async {
    // 真拿一个 user_version = 5 的旧文件来开：造一个只有旧列的表，
    // 再让 AppDatabase 走 onUpgrade 分支。
    final dir = await Directory.systemTemp.createTemp('ggjb_mig_');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // 临时目录删不掉不影响断言。
      }
    });
    final file = File('${dir.path}/old.sqlite');

    // 旧库的 DDL 不手抄：直接拿当前建表语句删掉三列，保证「除了这三列以
    // 外全部一致」——手抄漏一列就会变成测一个不存在的库。
    final ddl =
        (await db
                .customSelect(
                  "SELECT sql FROM sqlite_master WHERE name = 'items'",
                )
                .getSingle())
            .data['sql']! as String;

    final legacy = sqlite3.open(file.path);
    legacy.execute(ddl);
    legacy.execute('ALTER TABLE items DROP COLUMN warranty_status');
    legacy.execute('ALTER TABLE items DROP COLUMN warranty_start');
    legacy.execute('ALTER TABLE items DROP COLUMN warranty_end');
    legacy.execute(
      'INSERT INTO items (id, title, brand, note, status, buy_date, '
      'buy_price_cents, sell_price_cents, battery_health, trade_in_cents, '
      'created_at, updated_at, device_id) VALUES ('
      "'old-1', '老机器', 'Apple', '有划痕', 'sold', 1700000000, "
      "100000, 640000, 92, 550000, 0, 0, 'dev-old')",
    );
    legacy.execute('PRAGMA user_version = 5');
    legacy.dispose();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    final row = (await upgraded.select(upgraded.items).get()).single;
    expect(row.warrantyStatus, WarrantyStatus.none, reason: '旧行不能凭空变成在保');
    expect(row.warrantyStart, isNull);
    expect(row.warrantyEnd, isNull);

    // 升级不能动旧数据：同一个接口把旧字段逐个读回来对一遍，
    // 只看保修三列会漏掉「ADD COLUMN 把表重建了」这类事故。
    expect(row.title, '老机器');
    expect(row.brand, 'Apple');
    expect(row.note, '有划痕');
    expect(row.buyPriceCents, 100000);
    expect(row.sellPriceCents, 640000);
    expect(row.batteryHealth, 92);
    expect(row.tradeInCents, 550000);
    expect(row.deviceId, 'dev-old');

    // 列序必须与新建库一致（三列追加在最后），否则同步会判两端不兼容。
    final columns = await upgraded
        .customSelect('PRAGMA table_info(items)')
        .get();
    final names = columns.map((r) => r.data['name']! as String).toList();
    expect(
      names.sublist(names.length - 3),
      ['warranty_status', 'warranty_start', 'warranty_end'],
    );

    // 升级出来的表结构与全新建库逐字相同（含 NOT NULL 与 DEFAULT），
    // 否则两端 merge 时会因为列定义差异被判成不同库。
    final upgradedSql =
        (await upgraded
                .customSelect(
                  "SELECT sql FROM sqlite_master WHERE name = 'items'",
                )
                .getSingle())
            .data['sql']! as String;
    expect(upgradedSql, ddl);
  });

  test('升级中断后重跑：已加的列不重复报错，剩下的补上', () async {
    // drift 只在迁移跑完后才写 user_version，所以半路被杀会留下
    // 「列加了一部分、版本号还是 5」的库。重开时必须能继续跑完。
    final dir = await Directory.systemTemp.createTemp('ggjb_resume_');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // 删不掉不影响断言。
      }
    });
    final file = File('${dir.path}/half.sqlite');

    final ddl =
        (await db
                .customSelect(
                  "SELECT sql FROM sqlite_master WHERE name = 'items'",
                )
                .getSingle())
            .data['sql']! as String;

    final legacy = sqlite3.open(file.path);
    legacy.execute(ddl);
    // 只把三列里的第一列加回去，模拟「跑到第二个 addColumn 之前被kill」。
    legacy.execute('ALTER TABLE items DROP COLUMN warranty_start');
    legacy.execute('ALTER TABLE items DROP COLUMN warranty_end');
    legacy.execute('PRAGMA user_version = 5');
    legacy.dispose();

    final resumed = AppDatabase(NativeDatabase(file));
    addTearDown(resumed.close);

    final names = (await resumed.customSelect('PRAGMA table_info(items)').get())
        .map((r) => r.data['name']! as String)
        .toList();
    expect(
      names.sublist(names.length - 3),
      ['warranty_status', 'warranty_start', 'warranty_end'],
      reason: '重跑要把缺的两列补在末尾，不能重复加第一列',
    );
    // 结构又回到与新建库一致。
    final resumedSql =
        (await resumed
                .customSelect(
                  "SELECT sql FROM sqlite_master WHERE name = 'items'",
                )
                .getSingle())
            .data['sql']! as String;
    expect(resumedSql, ddl);
  });
}
