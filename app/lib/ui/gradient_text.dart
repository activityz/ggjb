import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/palette.dart';
import '../app/theme.dart';

/// 渐变文字，可带外发光。
///
/// 用法限定：**只给金额用**。满屏渐变标题会让「重点在哪」这个问题失去答案，
/// 一屏最多两处渐变（净到手 + 当前最关心的那个数）。
///
/// [glow] 是发光半径，0 表示不发光。发光靠「同一段文字模糊后垫在底下」实现，
/// 比 [Shadow] 更贴合字形轮廓。亮色下尽量不要开发光 —— 白底上会糊成一摊脏影。
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient,
    this.glow = 0,
    this.glowColor,
    this.textAlign,
    this.maxLines = 1,
  });

  final String text;
  final TextStyle? style;

  /// 不传则用当前主题的主强调渐变。
  final Gradient? gradient;
  final double glow;
  final Color? glowColor;
  final TextAlign? textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = (style ?? Theme.of(context).textTheme.headlineMedium)!.copyWith(
      color: Colors.white,
      fontFeatures: kTabularFigures,
    );
    final shader = gradient ?? accentGradient(p);

    final content = Text(
      text,
      style: base,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        if (glow > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: glow, sigmaY: glow),
                child: Text(
                  text,
                  style: base.copyWith(
                    color: glowColor ?? p.accent,
                    shadows: null,
                  ),
                  textAlign: textAlign,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: shader.createShader,
          child: content,
        ),
      ],
    );
  }
}

/// 主强调渐变：青绿 → 天蓝（暗）／ 深青蓝 → 中蓝（亮）。
LinearGradient accentGradient(AppPalette p) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        p.accent,
        Color.lerp(p.accent, p.textPrimary, 0.35)!,
      ],
    );

/// 盈利渐变。
LinearGradient profitGradient(AppPalette p) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        p.profit,
        Color.lerp(p.profit, p.textPrimary, 0.35)!,
      ],
    );

/// 亏损渐变。
LinearGradient lossGradient(AppPalette p) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        p.loss,
        Color.lerp(p.loss, p.textPrimary, 0.35)!,
      ],
    );

/// 按金额正负取渐变，零用主强调。
LinearGradient moneyGradient(int cents, AppPalette p) {
  if (cents > 0) return profitGradient(p);
  if (cents < 0) return lossGradient(p);
  return accentGradient(p);
}
