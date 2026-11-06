import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'printer_channel.dart';
import 'printer_factory.dart';

/// 打印链路的状态。
enum PrinterStatus {
  /// 没连打印机。
  idle,

  /// 正在扫描或正在建链（对 UI 都是「忙」）。
  scanning,

  /// 已连上，可以打印。
  connected,

  /// 上一次操作失败，[PrinterController.error] 有原因。
  failed,
}

/// 打印机连接状态机。
///
/// 只持有「本次运行内」的连接：打印机地址不落库（落库要升 schemaVersion，
/// 见 openspec 的 design D4），重启后需要重连。
class PrinterController extends ChangeNotifier {
  PrinterController(this._channel);

  final PrinterChannel _channel;

  PrinterStatus _status = PrinterStatus.idle;
  List<PrinterDevice> _devices = const [];
  PrinterDevice? _connected;
  String? _error;

  PrinterStatus get status => _status;
  List<PrinterDevice> get devices => _devices;
  PrinterDevice? get connected => _connected;
  String? get error => _error;

  /// 扫描附近设备。扫描期间状态是 [PrinterStatus.scanning]。
  Future<void> scan() async {
    _status = PrinterStatus.scanning;
    _error = null;
    notifyListeners();

    try {
      _devices = await _channel.scan();
      _status = _connected == null ? PrinterStatus.idle : PrinterStatus.connected;
    } on PrinterException catch (e) {
      _status = PrinterStatus.failed;
      _error = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// 连接一台打印机。失败时不保留半开状态。
  Future<void> connect(PrinterDevice device) async {
    _status = PrinterStatus.scanning;
    _error = null;
    notifyListeners();

    try {
      await _channel.connect(device.address);
      _connected = device;
      _status = PrinterStatus.connected;
    } on PrinterException catch (e) {
      _connected = null;
      _status = PrinterStatus.failed;
      _error = e.message;
    } finally {
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel.disconnect();
    } on PrinterException catch (_) {
      // 断开失败不影响本地状态：socket 那头已经不可信了。
    }
    _connected = null;
    _status = PrinterStatus.idle;
    _error = null;
    notifyListeners();
  }

  /// 打印一段指令。
  ///
  /// 没连接时直接抛 [PrinterException]（`not_connected`），不发通道——
  /// 免得原生侧报一个更含糊的错。写失败按断开处理：`socket` 那头发完
  /// 一半就断的情况，留着「已连接」会让用户以为打了但没出纸。
  Future<void> printLabel(List<int> bytes) async {
    if (_connected == null) {
      throw const PrinterException('not_connected', '还没连上打印机');
    }

    try {
      await _channel.write(bytes);
    } on PrinterException catch (e) {
      _connected = null;
      _status = PrinterStatus.failed;
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}

final printerChannelProvider = Provider<PrinterChannel>(
  (ref) => createPrinterChannel(),
);

final printerControllerProvider = Provider<PrinterController>((ref) {
  final controller = PrinterController(ref.watch(printerChannelProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

/// 当前平台能不能蓝牙打印（通道只在 Android 侧实现）。
final printAvailableProvider = Provider<bool>(
  (ref) => printerPlatformSupported,
);
