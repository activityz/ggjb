import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// 字典读写。
///
/// 字典只是「选项池」：商品表里存的是选中那一刻的文本快照
/// （`items.brand` / `items.model` / `items.storage` / `items.color` 都是 TEXT），
/// 所以字典改名不会回写历史记录 —— 这是有意的，老单子该保留当时的写法。
class DictDao {
  DictDao(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  List<OrderingTerm Function($DictEntriesTable)> get _order => [
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.label),
      ];

  /// 监听某一类字典项；[parentId] 非空时只看挂在它下面的（机型的品牌过滤）。
  Stream<List<DictEntry>> watchKind(String kind, {String? parentId}) {
    final q = _db.select(_db.dictEntries)
      ..where((t) => t.kind.equals(kind) & t.deletedAt.isNull());
    if (parentId != null) {
      q.where((t) => t.parentId.equals(parentId));
    }
    q.orderBy(_order);
    return q.watch();
  }

  Future<List<DictEntry>> allOfKind(String kind, {String? parentId}) {
    final q = _db.select(_db.dictEntries)
      ..where((t) => t.kind.equals(kind) & t.deletedAt.isNull());
    if (parentId != null) {
      q.where((t) => t.parentId.equals(parentId));
    }
    q.orderBy(_order);
    return q.get();
  }

  /// 按「父项 label」过滤。
  ///
  /// 商品表存的是品牌文本快照（`items.brand`），编辑页手里没有品牌的字典 id，
  /// 所以机型过滤只能拿 label 反查父项 id。父项被改名后子项就挂不住了 ——
  /// 这是已知取舍：宁可漏过滤，也不在商品表里存字典外键。
  Stream<List<DictEntry>> watchKindUnderLabel(
    String kind, {
    required String parentKind,
    required String parentLabel,
  }) {
    final parentIds = _db.selectOnly(_db.dictEntries)
      ..addColumns([_db.dictEntries.id])
      ..where(_db.dictEntries.kind.equals(parentKind) &
          _db.dictEntries.deletedAt.isNull() &
          _db.dictEntries.label.equals(parentLabel));
    final q = _db.select(_db.dictEntries)
      ..where((t) =>
          t.kind.equals(kind) &
          t.deletedAt.isNull() &
          t.parentId.isInQuery(parentIds));
    q.orderBy(_order);
    return q.watch();
  }

  /// 按 label 反查字典项 id（新增子项时要拿父项 id）。
  Future<String?> idOfLabel(String kind, String label) async {
    final q = _db.select(_db.dictEntries)
      ..where((t) =>
          t.kind.equals(kind) &
          t.deletedAt.isNull() &
          t.label.equals(label))
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row?.id;
  }

  /// 全部未删除的字典项，一次性取回（同步与字典管理页用）。
  Future<List<DictEntry>> all() {
    final q = _db.select(_db.dictEntries)
      ..where((t) => t.deletedAt.isNull());
    q.orderBy([
      (t) => OrderingTerm.asc(t.kind),
      (t) => OrderingTerm.asc(t.sortOrder),
      (t) => OrderingTerm.asc(t.label),
    ]);
    return q.get();
  }

  /// 全量字典的实时流，字典管理页用。
  Stream<List<DictEntry>> watchAll() {
    final q = _db.select(_db.dictEntries)
      ..where((t) => t.deletedAt.isNull());
    q.orderBy([
      (t) => OrderingTerm.asc(t.kind),
      (t) => OrderingTerm.asc(t.sortOrder),
      (t) => OrderingTerm.asc(t.label),
    ]);
    return q.watch();
  }

  /// 新增一条。同名同父已存在时直接复用，避免刷出一堆重复项。
  Future<String> insert({
    required String kind,
    required String label,
    required String deviceId,
    String? parentId,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('字典名称不能为空');
    }
    final existing = await allOfKind(kind, parentId: parentId);
    for (final e in existing) {
      if (e.label == trimmed) return e.id;
    }
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.dictEntries).insert(
          DictEntriesCompanion.insert(
            id: id,
            kind: kind,
            label: trimmed,
            parentId: Value(parentId),
            sortOrder: Value(existing.length),
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
          ),
        );
    return id;
  }

  Future<void> rename(String id, String label, {required DateTime now}) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('字典名称不能为空');
    }
    await (_db.update(_db.dictEntries)..where((t) => t.id.equals(id))).write(
      DictEntriesCompanion(
        label: Value(trimmed),
        updatedAt: Value(now),
      ),
    );
  }

  /// 软删除。写墓碑而不是物理删，否则同步时会被对端复活。
  Future<void> softDelete(String id, {required DateTime now}) async {
    await (_db.update(_db.dictEntries)..where((t) => t.id.equals(id))).write(
      DictEntriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
