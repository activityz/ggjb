import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';

/// 两套皮肤：亮色（默认）/ 暗色。
///
/// 亮色走「实心白卡 + 柔和阴影」，暗色走「玻璃拟态 + 粒子」。
/// 不做成同一套材质换个色：玻璃的半透明白在浅底上会发灰，
/// 粒子在黑字背景上又基本看不见，两套各按各的材质来才都好看。
///
/// 所有颜色从 [AppPalette] 取，页面里不许写字面色值。
///
/// 所有金额文字必须 `tabularFigures`，否则数字滚动时字宽跳变、整行抖动。

/// 金额文字统一带等宽数字。
const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];

/// 兼容旧调用点的语义色别名 —— **不要在页面里用**，用 `context.palette.xxx`。
/// 保留这几个是为了让语义名（profit / loss）在代码里仍然可读。
const Color kAccent = Color(0xFF5EEAD4);
const Color kProfitColor = Color(0xFF34D399);
const Color kLossColor = Color(0xFFFB7185);
const Color kReceivableColor = Color(0xFFFBBF24);
const Color kWarningColor = Color(0xFFF59E0B);

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final p = isDark ? AppPalette.dark : AppPalette.light;

  final scheme = isDark
      ? ColorScheme.dark(
          primary: p.accent,
          onPrimary: p.onAccent,
          secondary: p.accent,
          onSecondary: p.onAccent,
          surface: p.pageTop,
          onSurface: p.textPrimary,
          onSurfaceVariant: p.textSecondary,
          error: p.loss,
          onError: const Color(0xFF2A0A0E),
          outlineVariant: const Color(0x1FFFFFFF),
        )
      : ColorScheme.light(
          primary: p.accent,
          onPrimary: p.onAccent,
          secondary: p.accent,
          onSecondary: p.onAccent,
          surface: p.cardFill,
          onSurface: p.textPrimary,
          onSurfaceVariant: p.textSecondary,
          error: p.loss,
          onError: const Color(0xFFFFFFFF),
          outlineVariant: const Color(0x14000000),
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: <ThemeExtension<dynamic>>[p],
    scaffoldBackgroundColor: p.pageTop,
    canvasColor: p.pageBottom,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
        TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
      },
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: p.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.cardBorderStart),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: p.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.cardBorderStart),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.cardBorderStart),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      labelStyle: TextStyle(color: p.textSecondary),
      hintStyle: TextStyle(
        color: p.textSecondary.withValues(alpha: 0.6),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: p.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xE60D131A) : p.cardFill,
      indicatorColor: p.accent.withValues(alpha: isDark ? 0.12 : 0.14),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? p.accent
              : p.textSecondary,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isDark ? const Color(0xE60D131A) : p.cardFill,
      indicatorColor: p.accent.withValues(alpha: isDark ? 0.12 : 0.14),
      selectedLabelTextStyle: TextStyle(color: p.accent, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(
        color: p.textSecondary,
        fontSize: 12,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
      elevation: 0,
      highlightElevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: p.divider,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.textSecondary,
      textColor: p.textPrimary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1B2430) : const Color(0xFF23282F),
      contentTextStyle: const TextStyle(color: Color(0xFFF2F5F8)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? const Color(0xFF141B24) : p.cardFill,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.cardBorderStart),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.accent,
      unselectedLabelColor: p.textSecondary,
      indicatorColor: p.accent,
      dividerColor: Colors.transparent,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: p.textPrimary),
      bodyMedium: TextStyle(color: p.textPrimary),
      bodySmall: TextStyle(color: p.textSecondary),
      labelSmall: TextStyle(color: p.textSecondary),
    ),
  );
}

/// 金额着色：正数绿、负数红、零用次级色。
Color moneyColor(int cents, AppPalette p) {
  if (cents > 0) return p.profit;
  if (cents < 0) return p.loss;
  return p.textSecondary;
}

/// 页面转场：淡入 + 轻微上滑，比默认的左右推入安静。
///
/// 只做透明度与 3% 位移，不做缩放 —— 缩放会看到边缘发虚。
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
