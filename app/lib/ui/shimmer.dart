import 'package:flutter/material.dart';

import '../app/palette.dart';

/// 骨架屏的扫光层。
///
/// 直接把要占位的形状放进 [child]，外面套一层 [Shimmer] 就行；
/// 用 `ShaderMask` 扫一条高光过去，比整块 `AnimatedContainer` 呼吸省事，
/// 也不会因为透明度变化让底色跟着变。
///
/// 高光色跟主题走：暗底滑白光，浅底滑深色 —— 白底上再滑白光是看不见的。
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.glass;
    final edge = isDark ? const Color(0x00FFFFFF) : const Color(0x00000000);
    final peak = isDark ? const Color(0x14FFFFFF) : const Color(0x14000000);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // -1 → 2 让高光完整地从左边滑出、从右边滑入，中间不留停顿。
        final t = _controller.value * 3 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[edge, peak, edge],
            stops: <double>[
              (t - 0.35).clamp(0.0, 1.0),
              t.clamp(0.0, 1.0),
              (t + 0.35).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 骨架块：一个圆角的低对比色块。
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: p.glass ? const Color(0x0DFFFFFF) : const Color(0xFFE7ECF1),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// 卡片底：跟 [GlassCard] 用同一套底色与描边，骨架屏才不会跟真卡片错位。
Widget _skeletonCard({
  required BuildContext context,
  required double radius,
  required Widget child,
  EdgeInsetsGeometry padding = EdgeInsets.zero,
  double? height,
}) {
  final p = context.palette;
  return Container(
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: p.cardFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: p.cardBorderStart),
      boxShadow: p.cardShadow,
    ),
    child: child,
  );
}

/// 列表占位：几张假卡片，形状跟 [ItemListPage] 的 `_ItemTile` 对齐。
class ItemListSkeleton extends StatelessWidget {
  const ItemListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _skeletonCard(
          context: context,
          radius: 12,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              const ShimmerBox(width: 56, height: 56, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerBox(width: 120 + (i % 3) * 24),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: 160, height: 10),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: 90, height: 10),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerBox(width: 56, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 看板占位：一张大卡 + 四张小卡。
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          _skeletonCard(
            context: context,
            radius: 20,
            height: 148,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                ShimmerBox(width: 60, height: 11),
                SizedBox(height: 14),
                ShimmerBox(width: 190, height: 34, radius: 8),
                SizedBox(height: 18),
                ShimmerBox(width: 230, height: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: <Widget>[
              Expanded(child: _MiniCard()),
              SizedBox(width: 12),
              Expanded(child: _MiniCard()),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: <Widget>[
              Expanded(child: _MiniCard()),
              SizedBox(width: 12),
              Expanded(child: _MiniCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard();

  @override
  Widget build(BuildContext context) {
    return _skeletonCard(
      context: context,
      radius: 14,
      height: 92,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          ShimmerBox(width: 48, height: 10),
          SizedBox(height: 12),
          ShimmerBox(width: 80, height: 20, radius: 8),
        ],
      ),
    );
  }
}
