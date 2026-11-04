import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// 运营成本读写。
///
/// 这些钱摊不到某一单上（房租、包材、软件订阅），所以不进 `expenses`，
/// 看板用「总利润 − 运营成本」算净利，两者永远分开展示。
class OperatingDao {
  OperatingDao(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// 按日期区间取（半开区间 `[from, to)`）：`to` 当天 0 点不算在内。
  Stream<List<OperatingCost>> watch({DateTime? from, DateTime? to}) {
    final q = _db.select(_db.operatingCosts)
      ..where((t) => t.deletedAt.isNull());
    if (from != null) {
      q.where((t) => t.spentAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      q.where((t) => t.spentAt.isSmallerThanValue(to));
    }
    q.orderBy([
      (t) => OrderingTerm.desc(t.spentAt),
      (t) => OrderingTerm.desc(t.createdAt),
    ]);
    return q.watch();
  }

  /// 区间合计（分）。看板那一行小字用它。
  Stream<int> watchTotalCents({DateTime? from, DateTime? to}) {
    final sum = _db.operatingCosts.amountCents.sum();

    final q = _db.selectOnly(_db.operatingCosts)..addColumns([sum]);
    q.where(_db.operatingCosts.deletedAt.isNull());
    if (from != null) {
      q.where(_db.operatingCosts.spentAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      q.where(_db.operatingCosts.spentAt.isSmallerThanValue(to));
    }
    return q.watchSingle().map((row) {
      // 空集时 SUM 返回 NULL，不是 0。
      return row.read(sum) ?? 0;
    });
  }

  Future<String> insert({
    required DateTime spentAt,
    required String kind,
    required int amountCents,
    required String deviceId,
    String? note,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.operatingCosts).insert(
          OperatingCostsCompanion.insert(
            id: id,
            spentAt: spentAt,
            kind: kind,
            amountCents: amountCents,
            note: Value(note),
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
          ),
        );
    return id;
  }

  Future<void> update({
    required String id,
    required DateTime spentAt,
    required String kind,
    required int amountCents,
    String? note,
  }) async {
    await (_db.update(_db.operatingCosts)..where((t) => t.id.equals(id))).write(
      OperatingCostsCompanion(
        spentAt: Value(spentAt),
        kind: Value(kind),
        amountCents: Value(amountCents),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 软删除：物理删的话下次同步会被对端复活。
  Future<void> softDelete(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.operatingCosts)..where((t) => t.id.equals(id))).write(
      OperatingCostsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
