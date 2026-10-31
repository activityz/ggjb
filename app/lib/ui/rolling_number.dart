import 'package:flutter/material.dart';

import '../app/palette.dart';
import '../app/theme.dart';

/// 逐位独立滚动的金额数字。
///
/// 为什么不用整串 [AnimatedSwitcher]：数字从 ¥1,200 变成 ¥1,180 时，
/// 整串换掉会让读者重新从左读到右；逐位滚动时只有真正变化的位在动，
/// 其余位纹丝不动 —— 眼睛一眼就能锁定「哪一位变了」。
///
/// 数值变化时整串还会闪一下亮色（约 0.5 秒衰减），用来在扫一眼看板时
/// 抓住「这个数刚变过」。
class RollingNumber extends StatefulWidget {
  const RollingNumber({
    super.key,
    required this.text,
    this.style,
    this.color,
    this.duration = const Duration(milliseconds: 280),
    this.pulse = true,
  });

  /// 已经格式化好的字符串（含 ¥、逗号、负号）。
  final String text;
  final TextStyle? style;
  final Color? color;
  final Duration duration;

  /// 数字变了要不要闪一下。
  final bool pulse;

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 0,
  );

  @override
  void didUpdateWidget(covariant RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    if (!widget.pulse) return;
    // 从「亮」衰减到「正常」：value 从 1 走回 0。
    _pulse.value = 1;
    _pulse.animateBack(0, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = (widget.style ?? Theme.of(context).textTheme.headlineMedium)!
        .copyWith(
      color: widget.color ?? p.textPrimary,
      fontFeatures: kTabularFigures,
    );

    final chars = widget.text.characters;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        // 往「文字主色」方向提亮/压暗，不改色相 —— 直接换成别的颜色会看不出涨跌。
        // 暗底往白提亮，浅底往黑压暗，否则白底上闪白等于什么也没发生。
        final lit = Color.lerp(
          base.color,
          p.textPrimary,
          _pulse.value * 0.55,
        );
        final style = base.copyWith(color: lit);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            for (final c in chars)
              _Digit(char: c, style: style, duration: widget.duration),
          ],
        );
      },
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit({
    required this.char,
    required this.style,
    required this.duration,
  });

  final String char;
  final TextStyle style;
  final Duration duration;

  bool get _isDigit {
    final c = char.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39;
  }

  @override
  Widget build(BuildContext context) {
    // 非数字（¥、逗号、负号、小数点）不参与动画，直接静态显示，
    // 否则整个金额会像在「翻牌」一样乱跳。
    if (!_isDigit) return Text(char, style: style);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => ClipRect(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.70),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
      // 用「字符本身」当 key：同一位从 3 变 4 才触发动画，没变就不动。
      child: Text(char, key: ValueKey<String>(char), style: style),
    );
  }
}
