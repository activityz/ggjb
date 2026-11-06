import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/dao/item_dao.dart';
import '../../domain/date_period.dart';
import '../../domain/dict_seeds.dart';
import '../../domain/enums.dart';
import '../../domain/image_pipeline.dart';
import '../../domain/money.dart';
import '../../ui/glass_card.dart';
import '../../ui/gradient_text.dart';
import '../../ui/particles.dart';
import '../barcode/qr_dialog.dart';
import '../common/dict_field.dart';
import '../item_edit/item_edit_page.dart';

/// 商品详情：看盈亏、看图片、改状态。
class ItemDetailPage extends ConsumerStatefulWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends ConsumerState<ItemDetailPage> {
  bool _busy = false;
  bool _changed = false;
  bool _celebrate = false;

  static const _pipeline = ImagePipeline();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(itemDetailProvider(widget.itemId));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        appBar: AppBar(
          title: const Text('商品详情'),
          actions: [
            IconButton(
              tooltip: '二维码',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => QrDialog(
                  itemId: widget.itemId,
                  title: async.value?.item.title,
                ),
              ),
              icon: const Icon(Icons.qr_code_2),
            ),
            IconButton(
              tooltip: '编辑',
              onPressed: _busy ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
            if (_changed)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('返回'),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: context.palette.pageGradient,
                ),
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('读取失败：$err')),
                  data: (detail) {
                    if (detail == null) {
                      return const Center(child: Text('这条记录已被删除'));
                    }
                    return _body(detail);
                  },
                ),
              ),
            ),
            if (_celebrate)
              const Positioned.fill(
                child: IgnorePointer(child: ParticleBurst()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(ItemWithExpenses detail) {
    final scheme = Theme.of(context).colorScheme;
    final item = detail.item;
    final line = detail.toProfitLine();
    final profit = line.profitCents;
    final accent = profit == null
        ? context.palette.warning
        : moneyColor(profit, context.palette);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Chip(label: Text(item.status.label)),
          ],
        ),
        // 品牌 · 型号 · 内存规格 · 颜色，有哪项显示哪项。
        if ([
          item.brand,
          item.model,
          item.storage,
          item.color,
        ].any((e) => e != null && e.isNotEmpty)) ...[
          const SizedBox(height: 4),
          Text(
            [
              item.brand,
              item.model,
              item.storage,
              item.color,
            ].where((e) => e != null && e.isNotEmpty).join(' · '),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
        // 置换单要一眼可辨：状态 Chip 回答「卖没卖」，这里回答「怎么卖的」。
        if (line.isTradeIn) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.palette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '置换成交',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.palette.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '旧机抵扣',
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                Money(line.tradeInCents).toYuanString(),
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.palette.accent,
                  fontWeight: FontWeight.w600,
                  fontFeatures: kTabularFigures,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // 利润卡：口径完全来自 domain/profit.dart
        GlassCard(
              radius: 18,
              blur: 18,
              padding: const EdgeInsets.all(16),
              tint: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profit == null ? '还没卖出，暂无利润' : '这一单',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GradientText(
                    profit == null
                        ? Money(line.capitalOccupiedCents).toYuanString()
                        : Money(profit).toYuanString(),
                    gradient: profit == null
                        ? accentGradient(context.palette)
                        : moneyGradient(profit, context.palette),
                    glow: 12,
                    glowColor: accent,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (profit == null)
                    Text(
                      '资金占用中',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _kv('买入价', Money(item.buyPriceCents).toYuanString()),
                  _kv(
                    '卖出价',
                    item.sellPriceCents == null
                        ? '—'
                        : Money(item.sellPriceCents!).toYuanString(),
                  ),
                  _kv('费用合计', Money(line.expenseCents).toYuanString()),
                  _kv(
                    '总投入',
                    Money(line.totalCostCents).toYuanString(),
                    bold: true,
                  ),
                  if (line.marginRate != null)
                    _kv(
                      '利润率',
                      '${(line.marginRate! * 100).toStringAsFixed(1)}%',
                    ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 420.ms, curve: Curves.easeOut)
            .slideY(begin: 0.06, duration: 480.ms, curve: Curves.easeOutCubic),
        // 费用紧跟在利润卡后面：它是「利润为什么是这个数」的明细，
        // 属于财务主线；时间、渠道、成色是属性，往后排。
        const SizedBox(height: 16),
        _sectionTitle('费用明细'),
        GlassCard(
          radius: 14,
          blur: 12,
          padding: EdgeInsets.zero,
          child: detail.expenses.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Text(
                    '这一单没有额外费用。运费、手续费、维修这些记在编辑页，'
                    '记了就会从利润里扣掉。',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final e in detail.expenses)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          e.side == ExpenseSide.buy
                              ? Icons.shopping_cart_outlined
                              : Icons.local_shipping_outlined,
                          size: 18,
                        ),
                        title: Text('${e.kind.label}（${e.side.label}）'),
                        trailing: Text(
                          Money(e.amountCents).toYuanString(),
                          style: const TextStyle(fontFeatures: kTabularFigures),
                        ),
                      ),
                  ],
                ),
        ),

        const SizedBox(height: 16),
        _sectionTitle('时间与渠道'),
        GlassCard(
          radius: 14,
          blur: 12,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _kv('买入日期', _dateText(item.buyDate)),
              _kv('买入来源', item.sourcePlatform ?? '—'),
              _kv('买入成色', item.conditionBought ?? '—'),
              if (item.batteryHealth != null)
                _kv('电池健康', '${item.batteryHealth}%'),
              // 保修：在保才给起止日；已过保只留状态一行；无保修不提（旧单据
              // 一律是 none，凭空多一行「无保修」只会让老记录看起来变脏了）。
              if (item.warrantyStatus == WarrantyStatus.active) ...[
                _kv('保修开始', _dateText(item.warrantyStart)),
                _kv('保修到期', _dateText(item.warrantyEnd)),
              ] else if (item.warrantyStatus == WarrantyStatus.expired)
                _kv('保修', '已过保'),
              if (item.sellDate != null) ...[
                const Divider(height: 20),
                _kv('卖出日期', _dateText(item.sellDate)),
                _kv('卖出渠道', item.sellPlatform ?? '—'),
                _kv('卖出成色', item.conditionSold ?? '—'),
                // 置换记录：只留痕，不进利润 —— 抵扣的旧机卖出时才结算。
                if (item.listPriceCents != null)
                  _kv('挂牌价', Money(item.listPriceCents!).toYuanString()),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('图片'),
            TextButton.icon(
              onPressed: _busy ? null : _addImages,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('添加'),
            ),
          ],
        ),
        _imageGrid(),

        if (item.note != null && item.note!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('备注'),
          GlassCard(
            radius: 14,
            blur: 12,
            padding: const EdgeInsets.all(16),
            child: Text(
              item.note!,
              style: TextStyle(color: context.palette.textPrimary, height: 1.5),
            ),
          ),
        ],

        const SizedBox(height: 20),
        _sectionTitle('改状态'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 货走了、钱在路上 —— 唯一该点的就是「钱到了」。
            if (item.status == ItemStatus.sold)
              FilledButton.tonalIcon(
                onPressed: _busy
                    ? null
                    : () => _setStatus(item.id, ItemStatus.completed, '已标记到账'),
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                ),
                label: const Text('标记已到账'),
              ),
            // 已到账点错了可以退回，但不能直接退货——先退回已卖出。
            if (item.status == ItemStatus.completed)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _unmarkCompleted(item.id),
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('退回已卖出'),
              ),
            if (item.status == ItemStatus.inStock ||
                item.status == ItemStatus.listed)
              FilledButton.tonalIcon(
                onPressed: _busy ? null : () => _markSold(item.id),
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: const Text('标记已卖出'),
              ),
            if (item.status == ItemStatus.inStock)
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _setStatus(item.id, ItemStatus.listed, '已标记上架'),
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: const Text('标记已上架'),
              ),
            if (item.status == ItemStatus.sold)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _markReturned(item.id),
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('买家退货'),
              ),
            if (item.status != ItemStatus.scrapped &&
                item.status != ItemStatus.completed)
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _setStatus(item.id, ItemStatus.scrapped, '已标记报废'),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('报废'),
              ),
            if (item.status != ItemStatus.inStock &&
                item.status != ItemStatus.completed)
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _setStatus(item.id, ItemStatus.inStock, '已回到在库'),
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('回到在库'),
              ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _imageGrid() {
    final attachmentsAsync = ref.watch(itemAttachmentsProvider(widget.itemId));
    return attachmentsAsync.when(
      loading: () => const SizedBox(height: 60),
      error: (e, _) => Text('图片读取失败：$e'),
      data: (list) {
        if (list.isEmpty) {
          return Container(
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '还没有图片。买入截图、序列号铭牌都可以存这里。',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, meta) in list.indexed)
              GestureDetector(
                onLongPress: () => _deleteImage(meta.id),
                onTap: () => _viewImage(meta.id),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      // 首图与列表页缩略图共享元素：点进去时图片飞过去，不是整页黑一下。
                      child: i == 0
                          ? Hero(
                              tag: 'item-thumb-${widget.itemId}',
                              child: _ThumbView(attachmentId: meta.id),
                            )
                          : _ThumbView(attachmentId: meta.id),
                    ),
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          meta.role.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _kv(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  static String _dateText(DateTime? d) => d == null
      ? '—'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---- 动作 ----

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemEditPage(itemId: widget.itemId)),
    );
    if (saved == true) {
      _changed = true;
      _refresh();
    }
  }

  Future<void> _markSold(String itemId) async {
    final priceController = TextEditingController();
    final platformController = TextEditingController();
    final listController = TextEditingController();
    final tradeController = TextEditingController();
    final detail = await ref.read(itemRepositoryProvider).load(itemId);
    var sellDate = DateTime.now();
    // 置换是「这次卖出顺带收了一台旧机」。默认折叠：
    // 大多数人就是普通卖货，不该一进来先看见两个用不上的输入框。
    var hasTradeIn = false;
    if (detail != null) {
      final item = detail.item;
      priceController.text = item.sellPriceCents == null
          ? ''
          : Money(item.sellPriceCents!).toPlainString();
      platformController.text = item.sellPlatform ?? '';
      if (item.listPriceCents != null) {
        listController.text = Money(item.listPriceCents!).toPlainString();
      }
      if (item.tradeInCents != null && item.tradeInCents! > 0) {
        tradeController.text = Money(item.tradeInCents!).toPlainString();
      }
      hasTradeIn =
          item.listPriceCents != null ||
          (item.tradeInCents != null && item.tradeInCents! > 0);
      sellDate = item.sellDate ?? sellDate;
    }

    if (!mounted) return;
    // 卖出价一律必填：留空按 0 计等于把这单记成白送，
    // 利润直接变成负数，而用户以为只是「还没填」。
    String? priceError;
    String? platformError;
    String? listError;
    String? tradeError;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('标记已卖出'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: priceController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '卖出价（元）*',
                    hintText: '实收多少填多少，真白送就填 0',
                    errorText: priceError,
                  ),
                ),
                const SizedBox(height: 12),
                // 渠道走字典：二手平台就那么几个，手打字几乎必然打出
                // 「闲鱼 / 闲 鱼 / Xianyu」三种写法，统计时全散开。
                DictField(
                  controller: platformController,
                  label: '卖出渠道 *',
                  kind: DictSeeds.kindPlatform,
                  hint: '点这里选，字典里可以自己加',
                ),
                if (platformError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      platformError!,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: sellDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setLocal(() => sellDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '卖出日期 *'),
                    child: Row(
                      children: [
                        Expanded(child: Text(DateRange.formatDate(sellDate))),
                        const Icon(Icons.calendar_today_outlined, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: hasTradeIn,
                  title: const Text('这次收了一台旧机抵扣'),
                  subtitle: const Text('只记录，不冲抵这一单的利润'),
                  onChanged: (v) => setLocal(() => hasTradeIn = v),
                ),
                if (hasTradeIn) ...[
                  TextField(
                    controller: listController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '挂牌价（元）*',
                      hintText: '原本要价多少，例 1000',
                      errorText: listError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tradeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '旧机抵扣（元）*',
                      hintText: '买家旧机折了多少，例 600',
                      errorText: tradeError,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final raw = priceController.text.trim();
                final platform = platformController.text.trim();
                setLocal(() {
                  priceError = raw.isEmpty
                      ? '必须填卖出价'
                      : (Money.tryParseYuan(raw) == null ? '格式不对，填数字' : null);
                  platformError = platform.isEmpty ? '必须选卖出渠道' : null;

                  listError = null;
                  tradeError = null;
                  if (hasTradeIn) {
                    final listText = listController.text.trim();
                    final tradeText = tradeController.text.trim();
                    final list = Money.tryParseYuan(listText);
                    final trade = Money.tryParseYuan(tradeText);
                    if (listText.isEmpty) {
                      listError = '置换要填挂牌价';
                    } else if (list == null) {
                      listError = '格式不对，填数字';
                    }
                    if (tradeText.isEmpty) {
                      tradeError = '置换要填旧机抵扣';
                    } else if (trade == null) {
                      tradeError = '格式不对，填数字';
                    } else if (list != null && trade.cents > list.cents) {
                      tradeError = '抵扣不能大于挂牌价';
                    }
                  }
                });
                if (priceError != null ||
                    platformError != null ||
                    listError != null ||
                    tradeError != null) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final sell = Money.tryParseYuan(priceController.text);
    if (sell == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('卖出价格式不对')));
      }
      return;
    }
    final list = hasTradeIn ? Money.tryParseYuan(listController.text) : null;
    final trade = hasTradeIn ? Money.tryParseYuan(tradeController.text) : null;
    await _run(
      () => ref
          .read(itemRepositoryProvider)
          .markSold(
            itemId,
            sellPriceCents: sell.cents,
            sellDate: sellDate,
            sellPlatform: platformController.text.trim(),
            listPriceCents: list?.cents,
            tradeInCents: trade?.cents,
          ),
      '已标记售出',
    );
  }

  Future<void> _markReturned(String itemId) async {
    final ok = await _confirm('买家退货', '卖出记录会清空，卖出侧费用保留并计入亏损。');
    if (!ok) return;
    await _run(
      () => ref.read(itemRepositoryProvider).markReturned(itemId),
      '已标记退货',
    );
  }

  Future<void> _setStatus(
    String itemId,
    ItemStatus status,
    String toast,
  ) async {
    await _run(() async {
      final repo = ref.read(itemRepositoryProvider);
      switch (status) {
        case ItemStatus.inStock:
          await repo.backToStock(itemId);
        case ItemStatus.listed:
          await repo.markListed(itemId);
        case ItemStatus.completed:
          await repo.markCompleted(itemId);
        case ItemStatus.scrapped:
          await repo.markScrapped(itemId);
        case ItemStatus.sold:
        case ItemStatus.returned:
          break;
      }
    }, toast);
    // 钱到账是这整个 App 里唯一值得庆祝的事件，只有它触发爆发。
    if (status == ItemStatus.completed) _fireBurst();
  }

  void _fireBurst() {
    if (!mounted) return;
    setState(() => _celebrate = true);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _celebrate = false);
    });
  }

  Future<void> _unmarkCompleted(String itemId) async {
    await _run(
      () => ref.read(itemRepositoryProvider).unmarkCompleted(itemId),
      '已退回「已卖出」',
    );
  }

  Future<void> _delete() async {
    final ok = await _confirm('删除这条记录', '记录会进回收站（软删除），同步时不会复活。');
    if (!ok) return;
    await _run(
      () => ref.read(itemRepositoryProvider).delete(widget.itemId),
      '已删除',
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _run(Future<void> Function() action, String toast) async {
    setState(() => _busy = true);
    try {
      await action();
      _changed = true;
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(toast)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('操作失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh() {
    ref.invalidate(itemDetailProvider(widget.itemId));
    ref.invalidate(itemAttachmentsProvider(widget.itemId));
    ref.invalidate(profitSummaryProvider);
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _addImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _busy = true);
    final repo = ref.read(itemRepositoryProvider);
    var added = 0;
    var failed = 0;

    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        failed++;
        continue;
      }
      try {
        final processed = await _pipeline.process(bytes);
        await repo.addImage(
          itemId: widget.itemId,
          role: AttachmentRole.buyShot,
          bytes: processed.bytes,
          thumb: processed.thumb,
          width: processed.width,
          height: processed.height,
        );
        added++;
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() => _busy = false);
    _changed = true;
    _refresh();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failed == 0 ? '已添加 $added 张图片' : '已添加 $added 张，$failed 张失败',
          ),
        ),
      );
  }

  Future<void> _deleteImage(String id) async {
    final ok = await _confirm('删除这张图片', '图片会从库里移除。');
    if (!ok) return;
    await _run(() => ref.read(itemRepositoryProvider).deleteImage(id), '已删除图片');
  }

  Future<void> _viewImage(String id) async {
    final bytes = await ref.read(itemRepositoryProvider).fullImage(id);
    if (!mounted || bytes == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.memory(bytes)),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbView extends ConsumerWidget {
  const _ThumbView({required this.attachmentId});

  final String attachmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attachmentThumbProvider(attachmentId));
    const size = 84.0;

    return async.maybeWhen(
      data: (bytes) => bytes == null
          ? _placeholder(context)
          : Image.memory(
              Uint8List.fromList(bytes),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
      orElse: () => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    width: 84,
    height: 84,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}
