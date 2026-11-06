import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/features/scan/printer_channel.dart';
import 'package:ggjb/features/scan/printer_controller.dart';

/// seam: 打印连接状态机。
///
/// 通道用假的 MethodChannel handler 顶替：能验「调了什么、状态怎么变」，
/// 验不了真实蓝牙链路（只能真机）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ggjb/printer');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockChannel(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('初始状态是未连接且没有设备', () {
    final controller = PrinterController(const AndroidPrinterChannel());
    addTearDown(controller.dispose);

    expect(controller.status, PrinterStatus.idle);
    expect(controller.devices, isEmpty);
    expect(controller.connected, isNull);
  });

  test('未连接时打印直接失败，不往通道发指令', () async {
    var invoked = false;
    mockChannel((call) async {
      invoked = true;
      return true;
    });

    final controller = PrinterController(const AndroidPrinterChannel());
    addTearDown(controller.dispose);

    await expectLater(
      controller.printLabel(const [1, 2, 3]),
      throwsA(
        isA<PrinterException>().having((e) => e.code, 'code', 'not_connected'),
      ),
    );
    expect(invoked, isFalse);
  });

  test('连接成功后进入已连接状态', () async {
    mockChannel((call) async {
      if (call.method == 'connect') return true;
      if (call.method == 'isConnected') return true;
      return null;
    });

    final controller = PrinterController(const AndroidPrinterChannel());
    addTearDown(controller.dispose);

    await controller.connect(
      const PrinterDevice(name: '标签机', address: 'AA:BB:CC:DD:EE:FF'),
    );

    expect(controller.status, PrinterStatus.connected);
    expect(controller.connected?.address, 'AA:BB:CC:DD:EE:FF');
  });

  test('连接被拒时进入失败状态并带上原因', () async {
    mockChannel((call) async {
      if (call.method == 'connect') {
        throw PlatformException(
          code: 'connect_failed',
          message: '连不上 AA:BB:CC:DD:EE:FF',
        );
      }
      return null;
    });

    final controller = PrinterController(const AndroidPrinterChannel());
    addTearDown(controller.dispose);

    await controller.connect(
      const PrinterDevice(name: '标签机', address: 'AA:BB:CC:DD:EE:FF'),
    );

    expect(controller.status, PrinterStatus.failed);
    expect(controller.error, contains('连不上'));
    expect(controller.connected, isNull);
  });

  test('已连接时打印会把字节发到通道', () async {
    final sent = <int>[];
    mockChannel((call) async {
      if (call.method == 'connect') return true;
      if (call.method == 'write') {
        final bytes = call.arguments as Map<Object?, Object?>;
        sent.addAll((bytes['bytes'] as List).cast<int>());
        return true;
      }
      return null;
    });

    final controller = PrinterController(const AndroidPrinterChannel());
    addTearDown(controller.dispose);

    await controller.connect(
      const PrinterDevice(name: '标签机', address: 'AA:BB:CC:DD:EE:FF'),
    );
    await controller.printLabel(const [65, 66, 67]);

    expect(sent, [65, 66, 67]);
  });
}
