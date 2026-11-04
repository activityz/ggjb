import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/palette.dart';
import 'package:ggjb/app/theme.dart';

List<Object?> fieldsOf(AppPalette p) => <Object?>[
  p.pageTop,
  p.pageBottom,
  p.cardFill,
  p.cardBorderStart,
  p.cardBorderEnd,
  p.highlight,
  p.inputFill,
  p.divider,
  p.textPrimary,
  p.textSecondary,
  p.accent,
  p.onAccent,
  p.profit,
  p.loss,
  p.receivable,
  p.warning,
  p.glass,
  p.particles,
  p.heroGlow,
];

void main() {
  group('AppPalette', () {
    test('深色用玻璃与粒子，亮色用实心卡', () {
      expect(AppPalette.dark.glass, isTrue);
      expect(AppPalette.dark.particles, isTrue);
      expect(AppPalette.light.glass, isFalse);
      expect(AppPalette.light.particles, isFalse);
      expect(AppPalette.dark.heroGlow, greaterThan(AppPalette.light.heroGlow));
    });

    test('亮色正文比底色暗，深色正文比底色亮', () {
      expect(
        AppPalette.light.textPrimary.computeLuminance(),
        lessThan(AppPalette.light.pageTop.computeLuminance()),
      );
      expect(
        AppPalette.dark.textPrimary.computeLuminance(),
        greaterThan(AppPalette.dark.pageTop.computeLuminance()),
      );
    });

    test('页面渐变就是 pageTop 到 pageBottom', () {
      final gradient = AppPalette.dark.pageGradient;
      expect(gradient.colors, <Color>[
        AppPalette.dark.pageTop,
        AppPalette.dark.pageBottom,
      ]);
      expect(gradient.begin, Alignment.topLeft);
      expect(gradient.end, Alignment.bottomRight);
    });

    test('阴影只给非玻璃的亮色', () {
      expect(AppPalette.dark.cardShadow, isEmpty);
      final shadow = AppPalette.light.cardShadow;
      expect(shadow, hasLength(1));
      expect(shadow.single.blurRadius, 18);
      expect(shadow.single.offset, const Offset(0, 4));
    });

    test('copyWith 只改点名的那一项', () {
      final patched = AppPalette.dark.copyWith(accent: const Color(0xFF123456));
      expect(patched.accent, const Color(0xFF123456));
      final before = fieldsOf(AppPalette.dark);
      final after = fieldsOf(patched);
      for (var i = 0; i < before.length; i++) {
        if (i == 10) continue; // accent
        expect(after[i], before[i], reason: '第 $i 项不该变');
      }
    });

    test('lerp 两端就是两端', () {
      expect(
        fieldsOf(AppPalette.dark.lerp(AppPalette.light, 0)),
        fieldsOf(AppPalette.dark),
      );
      expect(
        fieldsOf(AppPalette.dark.lerp(AppPalette.light, 1)),
        fieldsOf(AppPalette.light),
      );
    });

    test('lerp 中间值的开关按 0.5 切，数值按比例', () {
      final quarter = AppPalette.dark.lerp(AppPalette.light, 0.25);
      expect(quarter.glass, AppPalette.dark.glass);
      expect(quarter.particles, AppPalette.dark.particles);

      final threeQuarters = AppPalette.dark.lerp(AppPalette.light, 0.75);
      expect(threeQuarters.glass, AppPalette.light.glass);
      expect(threeQuarters.particles, AppPalette.light.particles);

      final half = AppPalette.dark.lerp(AppPalette.light, 0.5);
      expect(half.heroGlow, closeTo(0.135, 1e-9));
    });

    test('lerp 到别的扩展类型时原样返回', () {
      expect(
        fieldsOf(AppPalette.dark.lerp(null, 0.5)),
        fieldsOf(AppPalette.dark),
      );
    });
  });

  group('主题', () {
    test('两种亮度都挂上了对应调色板', () {
      expect(
        buildAppTheme(Brightness.dark).extension<AppPalette>(),
        same(AppPalette.dark),
      );
      expect(
        buildAppTheme(Brightness.light).extension<AppPalette>(),
        same(AppPalette.light),
      );
    });

    test('亮度字段与入参一致', () {
      expect(buildAppTheme(Brightness.dark).brightness, Brightness.dark);
      expect(buildAppTheme(Brightness.light).brightness, Brightness.light);
    });

    test('次级文字色走调色板', () {
      final light = buildAppTheme(Brightness.light);
      expect(light.textTheme.labelSmall?.color, AppPalette.light.textSecondary);
    });
  });

  group('moneyColor', () {
    test('正数绿、负数红、零用次级色', () {
      expect(moneyColor(1, AppPalette.light), AppPalette.light.profit);
      expect(moneyColor(-1, AppPalette.light), AppPalette.light.loss);
      expect(moneyColor(0, AppPalette.light), AppPalette.light.textSecondary);
    });

    test('深色亮色各用各的色', () {
      expect(moneyColor(100, AppPalette.dark), AppPalette.dark.profit);
      expect(moneyColor(-100, AppPalette.dark), AppPalette.dark.loss);
    });
  });
}
