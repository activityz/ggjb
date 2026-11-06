import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/scan_code.dart';

/// seam: 扫码文本 → 记录标识的规范化与格式判定。
///
/// 纯函数，不含相机与数据库；相机解码本身只能在真机验，这里只锁住
/// 「解出来的这串字是什么、算不算本应用的码」。
void main() {
  // 独立来源：UUID v4 的字面量（第 13 位固定 4、第 17 位是 8/9/a/b）。
  const validId = '123e4567-e89b-42d3-a456-426614174000';

  group('normalizeScanText', () {
    test('去掉首尾空白、换行与制表符', () {
      expect(normalizeScanText(' \r\n$validId\t\n '), validId);
    });

    test('去掉零宽字符', () {
      expect(normalizeScanText('\u200B$validId\uFEFF'), validId);
    });

    test('空串归一后仍是空串', () {
      expect(normalizeScanText('   '), '');
    });
  });

  group('isItemId', () {
    test('小写 v4 UUID 是合法记录标识', () {
      expect(isItemId(validId), isTrue);
    });

    test('大写 v4 UUID 也是合法记录标识', () {
      expect(isItemId(validId.toUpperCase()), isTrue);
    });

    test('v1 UUID 不是合法记录标识', () {
      expect(isItemId('123e4567-e89b-12d3-a456-426614174000'), isFalse);
    });

    test('空串与普通文本不是合法记录标识', () {
      expect(isItemId(''), isFalse);
      expect(isItemId('hello'), isFalse);
    });
  });

  group('resolveScanText', () {
    test('合法码值解析为命中，并归一成小写', () {
      final r = resolveScanText(' \r\n${validId.toUpperCase()}\n');

      expect(r, isA<ScanHit>());
      expect((r as ScanHit).itemId, validId);
    });

    test('非法码值解析为格式错误，并带回清洗后的原文', () {
      final r = resolveScanText('  hello  ');

      expect(r, isA<ScanMiss>());
      final miss = r as ScanMiss;
      expect(miss.reason, ScanMissReason.malformed);
      expect(miss.raw, 'hello');
    });

    test('空码值算格式错误', () {
      final r = resolveScanText('   ');

      expect(r, isA<ScanMiss>());
      expect((r as ScanMiss).reason, ScanMissReason.malformed);
    });
  });
}
