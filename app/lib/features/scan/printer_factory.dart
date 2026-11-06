import 'dart:io' show Platform;

import 'printer_channel.dart';
import 'windows_printer.dart';

/// 按平台挑实现。
///
/// 这里用 `Platform` 而不是 `defaultTargetPlatform`：通道选择是真正的
/// 平台分派（要加载对应平台的库），不是给测试留的开关。测试用
/// provider override 注入假实现。
PrinterChannel createPrinterChannel() {
  if (Platform.isAndroid) return const AndroidPrinterChannel();
  if (Platform.isWindows) return WindowsPrinterChannel();
  return const UnsupportedPrinterChannel();
}
