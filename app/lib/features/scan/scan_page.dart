import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scan_cooldown.dart';

/// 扫码取景页。
///
/// 只干一件事：拿到第一张 QR 的原文就 pop 回去。定位、跳转、提示都在
/// 调用方（`home_shell`），这样相机与业务之间只有一条 `String` 流动。
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final ScanCooldown _cooldown = ScanCooldown();
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      if (!_cooldown.accept(raw)) continue;
      _handled = true;
      Navigator.of(context).pop(raw);
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫码')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              final denied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        denied ? Icons.no_photography_outlined : Icons.error_outline,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        denied
                            ? '没有相机权限\n请到系统设置里允许本应用使用相机'
                            : '相机打不开：${error.errorCode.name}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // 取景提示：只扫本应用的二维码，别的码不认。
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    '对准记录上的二维码',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
