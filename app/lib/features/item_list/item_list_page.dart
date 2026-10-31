import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/dao/item_dao.dart';
import '../../domain/enums.dart';
import '../../domain/money.dart';
import '../../ui/glass_card.dart';
import '../../ui/particles.dart';
import '../../ui/shimmer.dart';
import '../item_detail/item_detail_page.dart';
import '../item_edit/item_edit_page.dart';

/// 明细列表：搜索 + 状态筛选 + 单件盈亏。
class ItemListPage extends ConsumerStatefulWidget {
  const ItemListPage({super.key});

  @override
  ConsumerState<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends ConsumerState<ItemListPage> {
  final _searchController = TextEditingController();
  String _keyword = '';
  bool _burst = false;
  ItemStatus? _status;

  /// 入场动效只播一次。
  ///
  /// 列表是 drift 的实时流，同步一次就会重建一遍。如果每次都 fadeIn + slideY，
  /// 用户正盯着列表看，另一台设备改了个价，整屏条目就会重新「浮现」一次 ——
  /// 看起来像页面在刷新，其实是数据在流动。只在第一次进来时播，之后静默替换。
  bool _introPlayed = false;

  @override
  void initState() {
    super.initState();
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
    final filter = ItemFilter(status: _status, keyword: _keyword);
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
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _statusChip(null, '全部'),
                for (final s in ItemStatus.values) _statusChip(s, s.label),
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
                  return _EmptyList(hasFilter: _status != null || _keyword.isNotEmpty);
                }
                return RefreshIndicator(
                  color: context.palette.accent,
                  backgroundColor: const Color(0xFF1A212B),
                  displacement: 32,
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final tile = _ItemTile(
                        row: rows[i],
                        onTap: () => _openDetail(context, rows[i].item.id),
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
                child: IgnorePointer(child: ParticleBurst(color: context.palette.accent)),
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
    final filter = ItemFilter(status: _status, keyword: _keyword);
    ref.invalidate(itemListProvider(filter));
    ref.invalidate(profitSummaryProvider);
    if (mounted) setState(() => _burst = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _burst = false);
  }

  Widget _statusChip(ItemStatus? status, String label) {    final selected = _status == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _status = selected ? null : status),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除「${row.item.title}」')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
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
                    _StatusBadge(status: item.status),
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
                  style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
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
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.label, required this.text, required this.color});

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
              hasFilter ? Icons.filter_alt_off_outlined : Icons.inventory_2_outlined,
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