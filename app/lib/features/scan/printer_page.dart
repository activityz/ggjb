import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'printer_channel.dart';
import 'printer_controller.dart';

/// 标签打印机管理页：扫描、连接、断开、校准走纸。
///
/// 打印机地址不持久化（见 design D4），所以这页顶部会明确写「重启后要重连」。
class PrinterPage extends ConsumerWidget {
  const PrinterPage({super.key});

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on PrinterException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _calibrate(
    BuildContext context,
    PrinterController controller,
  ) async {
    await _guard(
      context,
      () => controller.printLabel(utf8.encode('GAPDETECT\r\n')),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已发送校准指令，打印机会走一张空白标签')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(printerControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('标签打印机')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final connected = controller.connected;
          final isWindows =
              !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
          final busy = controller.status == PrinterStatus.scanning;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(
                    connected == null ? Icons.print_disabled : Icons.print,
                  ),
                  title: Text(
                    connected == null ? '未连接打印机' : '已连接：${connected.name}',
                  ),
                  subtitle: Text(
                    controller.error ??
                        (connected == null
                            ? '连接状态只在本次运行内有效，重启后需要重连'
                            : connected.address),
                    maxLines: 3,
                  ),
                  trailing: connected == null
                      ? null
                      : TextButton(
                          onPressed: busy
                              ? null
                              : () => controller.disconnect(),
                          child: const Text('断开'),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: busy ? null : () => controller.scan(),
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(
                  busy
                      ? '扫描中…'
                      : (isWindows ? '刷新已配对设备' : '扫描附近打印机'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: connected == null
                    ? null
                    : () => _calibrate(context, controller),
                icon: const Icon(Icons.straighten),
                label: const Text('校准走纸'),
              ),
              const Divider(height: 32),
              Text('附近的设备', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (controller.devices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    isWindows
                        ? '没有已配对的设备。先到 Windows「设置 → 蓝牙和其他设备」配对打印机，再回来点刷新。'
                        : '还没扫描到设备。打印机开机、靠近手机，再点一次扫描。',
                  ),
                )
              else
                for (final device in controller.devices)
                  ListTile(
                    leading: const Icon(Icons.print_outlined),
                    title: Text(device.name),
                    subtitle: Text(device.address),
                    trailing: device.address == connected?.address
                        ? const Icon(Icons.check)
                        : const Text('连接'),
                    onTap: busy
                        ? null
                        : () => _guard(
                            context,
                            () => controller.connect(device),
                          ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
