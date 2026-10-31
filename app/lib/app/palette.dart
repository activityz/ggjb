import 'package:flutter/material.dart';

/// 亮 / 暗两套皮肤共用的调色板。
///
/// 为什么不用 [ColorScheme] 就够了：Material 的 ColorScheme 里没有
/// 「卡片描边起止色」「顶部高光」「是否走玻璃」这类语义，而这些正是
/// 这套 UI 的骨架。硬编码色常量会让亮色模式变成白卡配白字，
/// 所以全部收进 [AppPalette]，由 `Theme.of(context).extension<AppPalette>()`
/// 取 —— 谁想写字面色值，都得先过 `context.palette`。
///
/// 语义色也放进来而不是写常量：`#34D399` 这种亮绿在深底上是对的，
/// 放白底上对比度只有 1.9，看不清。亮色必须用深一档的同色相。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.pageTop,
    required this.pageBottom,
    required this.cardFill,
    required this.cardBorderStart,
    required this.cardBorderEnd,
    required this.highlight,
    required this.inputFill,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.profit,
    required this.loss,
    required this.receivable,
    required this.warning,
    required this.glass,
    required this.particles,
    required this.heroGlow,
  });

  /// 页面底渐变两端。
  final Color pageTop;
  final Color pageBottom;

  /// 卡片底色。暗色是 6% 白（玻璃），亮色是纯白（实心）。
  final Color cardFill;

  /// 卡片描边渐变起止。
  final Color cardBorderStart;
  final Color cardBorderEnd;

  /// 卡片顶部 1px 高光。亮色下为透明 —— 白卡上加高光只会显脏。
  final Color highlight;

  /// 输入框底色，比卡片深/浅一档，才有边界感。
  final Color inputFill;

  final Color divider;

  final Color textPrimary;
  final Color textSecondary;

  /// 主强调色。暗色用亮青绿，亮色用深青蓝（浅底上青绿字对比不够）。
  final Color accent;

  /// 画在主强调色之上的文字/图标色。
  final Color onAccent;

  /// 赚钱
  final Color profit;

  /// 亏钱
  final Color loss;

  /// 待收货款：货已卖出、钱还在买家/平台上。
  final Color receivable;

  /// 在途占用：手上压着的钱。与 [receivable] 拉开色相，免得看板混成一个色。
  final Color warning;

  /// 是否走玻璃拟态（[BackdropFilter] 模糊 + 光斑）。
  final bool glass;

  /// 是否铺环境粒子。
  final bool particles;

  /// 看板大卡背后那团径向光晕的强度。亮色下要压到很淡，
  /// 否则会在白卡上晕出一摊脏印。
  final double heroGlow;

  /// 暗色：现有深色玻璃皮肤，值全部是上线过的，别随手改。
  static const AppPalette dark = AppPalette(
    pageTop: Color(0xFF0A0E14),
    pageBottom: Color(0xFF121820),
    cardFill: Color(0x0FFFFFFF),
    cardBorderStart: Color(0x1FFFFFFF),
    cardBorderEnd: Color(0x08FFFFFF),
    highlight: Color(0x28FFFFFF),
    inputFill: Color(0x0DFFFFFF),
    divider: Color(0x14FFFFFF),
    textPrimary: Color(0xFFE6EDF3),
    textSecondary: Color(0xFF8B98A5),
    accent: Color(0xFF5EEAD4),
    onAccent: Color(0xFF04211C),
    profit: Color(0xFF34D399),
    loss: Color(0xFFFB7185),
    receivable: Color(0xFFFBBF24),
    warning: Color(0xFFF59E0B),
    glass: true,
    particles: true,
    heroGlow: 0.20,
  );

  /// 亮色：实心白卡 + 柔和阴影，无玻璃、无粒子。
  ///
  /// 底色带一点冷调（不是纯白），纯白底配白卡会看不出卡片边界；
  /// 正文不用纯黑，纯黑在浅底上发硬。
  static const AppPalette light = AppPalette(
    pageTop: Color(0xFFF7F9FB),
    pageBottom: Color(0xFFEDF1F5),
    cardFill: Color(0xFFFFFFFF),
    cardBorderStart: Color(0x14000000),
    cardBorderEnd: Color(0x08000000),
    highlight: Color(0x00000000),
    inputFill: Color(0xFFF1F4F7),
    divider: Color(0x14000000),
    textPrimary: Color(0xFF11161C),
    textSecondary: Color(0xFF5B6672),
    accent: Color(0xFF2C6E8F),
    onAccent: Color(0xFFFFFFFF),
    profit: Color(0xFF0F7B4D),
    loss: Color(0xFFC0392B),
    receivable: Color(0xFFA16207),
    warning: Color(0xFFB45309),
    glass: false,
    particles: false,
    heroGlow: 0.07,
  );

  LinearGradient get pageGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[pageTop, pageBottom],
      );

  /// 卡片阴影。只有亮色用（玻璃层已经自带深度感，不需要阴影）。
  List<BoxShadow> get cardShadow => glass
      ? const <BoxShadow>[]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ];

  @override
  AppPalette copyWith({
    Color? pageTop,
    Color? pageBottom,
    Color? cardFill,
    Color? cardBorderStart,
    Color? cardBorderEnd,
    Color? highlight,
    Color? inputFill,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? onAccent,
    Color? profit,
    Color? loss,
    Color? receivable,
    Color? warning,
    bool? glass,
    bool? particles,
    double? heroGlow,
  }) {
    return AppPalette(
      pageTop: pageTop ?? this.pageTop,
      pageBottom: pageBottom ?? this.pageBottom,
      cardFill: cardFill ?? this.cardFill,
      cardBorderStart: cardBorderStart ?? this.cardBorderStart,
      cardBorderEnd: cardBorderEnd ?? this.cardBorderEnd,
      highlight: highlight ?? this.highlight,
      inputFill: inputFill ?? this.inputFill,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      profit: profit ?? this.profit,
      loss: loss ?? this.loss,
      receivable: receivable ?? this.receivable,
      warning: warning ?? this.warning,
      glass: glass ?? this.glass,
      particles: particles ?? this.particles,
      heroGlow: heroGlow ?? this.heroGlow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      pageTop: Color.lerp(pageTop, other.pageTop, t)!,
      pageBottom: Color.lerp(pageBottom, other.pageBottom, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      cardBorderStart: Color.lerp(cardBorderStart, other.cardBorderStart, t)!,
      cardBorderEnd: Color.lerp(cardBorderEnd, other.cardBorderEnd, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      receivable: Color.lerp(receivable, other.receivable, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      glass: t < 0.5 ? glass : other.glass,
      particles: t < 0.5 ? particles : other.particles,
      heroGlow: heroGlow + (other.heroGlow - heroGlow) * t,
    );
  }
}

/// 取当前调色板。所有页面都从这里拿颜色，不再引用任何 `kXxx` 常量。
extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
