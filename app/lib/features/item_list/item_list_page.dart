import '../barcode/qr_dialog.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/dao/item_dao.dart';
import '../../domain/date_period.dart';
import '../../domain/enums.dart';
import '../../domain/money.dart';
import '../../ui/glass_card.dart';
import '../../ui/particles.dart';
import '../../ui/shimmer.dart';
import '../item_detail/item_detail_page.dart';
import '../item_edit/item_edit_page.dart';

/// 明细列表：搜索 + 状态筛选 + 单件盈亏。
class ItemListPage extends ConsumerStatefulWidget {
  const ItemListPage({super.key, this.initialFilter});

  /// 从看板点卡片进来时带上的筛选。null = 空白筛选（底部 tab 里的默认页）。
  final ItemFilter? initialFilter;

  @override
  ConsumerState<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends ConsumerState<ItemListPage> {
  final _searchController = TextEditingController();
  String _keyword = '';
  bool _burst = false;

  /// 当前状态筛选；空集 = 全部。
  ///
  /// 用集合而不是单值：看板上的「已卖出」「未卖」各对应两个状态
  /// （已卖出 + 已到账 / 在库 + 挂出），点进来必须能一次看全。
  Set<ItemStatus> _statuses = const <ItemStatus>{};

  /// 日期筛选：字段（买入 / 卖出）+ 自定义区间。
  ///
  /// 区间两端都可以只填一头，全空就是不筛。`_dateField` 单独为 null 时
  /// 也不筛 —— 两个必须成对，见 `ItemFilter.hasDateFilter`。
  DateField? _dateField;
  DateRange _range = DateRange.all;

  /// 入场动效只播一次。
  ///
  /// 列表是 drift 的实时流，同步一次就会重建一遍。如果每次都 fadeIn + slideY，
  /// 用户正盯着列表看，另一台设备改了个价，整屏条目就会重新「浮现」一次 ——
  /// 看起来像页面在刷新，其实是数据在流动。只在第一次进来时播，之后静默替换。
  bool _introPlayed = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialFilter;
    if (init != null) {
      _statuses = init.statuses?.isNotEmpty == true
          ? init.statuses!
          : (init.status != null ? {init.status!} : const <ItemStatus>{});
      _keyword = init.keyword;
      _dateField = init.dateField;
      _range = init.range;
      if (init.keyword.isNotEmpty) _searchController.text = init.keyword;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _introPlayed = true);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    ref.invalidate(profitSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ItemFilter(
      statuses: _statuses,
      keyword: _keyword,
      dateField: _dateField,
      range: _range,
    );
    final async = ref.watch(itemListProvider(filter));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: context.palette.pageGradient),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜标题 / 品牌 / 型号 / 备注',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _keyword.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _keyword = '');
                                },
                              ),
                      ),
                      onChanged: (v) => setState(() => _keyword = v.trim()),
                    ),
                  ),
                  _FilterRow(
                    field: _dateField,
                    range: _range,
                    onPickDate: _pickDateFilter,
                    onClearDate: () => setState(() {
                      _dateField = null;
                      _range = DateRange.all;
                    }),
                  ),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: [
                        // 多状态组合（看板点进来）没有对应的单值 chip，
                        // 单独给一颗可删的标签，点 × 回到「全部」。
                        if (_statuses.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(
                                _statuses.map((s) => s.label).join(' + '),
                              ),
                              onDeleted: () => setState(
                                () => _statuses = const <ItemStatus>{},
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                            ),
                          ),
                        _statusChip(null, '全部'),
                        for (final s in ItemStatus.values)
                          _statusChip(s, s.label),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: async.when(
                      loading: () => const ItemListSkeleton(),
                      error: (err, _) => Center(child: Text('读取失败：$err')),
                      data: (rows) {
                        if (rows.isEmpty) {
                          return _EmptyList(
                            hasFilter:
                                _statuses.isNotEmpty ||
                                _keyword.isNotEmpty ||
                                (_dateField != null && !_range.isEmpty),
                          );
                        }
                        return RefreshIndicator(
                          color: context.palette.accent,
                          backgroundColor: const Color(0xFF1A212B),
                          displacement: 32,
                          onRefresh: _onRefresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final tile = _ItemTile(
                                row: rows[i],
                                onTap: () =>
                                    _openDetail(context, rows[i].item.id),
                                onDelete: () => _confirmDelete(rows[i]),
                              );
                              if (_introPlayed) return tile;
                              return tile
                                  .animate()
                                  .fadeIn(
                                    duration: 380.ms,
                                    delay: (i.clamp(0, 8) * 45).ms,
                                    curve: Curves.easeOut,
                                  )
                                  .slideY(
                                    begin: 0.10,
                                    duration: 440.ms,
                                    delay: (i.clamp(0, 8) * 45).ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_burst)
            Positioned.fill(
              child: IgnorePointer(
                child: ParticleBurst(color: context.palette.accent),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }

  /// 下拉刷新：数据本身是流、已经实时，这里刷的是「重算一遍再炸一下」。
  /// 真要它有用，是靠 invalidate 把 summary / 分组统计也一起重取。
  Future<void> _onRefresh() async {
    final filter = ItemFilter(
      statuses: _statuses,
      keyword: _keyword,
      dateField: _dateField,
      range: _range,
    );
    ref.invalidate(itemListProvider(filter));
    ref.invalidate(profitSummaryProvider);
    if (mounted) setState(() => _burst = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _burst = false);
  }

  /// 选「按哪一天筛」+ 一段时间。
  ///
  /// 分两段而不是一个弹窗塞完：日历一旦展开就盖住整屏，快捷入口和一整年的
  /// 滚动条会互相挤。常用区间给一排快捷入口，剩下的交给系统日期区间选择器。
  Future<void> _pickDateFilter() async {
    var field = _dateField ?? DateField.sell;
    final now = DateTime.now();

    final picked =
        await showModalBottomSheet<({DateField field, DateRange? range})>(
          context: context,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setLocal) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '按哪一天筛？',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '先定用哪个日期，再选一段时间。选完还能改。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final f in DateField.values)
                          ChoiceChip(
                            label: Text(f.label),
                            selected: field == f,
                            onSelected: (_) => setLocal(() => field = f),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '时间段',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('本月'),
                          onPressed: () => Navigator.of(ctx).pop((
                            field: field,
                            range: DateRange.thisMonth(now),
                          )),
                        ),
                        ActionChip(
                          label: const Text('上月'),
                          onPressed: () => Navigator.of(ctx).pop((
                            field: field,
                            range: DateRange.lastMonth(now),
                          )),
                        ),
                        ActionChip(
                          label: const Text('最近 7 天'),
                          onPressed: () => Navigator.of(ctx).pop((
                            field: field,
                            range: DateRange.lastDays(now, 7),
                          )),
                        ),
                        ActionChip(
                          label: const Text('今年'),
                          onPressed: () => Navigator.of(
                            ctx,
                          ).pop((field: field, range: DateRange.thisYear(now))),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: const Text('自定义…'),
                          onPressed: () => Navigator.of(
                            ctx,
                          ).pop((field: field, range: null)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    if (picked == null || !mounted) return;

    final DateRange applied;
    if (picked.range != null) {
      applied = picked.range!;
    } else {
      final start = _range.from ?? now;
      final end = _range.to ?? now;
      final initial = end.isBefore(start)
          ? null
          : DateTimeRange(start: start, end: end);
      final custom = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: initial,
        helpText: '选一段时间（含首尾两天）',
        saveText: '就这段',
      );
      if (custom == null || !mounted) return;
      applied = DateRange(from: custom.start, to: custom.end);
    }

    setState(() {
      _dateField = picked.field;
      _range = applied;
    });
  }

  Widget _statusChip(ItemStatus? status, String label) {
    // 单值 chip 的选中态：空集时「全部」亮；恰好一个状态且相等时那颗亮。
    // 多状态组合时谁都不亮，靠上面的组合标签表达。
    final selected = status == null
        ? _statuses.isEmpty
        : _statuses.length == 1 && _statuses.contains(status);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() {
          _statuses = selected || status == null
              ? const <ItemStatus>{}
              : <ItemStatus>{status};
        }),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, String? itemId) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemEditPage(itemId: itemId)),
    );
    if (saved == true) _reload();
  }

  Future<void> _openDetail(BuildContext context, String itemId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemDetailPage(itemId: itemId)),
    );
    if (changed == true) _reload();
  }

  /// 删除是软删（打墓碑），会参与两端同步 —— 删掉的记录不会在对端复活。
  Future<void> _confirmDelete(ItemListRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这一笔？'),
        content: Text(
          '「${row.item.title}」会被删掉，它的费用和照片一起删。\n'
          '另一台设备下次同步时也会跟着消失。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(itemRepositoryProvider).delete(row.item.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已删除「${row.item.title}」')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.row,
    required this.onTap,
    required this.onDelete,
  });

  final ItemListRow row;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// 长按出菜单。列表上直接摆一个删除按钮太吵，但删除又必须能一步到，
  /// 所以走长按 —— 和手机相册删照片是同一个手势。
  Future<void> _showActions(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('二维码'),
              onTap: () => Navigator.of(ctx).pop('qr'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                '删除这一笔',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
    if (picked == 'qr') {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) =>
            QrDialog(itemId: row.item.id, title: row.item.title),
      );
    }
    if (picked == 'delete') onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = row.item;
    final line = row.profitLine;
    final profit = line.profitCents;

    return GlassCard(
      radius: 12,
      blur: 12,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      onLongPress: () => _showActions(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(bytes: row.thumb, heroTag: 'item-thumb-${item.id}'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (line.isTradeIn) ...[
                      const _TradeInBadge(),
                      const SizedBox(width: 6),
                    ],
                    _StatusBadge(status: item.status),
                    IconButton(
                      tooltip: '二维码',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => QrDialog(
                          itemId: item.id,
                          title: item.title,
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_2, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (item.brand != null && item.brand!.isNotEmpty)
                      item.brand!,
                    if (item.model != null && item.model!.isNotEmpty)
                      item.model!,
                    if (item.storage != null && item.storage!.isNotEmpty)
                      item.storage!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PriceTag(
                      label: '买',
                      text: Money(item.buyPriceCents).toYuanString(),
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    _PriceTag(
                      label: '卖',
                      text: item.sellPriceCents == null
                          ? '—'
                          : Money(item.sellPriceCents!).toYuanString(),
                      color: scheme.onSurfaceVariant,
                    ),
                    // 抵扣单独成段：它不是卖价的一部分，塞进「卖」会被读成
                    // 「这台卖了 ¥2,300，其中 ¥800 是旧机」，账就乱了。
                    if (line.isTradeIn) ...[
                      const SizedBox(width: 12),
                      Text(
                        '抵 ${Money(line.tradeInCents).toYuanString()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.accent,
                          fontFeatures: kTabularFigures,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (profit != null)
                      Text(
                        Money(profit).toYuanString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFeatures: kTabularFigures,
                          color: moneyColor(profit, context.palette),
                        ),
                      )
                    else
                      Text(
                        '占用 ${Money(line.capitalOccupiedCents).toYuanString()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.warning,
                          fontFeatures: kTabularFigures,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.bytes, this.heroTag});

  final Uint8List? bytes;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;

    final Widget child;
    if (bytes == null) {
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.palette.cardFill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.photo_outlined,
          size: 20,
          color: context.palette.textSecondary.withValues(alpha: 0.6),
        ),
      );
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: context.palette.cardFill,
            child: Icon(
              Icons.broken_image_outlined,
              size: 20,
              color: context.palette.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    if (heroTag == null) return child;
    return Hero(tag: heroTag!, child: child);
  }
}

/// 置换徽章：这台是「以旧换新」成交的。
///
/// 用 accent 而不是状态色 —— 它和「已卖出 / 已到账」不是同一个维度，
/// 混进状态色里会被读成又一种状态。
class _TradeInBadge extends StatelessWidget {
  const _TradeInBadge();

  @override
  Widget build(BuildContext context) {
    final color = context.palette.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '置换',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      ItemStatus.inStock => scheme.primary,
      ItemStatus.listed => context.palette.warning,
      // 已卖出但钱没到：钱还没进兜，按待收款色提醒。
      ItemStatus.sold => context.palette.receivable,
      // 已到账：钱真到手了，才用「赚到」的绿色。
      ItemStatus.completed => context.palette.profit,
      ItemStatus.returned => context.palette.loss,
      ItemStatus.scrapped => scheme.outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({
    required this.label,
    required this.text,
    required this.color,
  });

  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.6)),
          ),
          TextSpan(text: text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// 筛选条：只按日期（字段 + 区间）。
///
/// 分类不再是筛子 —— 翻账时要问的是「这段时间卖出了什么」，
/// 而不是「这个分类卖出了什么」。分类仍然长在商品上：编辑页能填、
/// 统计页能分组、导表带得出，只是不进筛选条。
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.field,
    required this.range,
    required this.onPickDate,
    required this.onClearDate,
  });

  final DateField? field;
  final DateRange range;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (field != null && !range.isEmpty)
            Expanded(
              child: InputChip(
                avatar: const Icon(Icons.event_outlined, size: 16),
                label: Text(
                  '${field!.label} · ${range.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: onPickDate,
                onDeleted: onClearDate,
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            )
          else
            ActionChip(
              avatar: const Icon(Icons.event_outlined, size: 16),
              label: const Text('按日期筛选'),
              onPressed: onPickDate,
            ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter
                  ? Icons.filter_alt_off_outlined
                  : Icons.inventory_2_outlined,
              size: 48,
              color: scheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter ? '没有符合条件的记录' : '还没有任何记录',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
