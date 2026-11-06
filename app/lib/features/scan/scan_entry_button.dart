import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/scan_code.dart';
import '../item_detail/item_detail_page.dart';
import 'scan_page.dart';

/// 打开取景页并等它回传原始码值；用户取消时返回 null。
typedef ScanLauncher = Future<String?> Function(BuildContext context);

Future<String?> pushScanPage(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(builder: (_) => const ScanPage()),
  );
}

/// 取景器注入点。
///
/// widget 测试里换成「直接返回一个码值」，就不用拉起真相机。
final scanLauncherProvider = Provider<ScanLauncher>((ref) => pushScanPage);

/// 顶栏的扫码入口。
///
/// 拆成独立组件而不是塞进 `home_shell` 的一个方法：这样能在测试里单独
/// pump 它，不必拉起同步控制器与数据库表监听。
///
/// 平台判定也在这里做：没有摄像头能力的平台直接不渲染（Windows 上
/// 不会出现「按钮在但点了没反应」的假入口）。
class ScanEntryButton extends ConsumerWidget {
  const ScanEntryButton({super.key});

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final read = ref.read(scanLauncherProvider);
    final raw = await read(context);
    if (!context.mounted || raw == null) return;

    final result = await ref.read(itemRepositoryProvider).resolveScan(raw);
    if (!context.mounted) return;

    switch (result) {
      case ScanHit(:final itemId):
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ItemDetailPage(itemId: itemId),
          ),
        );
      case ScanMiss():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没找到这一笔')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(scanAvailableProvider)) return const SizedBox.shrink();

    return IconButton(
      tooltip: '扫码',
      onPressed: () => _scan(context, ref),
      icon: const Icon(Icons.qr_code_scanner),
    );
  }
}
