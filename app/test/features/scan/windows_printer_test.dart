import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/features/scan/windows_printer.dart';

/// seam: Windows 蓝牙打印里能纯算的那部分。
///
/// 地址解析与端口回退都是纯函数，可以在桌面宿主上断言；真正的 socket
/// 建链与 send 只能真机验。
void main() {
  group('parseBluetoothAddress', () {
    test('冒号分隔的地址解析成 48 bit 整数', () {
      expect(parseBluetoothAddress('AA:BB:CC:DD:EE:FF'), 0xAABBCCDDEEFF);
    });

    test('小写地址同样解析', () {
      expect(parseBluetoothAddress('aa:bb:cc:dd:ee:ff'), 0xAABBCCDDEEFF);
    });

    test('连字符分隔也认', () {
      expect(parseBluetoothAddress('AA-BB-CC-DD-EE-FF'), 0xAABBCCDDEEFF);
    });

    test('位数不对直接报参数错误，不返回半个地址', () {
      expect(() => parseBluetoothAddress('AA:BB:CC'), throwsArgumentError);
      expect(() => parseBluetoothAddress('nope'), throwsArgumentError);
    });
  });

  group('nextRfcommPort', () {
    test('按 1 → 2 → 3 → 4 依次给出', () {
      final ports = [for (var i = 0; i < 4; i++) nextRfcommPort(i)];

      expect(ports, [1, 2, 3, 4]);
    });

    test('四次之后没有更多端口可试', () {
      expect(nextRfcommPort(4), isNull);
    });
  });
}
