import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/domain/dict_seeds.dart';

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

  test('schemaVersion 是 5', () {
    expect(db.schemaVersion, 5);
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
}
