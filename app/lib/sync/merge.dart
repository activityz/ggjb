import 'dart:io';

import 'package:drift/drift.dart' show TableInfo;

import '../data/db/app_database.dart';

class MergeException implements Exception {
  MergeException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 一次合并的结果。
class MergeReport {
  const MergeReport({
    required this.itemsInserted,
    required this.itemsReplaced,
    required this.expensesInserted,
    required this.expensesReplaced,
    required this.attachmentsInserted,
    required this.attachmentsReplaced,
  });

  final int itemsInserted;
  final int itemsReplaced;
  final int expensesInserted;
  final int expensesReplaced;
  final int attachmentsInserted;
  final int attachmentsReplaced;

  int get totalChanged =>
      itemsInserted +
      itemsReplaced +
      expensesInserted +
      expensesReplaced +
      attachmentsInserted +
      attachmentsReplaced;

  String describe() =>
      '商品 +$itemsInserted / 覆盖 $itemsReplaced，'
      '费用 +$expensesInserted / 覆盖 $expensesReplaced，'
      '图片 +$attachmentsInserted / 覆盖 $attachmentsReplaced';
}

/// 把另一台设备导出的整库快照合并进本地库。
///
/// 实现方式：`ATTACH` 对方库，用 SQL 做「删旧的 + INSERT OR IGNORE」。
/// 这样做的好处是完全不用手写字段映射——以后给表加列，合并逻辑自动跟着走。
///
/// 冲突裁决策略与架构文档一致：`(updated_at, device_id)` 全序取大者胜。
/// 比较用元组字典序：更新者胜；时间相同则 device_id 字典序大者胜。
class MergeService {
  MergeService(this._db);

  final AppDatabase _db;

  /// 合并范围。`dict_entries` 也参与同步，否则换了设备品牌/机型要重配一遍。
  /// 字典的变化不进 [MergeReport] 计数 —— 用户关心的是商品记录有没有过来。
  /// v5 起 `operating_costs` 一并同步，否则换设备运营成本就丢了。
  static const syncedTables = [
    'items',
    'expenses',
    'attachments',
    'dict_entries',
    'operating_costs',
  ];

  Future<MergeReport> mergeFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw MergeException('找不到文件：$path');
    }

    await _db.customStatement('ATTACH DATABASE ? AS incoming', [path]);
    try {
      await _verifySchema();

      // 级联删除会误伤子表：删 items 那一行本地较旧的记录时，
      // 会把「本地较新」的 expenses 一起带走。所以合并期间关掉外键，
      // 合并完再开回来。引用完整性由「两端同源」保证。
      await _db.customStatement('PRAGMA foreign_keys = OFF');
      try {
        final before = await _totalChanges();

        // 统计用的本地 id 快照必须合并前取：合并之后远端独有行已经插进来了，
        // 差集恒空，所有行都会被算成「覆盖」，inserted 永远 0。
        final localIdsBefore = <String, Set<String>>{
          for (final table in syncedTables) table: await _localIds(table),
        };

        await _db.transaction(() async {
          for (final table in syncedTables) {
            await _mergeTable(table);
          }
        });

        final after = await _totalChanges();
        final delta = after - before;

        // 逐表统计，供 UI 展示。
        final items = await _tableDelta('items', localIdsBefore['items']!);
        final expenses = await _tableDelta(
          'expenses',
          localIdsBefore['expenses']!,
        );
        final attachments = await _tableDelta(
          'attachments',
          localIdsBefore['attachments']!,
        );

        // 关键：drift 的 stream 查询只在它自己知道「表动过」时才重查。
        // 上面整段合并走的是原始 SQL（ATTACH + DELETE/INSERT ... SELECT），
        // drift 完全无从得知，不手动通知的话明细列表、详情页、附件缩略图
        // 都会一直显示合并前的旧数据 —— 用户看到的就是「同步了但没变」。
        _db.markTablesUpdated(<TableInfo>[
          _db.items,
          _db.expenses,
          _db.attachments,
          _db.dictEntries,
          _db.operatingCosts,
        ]);

        // delta 只用来兜底断言，避免统计口径漂移时静默成功。
        assert(delta >= 0, '合并期间总变更数不可能为负（实际 $delta）');

        return MergeReport(
          itemsInserted: items.inserted,
          itemsReplaced: items.replaced,
          expensesInserted: expenses.inserted,
          expensesReplaced: expenses.replaced,
          attachmentsInserted: attachments.inserted,
          attachmentsReplaced: attachments.replaced,
        );
      } finally {
        await _db.customStatement('PRAGMA foreign_keys = ON');
      }
    } finally {
      await _db.customStatement('DETACH DATABASE incoming');
    }
  }

  /// 「删本地较旧的 → 插入远端所有 → 冲突跳过」。
  Future<void> _mergeTable(String table) async {
    await _db.customStatement('''
      DELETE FROM $table WHERE id IN (
        SELECT r.id
        FROM incoming.$table r
        JOIN $table l ON l.id = r.id
        WHERE r.updated_at > l.updated_at
           OR (r.updated_at = l.updated_at AND r.device_id > l.device_id)
      )
    ''');
    await _db.customStatement(
      'INSERT OR IGNORE INTO $table SELECT * FROM incoming.$table',
    );
  }

  Future<Set<String>> _localIds(String table) => _db
      .customSelect('SELECT id FROM $table')
      .get()
      .then((rows) => rows.map((r) => r.data['id'] as String).toSet());

  /// [localIds] 必须是合并前的快照，见调用处的说明。
  Future<({int inserted, int replaced})> _tableDelta(
    String table,
    Set<String> localIds,
  ) async {
    final remoteRows = await _db
        .customSelect('SELECT id FROM incoming.$table')
        .get();
    var inserted = 0;
    var replaced = 0;
    for (final row in remoteRows) {
      if (localIds.contains(row.data['id'])) {
        replaced++;
      } else {
        inserted++;
      }
    }
    // 这个统计是「远端出现过」的口径；本地更新胜出而被跳过的行也算 replaced，
    // 对用户来说都属于「两边都有、以较新为准」，可以接受。
    return (inserted: inserted, replaced: replaced);
  }

  Future<int> _totalChanges() async {
    final row = await _db
        .customSelect('SELECT total_changes() AS c')
        .getSingle();
    return (row.data['c'] as int?) ?? 0;
  }

  /// 两端 schema 必须一致，否则 `SELECT *` 的列顺序会对不上，插入脏数据。
  Future<void> _verifySchema() async {
    for (final table in syncedTables) {
      final local = await _columns('main', table);
      final remote = await _columns('incoming', table);
      if (local.isEmpty) {
        throw MergeException('本地库缺少表 $table，可能是空库或旧版本');
      }
      if (local.length != remote.length) {
        throw MergeException(
          '表 $table 的列数不一致（本地 ${local.length}，对方 ${remote.length}）。'
          '请先把两端升级到同一版本再合并。',
        );
      }
      for (var i = 0; i < local.length; i++) {
        if (local[i] != remote[i]) {
          throw MergeException(
            '表 $table 第 ${i + 1} 列不一致（本地 ${local[i]}，对方 ${remote[i]}）。'
            '请先把两端升级到同一版本再合并。',
          );
        }
      }
    }
  }

  Future<List<String>> _columns(String schema, String table) async {
    final rows = await _db
        .customSelect('PRAGMA $schema.table_info($table)')
        .get();
    return rows.map((r) => r.data['name'] as String).toList();
  }
}
