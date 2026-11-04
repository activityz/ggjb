import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/dao/stat_dao.dart';
import '../../domain/date_period.dart';
import '../../domain/enums.dart';
import '../../domain/money.dart';
import '../../domain/profit.dart';
import '../../ui/glass_card.dart';
import '../../ui/gradient_text.dart';
import '../../ui/particles.dart';
import '../../ui/rolling_number.dart';
import '../../ui/shimmer.dart';
import '../../ui/tap_scale.dart';
import '../item_list/item_list_page.dart';
import '../operating/operating_cost_page.dart';

/// 看板上的数字／胶囊点开时用的跳转：带上标题和状态口径，push 一页明细。
typedef _OpenItems = void Function(
  String title, {
  ItemStatus? status,
  Set<ItemStatus>? statuses,
});

/// 看板：一眼看到「赚了多少、压了多少钱、还有多少没卖掉」。
///
/// 口径严格遵守 domain/profit.dart：
/// - 净到手 = 已实现利润 + 了结亏损
/// - 在途占用单独展示，**不计入利润**
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DashboardFilter _filter = DashboardFilter.all;

  /// 看板筛选：日期字段 + 区间。
  ///
  /// 分类筛选已经拿掉了 —— 看板回答的是「这段时间挣了多少」，按分类切一刀
  /// 只会把总数切碎，真正想看某个分类时去明细页筛更顺手。
  ///
  /// 默认「全部时间」：打开看板不该先被要求选个时间，看到的就是全部账。
  /// 筛选条件只在本地 state 里，不落库：它是「现在想怎么看」，不是一台
  /// 设备上的长期设定。
  Future<void> _pickFilter() async {
    var field = _filter.dateField;
    var range = _filter.range;
    final now = DateTime.now();

    final applied = await showModalBottomSheet<DashboardFilter>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '看哪段时间？',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '只看这段时间卖出去或买进来的单子。不选就是全部账。',
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
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('全部时间'),
                          onPressed: () =>
                              setLocal(() => range = DateRange.all),
                        ),
                        ActionChip(
                          label: const Text('本月'),
                          onPressed: () =>
                              setLocal(() => range = DateRange.thisMonth(now)),
                        ),
                        ActionChip(
                          label: const Text('上月'),
                          onPressed: () =>
                              setLocal(() => range = DateRange.lastMonth(now)),
                        ),
                        ActionChip(
                          label: const Text('最近 7 天'),
                          onPressed: () => setLocal(
                            () => range = DateRange.lastDays(now, 7),
                          ),
                        ),
                        ActionChip(
                          label: const Text('今年'),
                          onPressed: () =>
                              setLocal(() => range = DateRange.thisYear(now)),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: const Text('自定义…'),
                          onPressed: () async {
                            final start = range.from ?? now;
                            final end = range.to ?? now;
                            final picked = await showDateRangePicker(
                              context: ctx,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDateRange: end.isBefore(start)
                                  ? null
                                  : DateTimeRange(start: start, end: end),
                              helpText: '选一段时间（含首尾两天）',
                              saveText: '就这段',
                            );
                            if (picked == null) return;
                            setLocal(
                              () => range = DateRange(
                                from: picked.start,
                                to: picked.end,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '当前：${field.label} · ${range.label}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(
                              ctx,
                            ).pop(const DashboardFilter()),
                            child: const Text('重置'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(
                              DashboardFilter(
                                dateField: field,
                                range: range,
                              ),
                            ),
                            child: const Text('应用'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (applied == null || !mounted) return;
    setState(() => _filter = applied);
  }

  /// 点开看板上的数字 / 胶囊，看这批单子到底是谁。
  ///
  /// 直接 push 一个新的明细页，而不是切底部 tab：tab 里的列表带着用户自己的
  /// 搜索词和状态，被看板覆盖掉再回来就找不回原样了。这里带上当前看板的时间
  /// 筛选；状态可以是一组（已卖出 = 已卖出 + 已到账），所以传 statuses。
  void _openItems(
    String title, {
    ItemStatus? status,
    Set<ItemStatus>? statuses,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ItemListPage(
            initialFilter: ItemFilter(
              status: status,
              statuses: statuses,
              dateField: _filter.range.isEmpty ? null : _filter.dateField,
              range: _filter.range,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profitSummaryProvider(_filter));

    return Scaffold(
      body: Stack(
        children: [
          // 页面底渐变 + 常驻粒子：粒子只在看板出现，别的页不铺，
          // 否则每一页都在动，反而没有「哪里是重点」。
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: context.palette.pageGradient),
            ),
          ),
          const Positioned.fill(child: AmbientParticles()),
          Positioned.fill(
            child: async.when(
              loading: () => const DashboardSkeleton(),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('读取数据失败：$err'),
                ),
              ),
              data: (agg) {
                // 没有任何一条记录时才显示空态。判据用计数而不是和
                // ProfitSummary.empty 比较对象——那是 const 常量，比较字段更可靠。
                final empty =
                    agg.summary.closedCount == 0 && agg.summary.activeCount == 0;
                if (empty) return const _EmptyDashboard();
                return _DashboardBody(
                  aggregate: agg,
                  filter: _filter,
                  onFilterTap: _pickFilter,
                  onOpenItems: _openItems,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text('还没有记录', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '去「明细」页添加第一件商品，填上买入价，卖出后这里就会出现盈亏。',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.aggregate,
    required this.filter,
    required this.onFilterTap,
    required this.onOpenItems,
  });

  final ProfitAggregate aggregate;
  final DashboardFilter filter;
  final VoidCallback onFilterTap;

  /// 数字点开看明细。由页面 state 提供，body 只负责把口径传下去。
  final _OpenItems onOpenItems;

  @override
  Widget build(BuildContext context) {
    final summary = aggregate.summary;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FilterBar(filter: filter, onTap: onFilterTap),
        const SizedBox(height: 12),
        _HeroCard(aggregate: aggregate, onOpenItems: onOpenItems)
            .animate()
            .fadeIn(duration: 420.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.05,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 6),
        _OperatingCostLine(filter: filter),
        const SizedBox(height: 16),
        _SectionLabel('分成几块，不混算'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            // 总利润已经在上面那张大卡里，这里不再重复一张。
            final cards = [
              _MetricCard(
                title: '已到手利润',
                value: Money(summary.settledProfitCents).toYuanString(),
                hint: '${summary.soldCount} 单已卖出',
                color: context.palette.profit,
                icon: Icons.account_balance_wallet_outlined,
                footnote: '钱真的收到手才算这里，一般是你把状态改成「已完成」之后',
                onTap: () =>
                    onOpenItems('已到手利润', status: ItemStatus.completed),
              ),
              _MetricCard(
                title: '未到手利润',
                value: Money(summary.unsettledProfitCents).toYuanString(),
                hint: '${summary.receivableCount} 单钱还没到',
                color: context.palette.receivable,
                icon: Icons.hourglass_bottom,
                footnote: '货已经卖了、钱还在买家或平台手里。每单多少是按成交价算出来的，不是估的',
                onTap: () => onOpenItems('未到手利润', status: ItemStatus.sold),
              ),
              _MetricCard(
                title: '待收货款',
                value: Money(summary.pendingReceivableCents).toYuanString(),
                hint: '${summary.receivableCount} 单钱还没到',
                color: context.palette.receivable,
                icon: Icons.schedule,
                footnote: '买家和平台还欠你的货款。是欠款不是利润，对应的利润已经算在「未到手利润」里了',
                onTap: () => onOpenItems('待收货款', status: ItemStatus.sold),
              ),
              _MetricCard(
                title: '了结亏损',
                value: Money(summary.closedLossCents).toYuanString(),
                hint: '${summary.lossClosedCount} 单退货/报废',
                color: context.palette.loss,
                icon: Icons.trending_down,
                footnote: '货没换成钱，但买入价和运费已经花出去',
              ),
              _MetricCard(
                title: '在途占用',
                value: Money(summary.capitalOccupiedCents).toYuanString(),
                hint: '${summary.activeCount} 件未卖出',
                color: context.palette.warning,
                icon: Icons.savings_outlined,
                footnote: '压在手上的钱，不是亏损，卖掉才能变成利润',
                onTap: () => onOpenItems(
                  '在途占用',
                  statuses: const {ItemStatus.inStock, ItemStatus.listed},
                ),
              ),
            ];

            if (c.maxWidth < 720) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _stagger(cards[i], i),
                  ],
                ],
              );
            }
            // 宽屏每行两张。IntrinsicHeight 让同一行两张卡等高，
            // 否则 footnote 行数不同会一高一低。
            return Column(
              children: [
                for (var row = 0; row * 2 < cards.length; row++) ...[
                  if (row > 0) const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var col = 0; col < 2; col++)
                          if (row * 2 + col < cards.length) ...[
                            if (col > 0) const SizedBox(width: 12),
                            Expanded(
                              child: _stagger(cards[row * 2 + col], row * 2 + col),
                            ),
                          ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _SectionLabel('效率指标'),
        const SizedBox(height: 8),
        GlassCard(
          radius: 14,
          blur: 12,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _KvRow(
                label: '平均每单利润',
                value: summary.averageRealizedCents == null
                    ? '—'
                    : Money(summary.averageRealizedCents!).toYuanString(),
              ),
              const Divider(height: 24),
              _KvRow(
                label: '已实现利润率',
                value: _rateText(
                  summary.realizedMarginRate(aggregate.realizedCostCents),
                ),
              ),
              const Divider(height: 24),
              _KvRow(
                label: '已了结单数',
                value: '${summary.closedCount} 单',
              ),
              const Divider(height: 24),
              _KvRow(
                label: '已售成本合计',
                value: Money(aggregate.realizedCostCents).toYuanString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionLabel('每月卖出'),
        const SizedBox(height: 8),
        _MonthlySoldCard(filter: filter),        const SizedBox(height: 16),
        _SectionLabel('按分类'),
        const SizedBox(height: 8),
        _GroupCard(
          provider: categoryStatsProvider(filter),
          emptyHint: '还没填过分类',
        ),
        const SizedBox(height: 16),
        _SectionLabel('按卖出渠道'),
        const SizedBox(height: 8),
        _GroupCard(
          provider: platformStatsProvider(filter),
          emptyHint: '还没填过卖出渠道',
        ),
        const SizedBox(height: 16),
        _Note(
          '利润率的分母只是已售商品的成本，不含还在手上的货。'
          '把在途占用算进分母会让利润率看着很低，失去参考意义。',
          color: scheme,
        ),
      ],
    );
  }

  /// 卡片错峰入场：0 / 60 / 120 / 180ms。
  ///
  /// 只给卡片用，section 标题不加 —— 标题也跟着浮起来会让整页像在「加载」。
  static Widget _stagger(Widget child, int index) {
    final delay = (index * 60).ms;
    return child.animate().fadeIn(
          duration: 420.ms,
          delay: delay,
          curve: Curves.easeOut,
        ).slideY(
          begin: 0.08,
          duration: 480.ms,
          delay: delay,
          curve: Curves.easeOutCubic,
        );
  }

  static String _rateText(double? rate) {
    if (rate == null) return '—';
    return '${(rate * 100).toStringAsFixed(1)}%';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.aggregate, required this.onOpenItems});

  final ProfitAggregate aggregate;
  final _OpenItems onOpenItems;

  @override
  Widget build(BuildContext context) {
    final summary = aggregate.summary;
    // 总利润扣过运营成本（用户口径 A）。summary 里那个数是「卖货挣的」，
    // 运营成本不是某一单的成本，所以减法只在这一层做。
    final total = aggregate.netAfterOperatingCents;
    final money = Money(total).toYuanString();
    final glowColor = total >= 0 ? context.palette.profit : context.palette.loss;

    return TapScale(
      scale: 0.985,
      haptic: false,
      child: GlassCard(
        radius: 20,
        blur: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        tint: glowColor,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 视差底光：滚得越远，光斑越往上飘，制造「卡在浮着」的错觉
            Positioned(
              right: -50,
              top: -70,
              child: _Parallax(
                factor: 0.10,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowColor.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '总利润',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: '已到手的利润 + 已经了结的亏损，再减掉这段时间的运营成本。'
                          '也就是这些单子最后给你留下的钱；还在手上、没卖出去的货不算在内。',
                      child: Icon(
                        Icons.info_outline,
                        size: 15,
                        color: context.palette.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GradientText(
                  money,
                  gradient: moneyGradient(total, context.palette),
                  glow: 14,
                  glowColor: glowColor,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Pill(
                      text: '已卖出 ${summary.soldCount}',
                      color: context.palette.profit,
                      onTap: () => onOpenItems(
                        '已卖出',
                        statuses: const {
                          ItemStatus.sold,
                          ItemStatus.completed,
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      text: '待收 ${summary.receivableCount}',
                      color: context.palette.receivable,
                      onTap: () =>
                          onOpenItems('待收货款', status: ItemStatus.sold),
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      text: '未卖 ${summary.activeCount}',
                      color: context.palette.warning,
                      onTap: () => onOpenItems(
                        '未卖出',
                        statuses: const {
                          ItemStatus.inStock,
                          ItemStatus.listed,
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 跟随主滚动控制器做反向位移的层。
///
/// ListView 自带 `PrimaryScrollController`，所以这里不必自己维护 controller。
/// [factor] 是位移比例：0.10 背景、0.25 粒子、1.0 就是普通滚动（不用包）。
class _Parallax extends StatefulWidget {
  const _Parallax({required this.child, required this.factor});

  final Widget child;
  final double factor;

  @override
  State<_Parallax> createState() => _ParallaxState();
}

class _ParallaxState extends State<_Parallax>
    with SingleTickerProviderStateMixin {
  ScrollController? _controller;
  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    // 拿不到 controller 时也得有个可监听的 animation，否则 AnimatedBuilder 报错。
    _idle = AnimationController(vsync: this, duration: Duration.zero);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _controller = PrimaryScrollController.maybeOf(context));
    });
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _controller ?? _idle;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final c = _controller;
        final offset = (c != null && c.hasClients) ? c.offset : 0.0;
        return Transform.translate(
          offset: Offset(0, -offset * widget.factor),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 小胶囊标签。带 [onTap] 时整颗可点，末尾带一个箭头暗示「点得动」。
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.onTap});

  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 7, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: kTabularFigures,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 1),
            Icon(Icons.chevron_right, size: 12, color: color),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }
}

/// 近 12 个月每月卖出多少台。
///
/// 口径在 StatDao.monthlySoldCounts 里：只算「已卖出 / 已完成」，按卖出日期归月，
/// 退货和报废不算 —— 它们没有真正卖出去。
class _MonthlySoldCard extends ConsumerWidget {
  const _MonthlySoldCard({required this.filter});

  final DashboardFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthlySoldProvider(filter));

    return async.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => GlassCard(
        radius: 14,
        blur: 12,
        padding: const EdgeInsets.all(16),
        child: Text('读取失败：$err'),
      ),
      data: (rows) {
        if (rows.isEmpty || rows.every((r) => r.count == 0)) {
          return GlassCard(
            radius: 14,
            blur: 12,
            padding: const EdgeInsets.all(16),
            child: Text(
              '最近 12 个月还没有卖出的记录。',
              style: TextStyle(
                color: context.palette.textSecondary,
                height: 1.45,
              ),
            ),
          );
        }

        var max = 0;
        for (final r in rows) {
          if (r.count > max) max = r.count;
        }
        // 数据是从旧到新排的，倒过来显示，最近一个月在最上面。
        final ordered = rows.reversed.toList();

        return GlassCard(
          radius: 14,
          blur: 12,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              for (final r in ordered) _MonthlySoldRow(row: r, max: max),
              const SizedBox(height: 8),
              Text(
                '按卖出日期归月。退货和报废的单子不算，它们没有真正卖出去。',
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textSecondary.withValues(alpha: 0.72),
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthlySoldRow extends StatelessWidget {
  const _MonthlySoldRow({required this.row, required this.max});

  final MonthlySoldCount row;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (row.count / max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            child: Text(
              row.label,
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textSecondary,
                fontFeatures: kTabularFigures,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: context.palette.cardFill,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.palette.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${row.count}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary,
                fontFeatures: kTabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.color,
    required this.icon,
    required this.footnote,
    this.onTap,
  });

  final String title;
  final String value;
  final String hint;
  final Color color;
  final IconData icon;
  final String footnote;

  /// 点了去哪。null = 这张卡只是个数字，点不动。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      radius: 14,
      blur: 12,
      padding: const EdgeInsets.all(16),
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RollingNumber(
            text: value,
            color: color,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            footnote,
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textSecondary.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFeatures: kTabularFigures,
          ),
        ),
      ],
    );
  }
}

/// 看板顶部的筛选条：一行说明现在的口径，点开换。
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onTap});

  final DashboardFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = filter.isAll
        ? '全部时间'
        : '${filter.dateField.label} · ${filter.range.label}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: palette.cardFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 16,
              color: palette.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: palette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 总利润下面那行小字：这段时间花了多少运营成本，点进去记 / 看。
///
/// 它已经从总利润里扣掉了，这里不再重复减，只是把扣了多少摊开 ——
/// 不然总利润少了会觉得账对不上。
class _OperatingCostLine extends ConsumerWidget {
  const _OperatingCostLine({required this.filter});

  final DashboardFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final total = ref.watch(operatingTotalProvider(filter)).value ?? 0;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OperatingCostPage(filter: filter),
          ),
        ),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 13,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '运营成本 ${Money(total).toYuanString()}，已从总利润里扣',
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {required this.color});

  final String text;
  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 16, color: color.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: color.onSurfaceVariant, height: 1.5),
          ),
        ),
      ],
    );
  }
}

/// 按某个维度（分类 / 渠道）的盈亏排行。只显示前 6 个。
class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.provider, required this.emptyHint});

  final FutureProvider<List<GroupStat>> provider;
  final String emptyHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      radius: 14,
      blur: 12,
      padding: EdgeInsets.zero,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('统计失败：$err'),
        ),
        data: (stats) {
          if (stats.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                emptyHint,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            );
          }
          final shown = stats.take(6).toList();
          final maxAbs = shown
              .map((s) => s.profitCents.abs())
              .fold<int>(0, (a, b) => a > b ? a : b);
          return Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _GroupRow(stat: shown[i], maxAbs: maxAbs),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.stat, required this.maxAbs});

  final GroupStat stat;
  final int maxAbs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = moneyColor(stat.profitCents, context.palette);
    final ratio = maxAbs == 0 ? 0.0 : (stat.profitCents.abs() / maxAbs).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                Money(stat.profitCents).toYuanString(),
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: const Color(0x14FFFFFF),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${stat.closedCount} 单',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}