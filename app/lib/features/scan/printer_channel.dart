import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

/// 一台可用打印机。
class PrinterDevice {
  const PrinterDevice({required this.name, required this.address});

  final String name;
  final String address;
}

/// 打印相关失败。
class PrinterException implements Exception {
  const PrinterException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PrinterException($code): $message';
}

/// 打印通道接口。
///
/// Android 走原生 MethodChannel（经典蓝牙 SPP），Windows 走纯 Dart FFI，
/// 其它平台给一个只会抛错的实现——上层（弹窗、状态机、指令生成）完全
/// 不关心底下是哪条路。
abstract class PrinterChannel {
  Future<List<PrinterDevice>> scan();
  Future<void> connect(String address);
  Future<void> disconnect();
  Future<bool> isConnected();
  Future<void> write(List<int> bytes);
}

/// 当前平台能不能蓝牙打印。
///
/// 用 `defaultTargetPlatform` 而不是 `Platform.isX`：widget 测试跑在桌面
/// 宿主上，硬编码平台会让「某个平台应该支持」的规格没法测。
bool get printerPlatformSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.windows;
}

/// Android：走 `ggjb/printer` 原生通道。
class AndroidPrinterChannel implements PrinterChannel {
  const AndroidPrinterChannel([
    this._channel = const MethodChannel('ggjb/printer'),
  ]);

  final MethodChannel _channel;

  @override
  Future<List<PrinterDevice>> scan() async {
    final raw = await _invoke<List<dynamic>>('scan');
    if (raw == null) return const [];

    return raw
        .whereType<Map<Object?, Object?>>()
        .map(
          (m) => PrinterDevice(
            name: '${m['name'] ?? '未命名设备'}',
            address: '${m['address'] ?? ''}',
          ),
        )
        .where((d) => d.address.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<void> connect(String address) async {
    await _invoke<bool>('connect', {'address': address});
  }

  @override
  Future<void> disconnect() async {
    await _invoke<bool>('disconnect');
  }

  @override
  Future<bool> isConnected() async {
    final value = await _invoke<bool>('isConnected');
    return value ?? false;
  }

  @override
  Future<void> write(List<int> bytes) async {
    await _invoke<bool>('write', {'bytes': bytes});
  }

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw PrinterException(e.code, e.message ?? e.code);
    } on MissingPluginException {
      throw const PrinterException('unsupported', '当前平台不支持蓝牙打印');
    }
  }
}

/// 其它平台：明确不支持，而不是静默失败。
class UnsupportedPrinterChannel implements PrinterChannel {
  const UnsupportedPrinterChannel();

  static const _error = PrinterException('unsupported', '当前平台不支持蓝牙打印');

  @override
  Future<List<PrinterDevice>> scan() async => throw _error;

  @override
  Future<void> connect(String address) async => throw _error;

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> isConnected() async => false;

  @override
  Future<void> write(List<int> bytes) async => throw _error;
}
