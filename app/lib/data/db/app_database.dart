import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/dict_seeds.dart';
import '../../domain/enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// 全库唯一数据库入口。
///
/// 纪律：
/// - 整个 App 只持有一个 [AppDatabase] 实例（由 Riverpod 提供）。
/// - 写入一律走 [transaction]，SQLite 单写者模型下并发写会 SQLITE_BUSY。
/// - 任何金额字段都是「分」，不要在 DAO 层做除法。
@DriftDatabase(
  tables: [
    Items,
    Expenses,
    Attachments,
    SyncStates,
    LocalDevices,
    DictEntries,
    OperatingCosts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'ggjb'));

  /// 版本历史：
  /// - v1 首版
  /// - v2 新增 `dict_entries` 字典表；`items` 增加 `storage` / `color`
  /// - v3 `sync_states` 增加配对凭证/地址/水位/自动同步四列；
  ///   `local_devices` 增加 `theme_mode`
  /// - v4 `items` 增加 `battery_health`（电池健康）、`list_price_cents`
  ///   （置换挂牌价）、`trade_in_cents`（旧机抵扣）；补 `buy_date` /
  ///   `sell_date` 索引供日期筛选与按月统计
  /// - v5 新增 `operating_costs`（摊不到单件的运营成本）；字典增加
  ///   `operating` 类别，并把「采货侠」「拍机堂」补进买入来源最前
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
          await _seedDicts();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(dictEntries);
            await m.addColumn(items, items.storage);
            await m.addColumn(items, items.color);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_dict_kind ON dict_entries(kind)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_dict_parent ON dict_entries(parent_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_dict_updated_at ON dict_entries(updated_at)',
            );
            await _seedDicts();
          }
          if (from < 3) {
            await m.addColumn(syncStates, syncStates.peerToken);
            await m.addColumn(syncStates, syncStates.peerHost);
            await m.addColumn(syncStates, syncStates.peerPort);
            await m.addColumn(syncStates, syncStates.lastSyncAt);
            await m.addColumn(syncStates, syncStates.autoSync);
            await m.addColumn(localDevices, localDevices.themeMode);
          }
          if (from < 4) {
            // 三列全部 nullable，旧行升级后是 NULL = 「没填」，
            // 不需要也不应该做任何猜测性回填。
            await m.addColumn(items, items.batteryHealth);
            await m.addColumn(items, items.listPriceCents);
            await m.addColumn(items, items.tradeInCents);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_items_buy_date ON items(buy_date)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_items_sell_date ON items(sell_date)',
            );
          }
          if (from < 5) {
            await m.createTable(operatingCosts);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_operating_spent_at ON operating_costs(spent_at)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_operating_updated_at ON operating_costs(updated_at)',
            );
            // 不重跑 _seedDicts：那会把用户自己排过的顺序按常量顺序重写
            // （insertOrIgnore 不更新已有行，但新项会按常量序号插进来，混在一起就乱了）。
            // 这里只补「新版本才有的项」。
            await _seedV5Extras();
          }
        },
        beforeOpen: (details) async {
          // SQLite 默认不校验外键，必须每个连接显式打开。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    // 同步按 updated_at 增量拉取，必须有索引。
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_items_updated_at ON items(updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_items_status ON items(status)',
    );
    // 日期筛选与按月销量都按这两列走区间扫描。
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_items_buy_date ON items(buy_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_items_sell_date ON items(sell_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_expenses_item_id ON expenses(item_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_expenses_updated_at ON expenses(updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attachments_item_id ON attachments(item_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attachments_updated_at ON attachments(updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_dict_kind ON dict_entries(kind)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_dict_parent ON dict_entries(parent_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_dict_updated_at ON dict_entries(updated_at)',
    );
    // 运营成本按日期筛（看板）与按 updated_at 增量同步。
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_operating_spent_at ON operating_costs(spent_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_operating_updated_at ON operating_costs(updated_at)',
    );
  }

  /// v5 增量补种：老库升级时只补「这一版才有的字典项」。
  ///
  /// 采货侠/拍机堂用负数排序号，直接排到来源列表最前，
  /// 又不会把用户已经调好的其他顺序整体推后。
  Future<void> _seedV5Extras() async {
    final now = DateTime.now();
    final rows = <DictEntriesCompanion>[];

    DictEntriesCompanion row({
      required String id,
      required String kind,
      required String label,
      required int sortOrder,
    }) {
      return DictEntriesCompanion.insert(
        id: id,
        kind: kind,
        label: label,
        sortOrder: Value(sortOrder),
        builtIn: const Value(1),
        createdAt: now,
        updatedAt: now,
        deviceId: 'seed',
      );
    }

    var index = 0;
    for (final label in DictSeeds.operating) {
      rows.add(
        row(
          id: 'seed|${DictSeeds.kindOperating}|$label',
          kind: DictSeeds.kindOperating,
          label: label,
          sortOrder: index++,
        ),
      );
    }

    var sourceRank = -2;
    for (final label in const ['采货侠', '拍机堂']) {
      rows.add(
        row(
          id: 'seed|${DictSeeds.kindSource}|$label',
          kind: DictSeeds.kindSource,
          label: label,
          sortOrder: sourceRank++,
        ),
      );
    }

    await batch(
      (b) => b.insertAll(
        dictEntries,
        rows,
        mode: InsertMode.insertOrIgnore,
      ),
    );
  }

  /// 内置字典灌入。
  ///
  /// id 用确定性字符串（`seed|brand|Apple`、`seed|model|Apple|iPhone 13`），
  /// 保证两台设备各自 seed 出来的行 id 相同 —— 同步合并时命中同一行，
  /// 不会把 15 个品牌变成 30 个。用 `insertOrIgnore` 保护重复执行。
  Future<void> _seedDicts() async {
    final now = DateTime.now();
    final rows = <DictEntriesCompanion>[];

    DictEntriesCompanion row({
      required String id,
      required String kind,
      required String label,
      String? parentId,
      required int sortOrder,
    }) {
      return DictEntriesCompanion.insert(
        id: id,
        kind: kind,
        label: label,
        parentId: Value(parentId),
        sortOrder: Value(sortOrder),
        builtIn: const Value(1),
        createdAt: now,
        updatedAt: now,
        deviceId: 'seed',
      );
    }

    // 品牌 + 机型
    var brandIndex = 0;
    for (final entry in DictSeeds.brandModels.entries) {
      final brandId = 'seed|brand|${entry.key}';
      rows.add(
        row(
          id: brandId,
          kind: DictSeeds.kindBrand,
          label: entry.key,
          sortOrder: brandIndex,
        ),
      );
      var modelIndex = 0;
      for (final model in entry.value) {
        rows.add(
          row(
            id: 'seed|model|${entry.key}|$model',
            kind: DictSeeds.kindModel,
            label: model,
            parentId: brandId,
            sortOrder: modelIndex,
          ),
        );
        modelIndex++;
      }
      brandIndex++;
    }

    // 无层级的 6 类：内存规格 / 颜色 / 分类 / 买入来源 / 卖出渠道 / 成色。
    // 统一遍历 DictSeeds.flatKinds，加新类别不用动这里。
    for (final group in DictSeeds.flatKinds) {
      var index = 0;
      for (final label in group.items) {
        rows.add(
          row(
            id: 'seed|${group.kind}|$label',
            kind: group.kind,
            label: label,
            sortOrder: index,
          ),
        );
        index++;
      }
    }

    await batch((b) {
      b.insertAll(dictEntries, rows, mode: InsertMode.insertOrIgnore);
    });
  }

  /// 整库快照（导出用）。SQLite 官方推荐方式，比复制文件安全。
  Future<void> vacuumInto(String absolutePath) async {
    await customStatement('VACUUM INTO ?', [absolutePath]);
  }

  /// 当前库文件路径。drift_flutter 的默认路径是内部实现细节，
  /// 唯一可靠的取法是问 SQLite 自己。
  Future<String?> currentFilePath() async {
    final rows = await customSelect('PRAGMA database_list').get();
    for (final row in rows) {
      if (row.data['name'] == 'main') {
        final file = row.data['file'];
        if (file is String && file.isNotEmpty) return file;
      }
    }
    return null;
  }
}
