
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/features/barcode/qr_export.dart';

/// seam: 把屏幕上已渲染的二维码区域截成 PNG 字节。
///
/// 不测"分享到哪"（那是平台通道），只测"截出来的字节是不是一张合法 PNG"。
void main() {
  testWidgets('渲染区域的截图是合法 PNG 且非空', (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: const SizedBox(
              width: 120,
              height: 90,
              child: ColoredBox(color: Colors.white),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final bytes = await tester.runAsync(
      () => renderBoundaryPng(boundaryKey, pixelRatio: 2),
    );

    expect(bytes, isNotNull);
    final data = bytes!;
    expect(data.length, greaterThan(8));
    // PNG 文件头：89 50 4E 47 0D 0A 1A 0A
    expect(
      data.sublist(0, 8),
      <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    );
  });

  testWidgets('按 pixelRatio 放大后像素尺寸跟着变', (tester) async {
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: const SizedBox(
              width: 100,
              height: 100,
              child: ColoredBox(color: Colors.white),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final image = await tester.runAsync(
      () => renderBoundaryImage(boundaryKey, pixelRatio: 3),
    );

    expect(image, isNotNull);
    expect(image!.width, 300);
    expect(image.height, 300);
  });
}
