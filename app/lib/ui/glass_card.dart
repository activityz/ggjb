import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/palette.dart';

/// 卡片容器，两种材质：
///
/// **暗色（玻璃）**：模糊底 + 渐变描边 + 顶部高光 + 跟随手指的光斑。
/// 层级来源（从下到上）：
/// 1. [BackdropFilter] 模糊背景 —— 让卡「浮」在粒子层之上
/// 2. 6% 白底 —— 压住模糊后的杂色，保证文字对比度
/// 3. 触摸光斑 —— 手指按下去的地方有一团柔光，暗示「这是可交互的」
/// 4. 顶部 1px 高光 —— 玻璃边缘的物理感
/// 5. 内容
///
/// **亮色（实心）**：纯白底 + 极淡描边 + 柔和投影，没有模糊也没有光斑。
/// 玻璃的半透明白在浅底上只会发灰，看不清卡片边界。
///
/// 调用点不用关心用的是哪种材质 —— 只看 `context.palette.glass`。
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blur = 18,
    this.radius = 16,
    this.onTap,
    this.onLongPress,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// 模糊半径（仅玻璃材质生效）。叠 2 层以上的卡不要都设很大，否则整屏发灰。
  final double blur;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 给卡片染一点语义色（如亏损卡微红），默认不染。
  final Color? tint;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  Offset? _glow;

  void _updateGlow(Offset local) {
    setState(() => _glow = local);
  }

  void _clearGlow() {
    if (_glow != null) setState(() => _glow = null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(widget.radius);

    final content = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    if (!p.glass) {
      return _wrapGesture(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.tint == null
                ? p.cardFill
                : Color.alphaBlend(
                    widget.tint!.withValues(alpha: 0.05),
                    p.cardFill,
                  ),
            borderRadius: radius,
            border: Border.all(color: p.cardBorderStart),
            boxShadow: p.cardShadow,
          ),
          child: content,
        ),
      );
    }

    return _wrapGesture(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: widget.blur,
                sigmaY: widget.blur,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.tint == null
                      ? p.cardFill
                      : Color.alphaBlend(
                          widget.tint!.withValues(alpha: 0.06),
                          p.cardFill,
                        ),
                  borderRadius: radius,
                ),
                child: Stack(
                  children: <Widget>[
                    if (_glow != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(
                                  (_glow!.dx / size.width) * 2 - 1,
                                  (_glow!.dy / size.height) * 2 - 1,
                                ),
                                radius: 0.9,
                                colors: <Color>[
                                  p.highlight,
                                  const Color(0x00FFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // 顶部 1px 高光：玻璃的「边缘反射」
                    if (p.highlight.a > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                const Color(0x00FFFFFF),
                                p.highlight,
                                const Color(0x00FFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    content,
                    // 描边画在最上层，避免被内容压住
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            border: Border.all(
                              color: p.cardBorderStart,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wrapGesture({required Widget child}) {
    return GestureDetector(
      onTapDown: (d) => _updateGlow(d.localPosition),
      onTapUp: (_) => _clearGlow(),
      onTapCancel: _clearGlow,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

/// 轻量面板：不做模糊，只用半透明底 + 描边。
///
/// 用在「一屏已经有两层模糊」的地方当第三条腿 —— 再叠 [BackdropFilter]
/// 整屏会糊成一片，层级反而消失。亮色下就是一块更浅的底色。
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 12,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderRadius = BorderRadius.circular(radius);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint == null
            ? p.inputFill
            : Color.alphaBlend(tint!.withValues(alpha: 0.10), p.cardFill),
        borderRadius: borderRadius,
        border: Border.all(color: p.cardBorderEnd, width: 1),
      ),
      child: child,
    );
  }
}
