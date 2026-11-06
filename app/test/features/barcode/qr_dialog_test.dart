import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/features/barcode/qr_dialog.dart';
import 'package:ggjb/features/scan/printer_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// seam: 二维码弹窗的内容与入口可见性。
///
/// 抓住「明文就是主键」「M 容错」「白底」「打印按钮只在有蓝牙能力的平台出现」
/// 「未连接时点打印给提示」。图形里编的到底是什么、打印出来什么效果，只能真机看。
void main() {
  const itemId = '123e4567-e89b-42d3-a456-426614174000';
  const title = 'iPhone 13 128G';

  Future<void> open(
    WidgetTester tester, {
    String? withTitle,
    bool printAvailable = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          printAvailableProvider.overrideWithValue(printAvailable),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: QrDialog(itemId: itemId, title: withTitle),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('展示二维码组件', (tester) async {
    await open(tester);

    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('明文里能看到完整主键，便于人工核对', (tester) async {
    await open(tester);

    expect(find.textContaining(itemId.toUpperCase()), findsWidgets);
  });

  testWidgets('用 M 容错，白底黑码，不跟随深色皮肤', (tester) async {
    await open(tester);

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.M);
    expect(qr.backgroundColor, Colors.white);
  });

  testWidgets('有标题时显示标题，连续贴标签能确认没拿错', (tester) async {
    await open(tester, withTitle: title);

    expect(find.text(title), findsWidgets);
  });

  testWidgets('提供导出 PNG 的入口', (tester) async {
    await open(tester);

    expect(find.text('导出 PNG'), findsOneWidget);
  });

  testWidgets('没有蓝牙打印能力的平台不出现打印按钮', (tester) async {
    await open(tester, printAvailable: false);

    expect(find.text('打印'), findsNothing);
    expect(find.text('导出 PNG'), findsOneWidget);
  });

  testWidgets('有蓝牙打印能力时出现打印按钮', (tester) async {
    await open(tester, printAvailable: true);

    expect(find.text('打印'), findsOneWidget);
  });

  testWidgets('未连接打印机时点打印给提示，不发送指令', (tester) async {
    await open(tester, printAvailable: true);

    await tester.tap(find.text('打印'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('先连接打印机'), findsWidgets);
  });
}
