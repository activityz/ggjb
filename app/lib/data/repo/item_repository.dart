import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/date_period.dart';
import '../../domain/enums.dart';
import '../../domain/profit.dart';
import '../dao/attachment_dao.dart';
import '../dao/item_dao.dart';
import '../db/app_database.dart';

/// 编辑页提交上来的商品草稿。
///
/// [id] 为 null 表示新建；不为 null 表示编辑已有记录。
class ItemDraft {
  const ItemDraft({
    this.id,
    required this.title,
    this.category,
    this.brand,
    this.model,
    this.storage,
    this.color,
    this.conditionBought,
    this.conditionSold,
    required this.status,
    this.sourcePlatform,
    this.buyDate,
    required this.buyPriceCents,
    this.sellDate,
    this.sellPriceCents,
    this.sellPlatform,
    this.lotId,
    this.note,
    this.batteryHealth,
    this.listPriceCents,
    this.tradeInCents,
  });

  final String? id;
  final String title;
  final String? category;
  final String? brand;
  final String? model;

  /// 内存规格（如 `12+256`），来自字典 `storage`。
  final String? storage;

  /// 颜色，来自字典 `color`。
  final String? color;
  final String? conditionBought;
  final String? conditionSold;
  final ItemStatus status;
  final String? sourcePlatform;
  final DateTime? buyDate;
  final int buyPriceCents;
  final DateTime? sellDate;
  final int? sellPriceCents;
  final String? sellPlatform;
  final String? lotId;
  final String? note;

  /// 电池健康百分比（0–100）。null = 没填。
  final int? batteryHealth;

  /// 置换挂牌价（分）。普通交易为 null。
  final int? listPriceCents;

  /// 置换时旧机抵扣额（分）。只记录，不参与利润。
  final int? tradeInCents;
}

/// 草稿里的一条费用。
class ExpenseDraft {
  const ExpenseDraft({
    this.id,
    required this.kind,
    required this.side,
    required this.amountCents,
    this.incurredAt,
    this.note,
  });

  final String? id;
  final ExpenseKind kind;
  final ExpenseSide side;
  final int amountCents;
  final DateTime? incurredAt;
  final String? note;
}

/// 业务写入口。所有写操作在这里统一补 `updatedAt` / `deviceId` 等同步字段，
/// UI 层不允许自己拼 Companion。
class ItemRepository {
  ItemRepository({
    required AppDatabase db,
    required ItemDao itemDao,
    required AttachmentDao attachmentDao,
    required String deviceId,
    Uuid uuid = const Uuid(),
  }) : _db = db,
       _items = itemDao,
       _attachments = attachmentDao,
       _deviceId = deviceId,
       _uuid = uuid;

  final AppDatabase _db;
  final ItemDao _items;
  final AttachmentDao _attachments;
  final String _deviceId;
  final Uuid _uuid;

  Stream<List<ItemListRow>> watchList({
    ItemStatus? status,
    Set<ItemStatus>? statuses,
    String? keyword,
    DateField? dateField,
    DateRange? range,
  }) => _items.watchList(
    status: status,
    statuses: statuses,
    keyword: keyword,
    dateField: dateField,
    range: range,
  );

  Future<ItemWithExpenses?> load(String id) => _items.load(id);

  Future<List<AttachmentMeta>> attachmentsOf(String itemId) =>
      _attachments.listMeta(itemId);

  /// 利润汇总，供看板使用。
  ///
  /// 不给参数就是全库口径（默认为「全部时间」）；
  /// 给了 [dateField] / [range] 就只算筛选范围内的单子。
  Future<ProfitAggregate> aggregate({
    DateField? dateField,
    DateRange? range,
  }) async {
    final lines = await _items.allProfitLines(
      dateField: dateField,
      range: range,
    );
    return ProfitCalculator.aggregate(lines);
  }

  /// 保存商品 + 其费用。整套操作在一个事务里，失败则全部回滚。
  Future<String> save(ItemDraft draft, List<ExpenseDraft> expenses) async {
    final now = DateTime.now();
    final id = draft.id ?? _uuid.v4();

    await _db.transaction(() async {
      final companion = ItemsCompanion(
        id: Value(id),
        title: Value(draft.title),
        category: Value(draft.category),
        brand: Value(draft.brand),
        model: Value(draft.model),
        storage: Value(draft.storage),
        color: Value(draft.color),
        conditionBought: Value(draft.conditionBought),
        conditionSold: Value(draft.conditionSold),
        status: Value(draft.status),
        sourcePlatform: Value(draft.sourcePlatform),
        buyDate: Value(draft.buyDate),
        buyPriceCents: Value(draft.buyPriceCents),
        sellDate: Value(draft.sellDate),
        sellPriceCents: Value(draft.sellPriceCents),
        sellPlatform: Value(draft.sellPlatform),
        lotId: Value(draft.lotId),
        note: Value(draft.note),
        batteryHealth: Value(draft.batteryHealth),
        listPriceCents: Value(draft.listPriceCents),
        tradeInCents: Value(draft.tradeInCents),
        createdAt: Value(now),
        updatedAt: Value(now),
        deviceId: Value(_deviceId),
      );

      // id 非空不等于「编辑」：导表时 parse 会给新行分配 uuid，编辑页也可能
      // 带着一个已被清空的 id 进来。只认 draft.id 会把它们全当成编辑，
      // update 0 行后仍然报成功，用户看到「已写入 1 件」但列表里空空如也。
      final existing = draft.id == null ? null : await _items.findById(id);
      if (existing == null) {
        await _items.insertItem(companion);
      } else {
        // 编辑不覆盖 createdAt / deviceId（deviceId 记录最初创建者）。
        //
        // deletedAt 必须显式清空：导入一份「自己导出过的表」时，id 往往
        // 正好命中本地已软删的行。只 update 不清墓碑，数据确实写进了库，
        // 但列表按 deleted_at 过滤，用户看到「已写入 N 件」却什么都没有——
        // 这就是「导入提示成功、实际没导入」的来源。
        await (_db.update(_db.items)..where((t) => t.id.equals(id))).write(
          companion.copyWith(
            createdAt: const Value.absent(),
            deviceId: const Value.absent(),
            deletedAt: const Value(null),
          ),
        );
      }

      // 费用按「全量替换」处理。
      //
      // 这里踩过一个坑：原来是「先把该商品的费用全部打墓碑，再用原 id 插新行」，
      // 结果编辑一笔已有费用时直接炸
      // `UNIQUE constraint failed: expenses.id` —— 墓碑只是把 deleted_at 写上，
      // 行还在，主键自然被占着。
      //
      // 正确做法是分开两种情况：
      // - 这次不在列表里的旧行 → 打墓碑（保留墓碑给对端同步，否则对端会复活）
      // - 这次在列表里的行 → 有 id 就「复活 + 覆盖」，没 id 才插新行
      final keepIds = <String>{
        for (final e in expenses)
          if (e.id != null) e.id!,
      };

      final stale = _db.update(_db.expenses)..where((t) => t.itemId.equals(id));
      // 空集合不能直接塞进 `isNotIn`（会生成 `NOT IN ()` 这种非法 SQL），
      // 所以有保留项时才追加这个条件。
      if (keepIds.isNotEmpty) {
        stale.where((t) => t.id.isNotIn(keepIds));
      }
      await stale.write(
        ExpensesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );

      for (final e in expenses) {
        final expenseId = e.id ?? _uuid.v4();
        final exists = await (_db.select(
          _db.expenses,
        )..where((t) => t.id.equals(expenseId))).getSingleOrNull();

        if (exists == null) {
          await _items.insertExpense(
            ExpensesCompanion(
              id: Value(expenseId),
              itemId: Value(id),
              kind: Value(e.kind),
              side: Value(e.side),
              amountCents: Value(e.amountCents),
              incurredAt: Value(e.incurredAt),
              note: Value(e.note),
              createdAt: Value(now),
              updatedAt: Value(now),
              deviceId: Value(_deviceId),
            ),
          );
        } else {
          // 复活已存在的行：deleted_at 清空，其余按当前表单覆盖。
          // createdAt / deviceId 属于「谁在什么时候建的」，编辑不覆盖。
          await (_db.update(
            _db.expenses,
          )..where((t) => t.id.equals(expenseId))).write(
            ExpensesCompanion(
              itemId: Value(id),
              kind: Value(e.kind),
              side: Value(e.side),
              amountCents: Value(e.amountCents),
              incurredAt: Value(e.incurredAt),
              note: Value(e.note),
              deletedAt: const Value(null),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });

    return id;
  }

  /// 标记为已售出。
  ///
  /// [listPriceCents] / [tradeInCents] 是置换留痕（挂牌价、旧机抵扣），
  /// **不参与利润**：旧机的价值要等它作为新商品再卖出去才结算，
  /// 现在就在这一单里扣，同一台机器会被算两次。
  Future<void> markSold(
    String itemId, {
    required int sellPriceCents,
    DateTime? sellDate,
    String? sellPlatform,
    String? conditionSold,
    int? listPriceCents,
    int? tradeInCents,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(
      ItemsCompanion(
        status: const Value(ItemStatus.sold),
        sellPriceCents: Value(sellPriceCents),
        sellDate: Value(sellDate ?? now),
        sellPlatform: Value(sellPlatform),
        conditionSold: Value(conditionSold),
        listPriceCents: Value(listPriceCents),
        tradeInCents: Value(tradeInCents),
        updatedAt: Value(now),
      ),
    );
  }

  /// 标记货款已到账。
  ///
  /// 与 [markSold] 的差别只在状态：卖出价、卖出日期、渠道都原样保留，
  /// 唯一的变化是这单不再计入「待收货款」。
  Future<void> markCompleted(String itemId) async {
    final now = DateTime.now();
    await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(
      ItemsCompanion(
        status: const Value(ItemStatus.completed),
        updatedAt: Value(now),
      ),
    );
  }

  /// 从「已到账」退回「已卖出」：钱其实没到，或者点错了。
  Future<void> unmarkCompleted(String itemId) async {
    final now = DateTime.now();
    await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(
      ItemsCompanion(
        status: const Value(ItemStatus.sold),
        updatedAt: Value(now),
      ),
    );
  }

  /// 退货：清空卖出价与卖出日期，状态置为 returned（卖出侧费用保留，计入亏损）。
  Future<void> markReturned(String itemId) async {
    final now = DateTime.now();
    await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(
      ItemsCompanion(
        status: const Value(ItemStatus.returned),
        sellPriceCents: const Value(null),
        sellDate: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// 标记为已上架（挂出去卖，但还没卖掉）。仍在途，算资金占用不算利润。
  Future<void> markListed(String itemId) async {
    final now = DateTime.now();
    await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(
      ItemsCompanion(
        status: const Value(ItemStatus.listed),
        updatedAt: Value(now),
      ),
    );
  }

  /// 报废。
  Future<void> markScrapped(String itemId) async {
    final now = DateTime.now();
    await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(
      ItemsCompanion(
        status: const Value(ItemStatus.scrapped),
        sellPriceCents: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// 重新上架（退货后再卖、报废后悔了都走这里）。
  Future<void> backToStock(String itemId) async {
    final now = DateTime.now();
    await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(
      ItemsCompanion(
        status: const Value(ItemStatus.inStock),
        sellPriceCents: const Value(null),
        sellDate: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> delete(String itemId) =>
      _items.softDeleteItem(itemId, now: DateTime.now());

  /// 保存一张已处理好的图片。
  Future<String> addImage({
    required String itemId,
    required AttachmentRole role,
    required List<int> bytes,
    required List<int> thumb,
    required int width,
    required int height,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _attachments.insert(
      AttachmentsCompanion(
        id: Value(id),
        itemId: Value(itemId),
        role: Value(role),
        mime: const Value('image/jpeg'),
        bytes: Value(Uint8List.fromList(bytes)),
        thumb: Value(Uint8List.fromList(thumb)),
        width: Value(width),
        height: Value(height),
        sizeBytes: Value(bytes.length),
        createdAt: Value(now),
        updatedAt: Value(now),
        deviceId: Value(_deviceId),
      ),
    );
    return id;
  }

  Future<void> deleteImage(String id) =>
      _attachments.softDelete(id, now: DateTime.now());

  Future<Uint8List?> fullImage(String attachmentId) =>
      _attachments.bytesOf(attachmentId);

  Future<Uint8List?> thumbImage(String attachmentId) =>
      _attachments.thumbOf(attachmentId);
}
