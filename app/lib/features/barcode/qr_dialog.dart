import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../scan/printer_channel.dart';
import '../scan/printer_controller.dart';
import '../scan/printer_page.dart';
import 'label_commands.dart';
import 'qr_export.dart';

/// 记录二维码弹窗：详情页与列表页共用。
///
/// 三条硬约束（写在 openspec 的 design.md 里）：
/// 1. **白底不可跟随皮肤**：深色主题下反色会让多数扫码器读不出来；
/// 2. **静区不能省**：四周留白约 4 个模块；
/// 3. **导出走截图**：`RepaintBoundary` 保证"看到的就是导出的"。
///
/// 打印则相反：不走截图，直接把 TSPL 指令写给蓝牙打印机（指令不到 300 字节，
/// 且质量取决于打印机自己的点阵字库）。
class QrDialog extends ConsumerStatefulWidget {
  const QrDialog({super.key, required this.itemId, this.title});

  /// 码值就是记录主键：编辑不改主键，所以二维码天然不变。
  final String itemId;

  /// 记录标题，打印到标签上便于人工确认。
  final String? title;

  @override
  ConsumerState<QrDialog> createState() => _QrDialogState();
}

/// 导出画布的宽高比：40 × 30mm 标签。
const double qrCanvasWidth = 360;
const double qrCanvasHeight = 270;

class _QrDialogState extends ConsumerState<QrDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _busy = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final bytes = await renderBoundaryPng(_boundaryKey, pixelRatio: 4);
      if (bytes == null) throw StateError('截图失败');

      final dir = await getTemporaryDirectory();
      final name = widget.itemId.replaceAll('-', '').substring(0, 8);
      final file = File('${dir.path}/ggjb-qr-$name.png');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: '搞个机吧 · 二维码'),
      );
    } catch (_) {
      if (mounted) _toast('导出失败，稍后再试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    final controller = ref.read(printerControllerProvider);

    if (controller.connected == null) {
      _toast('先连接打印机，再回来点打印');
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const PrinterPage()),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await controller.printLabel(
        buildLabelCommands(code: widget.itemId, title: widget.title ?? ''),
      );
      if (mounted) _toast('已发送到打印机');
    } on PrinterException catch (e) {
      if (mounted) _toast('打印失败：${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final printAvailable = ref.watch(printAvailableProvider);
    final title = widget.title?.trim();

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              width: qrCanvasWidth,
              height: qrCanvasHeight,
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: QrImageView(
                      data: widget.itemId,
                      version: QrVersions.auto,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (title != null && title.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    widget.itemId.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.black54,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (printAvailable)
          OutlinedButton.icon(
            onPressed: _busy ? null : _print,
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('打印'),
          ),
        FilledButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.ios_share, size: 18),
          label: const Text('导出 PNG'),
        ),
      ],
    );
  }
}
