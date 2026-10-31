import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/palette.dart';

/// 环境粒子层：常驻背景，慢速漂移 + 呼吸明暗 + 最近邻连线。
///
/// 定调：**安静**。粒子透明度 0.06~0.14、连线 ≤0.08 —— 再亮一档就从
/// 「有质感」滑向「廉价炫光」，这是这个设计唯一不能让的品味线。
///
/// 亮色主题下不铺（`palette.particles == false`）：白底上的浅色点几乎看不见，
/// 看见了也只是噪点。
class AmbientParticles extends StatefulWidget {
  const AmbientParticles({
    super.key,
    this.count = 120,
    this.linkDistance = 130,
    this.linkOpacity = 0.08,
    this.speed = 0.12,
    this.color,
  });

  final int count;
  final double linkDistance;
  final double linkOpacity;
  final double speed;

  /// 不传则用当前主题的主强调色。
  final Color? color;

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late List<_P> _points;
  final math.Random _rnd = math.Random(20261030);
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _points = const [];
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ticker.addListener(_step);
  }

  void _step() {
    if (_size == Size.zero || _points.isEmpty) return;
    for (final p in _points) {
      p.x += p.vx * widget.speed;
      p.y += p.vy * widget.speed;
      p.phase += 0.012;
      if (p.x < -20) p.x = _size.width + 20;
      if (p.x > _size.width + 20) p.x = -20;
      if (p.y < -20) p.y = _size.height + 20;
      if (p.y > _size.height + 20) p.y = -20;
    }
    setState(() {});
  }

  void _ensure(Size size) {
    if (size == _size && _points.isNotEmpty) return;
    _size = size;
    _points = List.generate(widget.count, (_) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final v = 0.4 + _rnd.nextDouble() * 0.8;
      return _P(
        x: _rnd.nextDouble() * size.width,
        y: _rnd.nextDouble() * size.height,
        vx: math.cos(a) * v,
        vy: math.sin(a) * v,
        r: 0.9 + _rnd.nextDouble() * 1.6,
        phase: _rnd.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _ticker.removeListener(_step);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (!p.particles) return const SizedBox.shrink();
    final color = widget.color ?? p.accent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensure(size);
        return IgnorePointer(
          child: CustomPaint(
            size: size,
            painter: _ParticlePainter(
              points: _points,
              linkDistance: widget.linkDistance,
              linkOpacity: widget.linkOpacity,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class _P {
  _P({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.phase,
  });

  double x;
  double y;
  double vx;
  double vy;
  final double r;
  double phase;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.points,
    required this.linkDistance,
    required this.linkOpacity,
    required this.color,
  });

  final List<_P> points;
  final double linkDistance;
  final double linkOpacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final maxDist2 = linkDistance * linkDistance;

    // 连线先画，粒子后画 —— 否则线会盖在光点上，显得脏。
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      for (var j = i + 1; j < points.length; j++) {
        final b = points[j];
        final dx = a.x - b.x;
        final dy = a.y - b.y;
        final d2 = dx * dx + dy * dy;
        if (d2 > maxDist2) continue;
        final t = 1 - d2 / maxDist2; // 越近越亮
        final paint = Paint()
          ..color = color.withValues(alpha: linkOpacity * t)
          ..strokeWidth = 0.7;
        canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), paint);
      }
    }

    for (final p in points) {
      final breath = 0.06 + (math.sin(p.phase) + 1) / 2 * 0.08; // 0.06~0.14
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.r,
        Paint()..color = color.withValues(alpha: breath),
      );
      // 外圈柔光，只给一点点，避免变成萤火虫
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.r * 3,
        Paint()
          ..color = color.withValues(alpha: breath * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

/// 一次性爆发：内核粒子 + 外环冲击波。
///
/// 触发时机只有两个：金额落定（进钱）、下拉刷新。不要给它加更多入口，
/// 每多一个入口，这个效果就从「奖励」降级成「噪音」。
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    this.count = 90,
    this.radius = 220,
    this.color,
    this.duration = const Duration(milliseconds: 1200),
    this.onDone,
  });

  final int count;
  final double radius;

  /// 不传则用当前主题的盈利色。
  final Color? color;
  final Duration duration;
  final VoidCallback? onDone;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late List<_B> _bits;
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _bits = List.generate(widget.count, (_) {
      final a = _rnd.nextDouble() * math.pi * 2;
      final speed = 0.35 + _rnd.nextDouble() * 0.65;
      return _B(
        angle: a,
        speed: speed,
        size: 1.2 + _rnd.nextDouble() * 2.4,
        // 越快的粒子越小、越淡，视觉上更像「散开」而不是「喷射」
        fade: 0.35 + _rnd.nextDouble() * 0.65,
      );
    });
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone?.call();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.palette.profit;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _BurstPainter(
            t: _c.value,
            bits: _bits,
            radius: widget.radius,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _B {
  _B({
    required this.angle,
    required this.speed,
    required this.size,
    required this.fade,
  });

  final double angle;
  final double speed;
  final double size;
  final double fade;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.t,
    required this.bits,
    required this.radius,
    required this.color,
  });

  final double t;
  final List<_B> bits;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 外环冲击波：前 300ms 扩散到 1.15 倍，随后淡出
    final ringT = (t / 0.25).clamp(0.0, 1.0);
    if (t < 0.55) {
      final ringR = radius * (0.2 + ringT * 0.95);
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - ringT) + 0.4
          ..color = color.withValues(alpha: (1 - t / 0.55) * 0.45),
      );
    }

    // 内核：easeOut 扩散，末期淡出
    final eased = 1 - math.pow(1 - t, 3).toDouble();
    final alpha = (1 - t).clamp(0.0, 1.0);
    for (final b in bits) {
      final d = radius * b.speed * eased;
      final p = Offset(
        center.dx + math.cos(b.angle) * d,
        center.dy + math.sin(b.angle) * d,
      );
      final sizeNow = b.size * (1 - t * 0.6);
      canvas.drawCircle(
        p,
        sizeNow,
        Paint()..color = color.withValues(alpha: alpha * b.fade),
      );
      canvas.drawCircle(
        p,
        sizeNow * 3.5,
        Paint()
          ..color = color.withValues(alpha: alpha * b.fade * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
