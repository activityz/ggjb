import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/theme.dart';
import 'package:ggjb/ui/glass_card.dart';

/// seam: GlassCard 的手势层 —— 没有 onTap/onLongPress 时必须对点击透明。
///
/// 曾经它是无条件装 GestureDetector 的：只要注册了 onTapDown/onTapUp，
/// 就会进手势竞技场，而它在卡片内侧、比外层先赢，导致套在外面的
/// GestureDetector / TapScale 永远收不到点击（看板五张卡全部点不动）。
void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: Center(child: card)),
      ),
    );
  }

  testWidgets('没有 onTap 的 GlassCard 不抢外层点击', (tester) async {
    var outerTaps = 0;
    await pumpCard(
      tester,
      GestureDetector(
        onTap: () => outerTaps++,
        behavior: HitTestBehavior.opaque,
        child: const GlassCard(
          padding: EdgeInsets.all(16),
          child: Text('只是一张卡'),
        ),
      ),
    );

    await tester.tap(find.text('只是一张卡'));
    await tester.pump();

    expect(outerTaps, 1, reason: '外层 onTap 必须收到点击');
  });

  testWidgets('自己带 onTap 的 GlassCard 能把点击交回给调用方', (tester) async {
    var taps = 0;
    await pumpCard(
      tester,
      GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () => taps++,
        child: const Text('能点的卡'),
      ),
    );

    await tester.tap(find.text('能点的卡'));
    await tester.pump();

    expect(taps, 1);
  });
}
