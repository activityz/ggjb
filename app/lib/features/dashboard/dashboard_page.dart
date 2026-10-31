import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/dao/stat_dao.dart';
import '../../domain/money.dart';
import '../../domain/profit.dart';
import '../../ui/glass_card.dart';
import '../../ui/gradient_text.dart';
import '../../ui/particles.dart';
import '../../ui/rolling_number.dart';
import '../../ui/shimmer.dart';
import '../../ui/tap_scale.dart';

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
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profitSummaryProvider);

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
                return _DashboardBody(aggregate: agg);
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
  const _DashboardBody({required this.aggregate});

  final ProfitAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final summary = aggregate.summary;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(summary: summary)
            .animate()
            .fadeIn(duration: 420.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.05,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 16),
        _SectionLabel('分成四块，不混算'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final cards = [
              _MetricCard(
                title: '已实现利润',
                value: Money(summary.realizedProfitCents).toYuanString(),
                hint: '${summary.soldCount} 单已卖出',
                color: context.palette.profit,
                icon: Icons.trending_up,
                footnote: '只统计卖掉成功的单子，退货和报废不算在内',
              ),
              _MetricCard(
                title: '待收货款',
                value: Money(summary.pendingReceivableCents).toYuanString(),
                hint: '${summary.receivableCount} 单钱还没到',
                color: context.palette.receivable,
                icon: Icons.schedule,
                footnote: '买家和平台还欠你的货款。是欠款不是利润，对应的利润已经算进左边了',
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
            // 宽屏两行两列。IntrinsicHeight 让同一行两张卡等高，
            // 否则 footnote 行数不同会一高一低。
            return Column(
              children: [
                for (var row = 0; row < 2; row++) ...[
                  if (row > 0) const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var col = 0; col < 2; col++) ...[
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
                label: '平均每单毛利',
                value: summary.averageRealizedCents == null
                    ? '—'
                    : Money(summary.averageRealizedCents!).toYuanString(),
              ),
              const Divider(height: 24),
              _KvRow(
                label: '已实现毛利率',
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
        _SectionLabel('按分类'),
        const SizedBox(height: 8),
        _GroupCard(
          provider: categoryStatsProvider,
          emptyHint: '还没填过分类',
        ),
        const SizedBox(height: 16),
        _SectionLabel('按卖出渠道'),
        const SizedBox(height: 8),
        _GroupCard(
          provider: platformStatsProvider,
          emptyHint: '还没填过卖出渠道',
        ),
        const SizedBox(height: 16),
        _Note(
          '毛利率的分母只是已售商品的成本，不含还在手上的货。'
          '把在途占用算进分母会让毛利率看着很低，失去参考意义。',
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
  const _HeroCard({required this.summary});

  final ProfitSummary summary;

  @override
  Widget build(BuildContext context) {
    final net = summary.netProfitCents;
    final money = Money(net).toYuanString();
    final glowColor = net >= 0 ? context.palette.profit : context.palette.loss;

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
                      '净到手',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: '已实现利润 + 了结亏损。也就是这些单子实际给你留下的钱。',
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
                  gradient: moneyGradient(net, context.palette),
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
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      text: '待收 ${summary.receivableCount}',
                      color: context.palette.receivable,
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      text: '未卖 ${summary.activeCount}',
                      color: context.palette.warning,
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

/// 小胶囊标签。
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          fontFeatures: kTabularFigures,
        ),
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
  });

  final String title;
  final String value;
  final String hint;
  final Color color;
  final IconData icon;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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