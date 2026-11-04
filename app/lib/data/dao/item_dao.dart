import 'package:drift/drift.dart';

import '../../domain/date_period.dart';
import '../../domain/enums.dart';
import '../../domain/profit.dart';
import '../db/app_database.dart';

/// 一件商品 + 它的全部未删除费用。
class ItemWithExpenses {
  const ItemWithExpenses({required this.item, required this.expenses});

  final Item item;
  final List<Expense> expenses;

  int get expenseCents => expenses.fold(0, (sum, e) => sum + e.amountCents);

  /// 换算成利润口径的输入。**利润只能由 [ProfitLine] 计算**。
  ProfitLine toProfitLine() => ProfitLine(
    itemId: item.id,
    status: item.status,
    buyPriceCents: item.buyPriceCents,
    expenseCents: expenseCents,
    sellPriceCents: item.sellPriceCents,
    tradeInCents: item.tradeInCents ?? 0,
  );
}

/// 列表页用的轻量行：不读 BLOB，只挑一张缩略图。
class ItemListRow {
  const ItemListRow({
    required this.item,
    required this.expenseCents,
    required this.thumb,
  });

  final Item item;
  final int expenseCents;
  final Uint8List? thumb;

  ProfitLine get profitLine => ProfitLine(
    itemId: item.id,
    status: item.status,
    buyPriceCents: item.buyPriceCents,
    expenseCents: expenseCents,
    sellPriceCents: item.sellPriceCents,
    tradeInCents: item.tradeInCents ?? 0,
  );
}

class ItemDao {
  ItemDao(this._db);

  final AppDatabase _db;

  /// 列表流：商品 + 费用合计 + 首图缩略图。
  ///
  /// 用 join 一次拿全，避免 N+1；费用按行展开后在这里聚合回商品。
  ///
  /// [dateField] / [range] 一起给才生效：只看其中一个是没意义的
  /// （「按卖出日期」得先说清是哪一段）。区间两端可以只给一头 ——
  /// 只填开始日就是「这天之后」，只填结束日就是「这天之前」。
  Stream<List<ItemListRow>> watchList({
    ItemStatus? status,
    Set<ItemStatus>? statuses,
    String? keyword,
    DateField? dateField,
    DateRange? range,
  }) {
    final query = _db.select(_db.items).join([
      leftOuterJoin(
        _db.expenses,
        _db.expenses.itemId.equalsExp(_db.items.id) &
            _db.expenses.deletedAt.isNull(),
      ),
    ]);

    query.where(_db.items.deletedAt.isNull());
    // 一组状态优先：看板的「已卖出」= sold + completed，「未卖」= inStock + listed；
    // 单状态留给列表页的状态 chip。
    if (statuses != null && statuses.isNotEmpty) {
      query.where(_db.items.status.isInValues(statuses.toList()));
    } else if (status != null) {
      query.where(_db.items.status.equalsValue(status));
    }
    final kw = keyword?.trim();
    if (kw != null && kw.isNotEmpty) {
      final like = '%$kw%';
      query.where(
        _db.items.title.like(like) |
            _db.items.brand.like(like) |
            _db.items.model.like(like) |
            _db.items.note.like(like),
      );
    }

    if (dateField != null) {
      // 半开区间 [start, endExclusive)：右端用小于是对的。
      // 写成 `<=` 且 to 取「下一天 0 点」，会把第二天 0:00:00 整的
      // 单子也算进今天。
      final from = range?.startInclusive;
      final to = range?.endExclusive;
      if (from != null || to != null) {
        switch (dateField) {
          case DateField.buy:
            if (from != null) {
              query.where(_db.items.buyDate.isBiggerOrEqualValue(from));
            }
            if (to != null) {
              query.where(_db.items.buyDate.isSmallerThanValue(to));
            }
          case DateField.sell:
            if (from != null) {
              query.where(_db.items.sellDate.isBiggerOrEqualValue(from));
            }
            if (to != null) {
              query.where(_db.items.sellDate.isSmallerThanValue(to));
            }
        }
      }
    }
    query.orderBy([
      OrderingTerm(expression: _db.items.updatedAt, mode: OrderingMode.desc),
    ]);

    return query.watch().asyncMap((rows) async {
      final expenses = <String, int>{};
      final items = <String, Item>{};
      final order = <String>[];
      for (final row in rows) {
        final item = row.readTable(_db.items);
        if (!items.containsKey(item.id)) {
          items[item.id] = item;
          order.add(item.id);
          expenses[item.id] = 0;
        }
        final expense = row.readTableOrNull(_db.expenses);
        if (expense != null) {
          expenses[item.id] = (expenses[item.id] ?? 0) + expense.amountCents;
        }
      }
      if (order.isEmpty) return const <ItemListRow>[];

      final thumbs = await _loadThumbs(order);

      return order
          .map(
            (id) => ItemListRow(
              item: items[id]!,
              expenseCents: expenses[id] ?? 0,
              thumb: thumbs[id],
            ),
          )
          .toList(growable: false);
    });
  }

  Future<Map<String, Uint8List?>> _loadThumbs(List<String> itemIds) async {
    if (itemIds.isEmpty) return const {};
    final query = _db.selectOnly(_db.attachments)
      ..addColumns([_db.attachments.itemId, _db.attachments.thumb])
      ..where(
        _db.attachments.itemId.isIn(itemIds) &
            _db.attachments.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm(expression: _db.attachments.createdAt)]);

    final result = <String, Uint8List?>{};
    final rows = await query.get();
    for (final row in rows) {
      final id = row.read(_db.attachments.itemId);
      if (id == null || result.containsKey(id)) continue;
      final thumb = row.read(_db.attachments.thumb);
      if (thumb != null) result[id] = thumb;
    }
    return result;
  }

  Future<ItemWithExpenses?> load(String id) async {
    final item = await (_db.select(
      _db.items,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    if (item == null) return null;
    final expenses =
        await (_db.select(_db.expenses)
              ..where((t) => t.itemId.equals(id) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
            .get();
    return ItemWithExpenses(item: item, expenses: expenses);
  }

  Future<List<Item>> allItems() =>
      (_db.select(_db.items)..where((t) => t.deletedAt.isNull())).get();

  Future<List<Expense>> allExpenses() =>
      (_db.select(_db.expenses)..where((t) => t.deletedAt.isNull())).get();

  /// 全量利润行（看板与导出用）。数据量在几千级，一次拉全再在内存聚合最省事。
  ///
  /// [dateField] / [range] 用来给看板做「按时间段」筛选：
  /// 过滤发生在 SQL（走 buy_date / sell_date 索引），
  /// 聚合口径仍然只有 [ProfitCalculator.aggregate] 一处。
  Future<List<ProfitLine>> allProfitLines({
    DateField? dateField,
    DateRange? range,
  }) async {
    final q = _db.select(_db.items)..where((t) => t.deletedAt.isNull());
    if (dateField != null) {
      final from = range?.startInclusive;
      final to = range?.endExclusive;
      switch (dateField) {
        case DateField.buy:
          if (from != null) {
            q.where((t) => t.buyDate.isBiggerOrEqualValue(from));
          }
          if (to != null) {
            q.where((t) => t.buyDate.isSmallerThanValue(to));
          }
        case DateField.sell:
          if (from != null) {
            q.where((t) => t.sellDate.isBiggerOrEqualValue(from));
          }
          if (to != null) {
            q.where((t) => t.sellDate.isSmallerThanValue(to));
          }
      }
    }

    final items = await q.get();
    final expenses = await allExpenses();
    final byItem = <String, int>{};
    for (final e in expenses) {
      byItem[e.itemId] = (byItem[e.itemId] ?? 0) + e.amountCents;
    }
    return items
        .map(
          (item) => ProfitLine(
            itemId: item.id,
            status: item.status,
            buyPriceCents: item.buyPriceCents,
            expenseCents: byItem[item.id] ?? 0,
            sellPriceCents: item.sellPriceCents,
            tradeInCents: item.tradeInCents ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<Item?> findById(String id) =>
      (_db.select(_db.items)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertItem(ItemsCompanion companion) =>
      _db.into(_db.items).insert(companion);

  Future<void> updateItem(ItemsCompanion companion) => (_db.update(
    _db.items,
  )..where((t) => t.id.equals(companion.id.value))).write(companion);

  /// 软删除：物理删除会被对端同步复活，因此只写墓碑。
  Future<void> softDeleteItem(String id, {required DateTime now}) async {
    await (_db.update(_db.items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await (_db.update(_db.expenses)..where((t) => t.itemId.equals(id))).write(
      ExpensesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await (_db.update(
      _db.attachments,
    )..where((t) => t.itemId.equals(id))).write(
      AttachmentsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<void> insertExpense(ExpensesCompanion companion) =>
      _db.into(_db.expenses).insert(companion);

  Future<void> softDeleteExpense(String id, {required DateTime now}) =>
      (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
        ExpensesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );

  /// 写入或覆盖一条费用（编辑时整条替换）。
  Future<void> upsertExpense(ExpensesCompanion companion) =>
      _db.into(_db.expenses).insertOnConflictUpdate(companion);
}
