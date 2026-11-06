import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: WarrantyStatus 与其 TypeConverter —— 库里的文本值契约。
///
/// 断言值全部是字面量（`active` / `none`），不按实现里的枚举顺序重算：
/// 这三个字符串是库与 Excel 共用的对外格式，改动就是破坏兼容。
void main() {
  group('WarrantyStatus 取值', () {
    test('三态齐全，库内文本与中文标签固定', () {
      expect(WarrantyStatus.values.map((e) => e.dbValue), [
        'none',
        'active',
        'expired',
      ]);
      expect(WarrantyStatus.values.map((e) => e.label), [
        '无保修',
        '在保',
        '已过保',
      ]);
    });
  });

  group('WarrantyStatusConverter', () {
    const converter = WarrantyStatusConverter();

    test('三种状态往返不丢信息', () {
      for (final value in WarrantyStatus.values) {
        expect(converter.fromSql(converter.toSql(value)), value);
      }
    });

    test('toSql 写的是 dbValue 而不是标签', () {
      expect(converter.toSql(WarrantyStatus.active), 'active');
      expect(converter.toSql(WarrantyStatus.expired), 'expired');
      expect(converter.toSql(WarrantyStatus.none), 'none');
    });

    test('不认识的文本回落为无保修，不抛异常', () {
      expect(converter.fromSql('unknown'), WarrantyStatus.none);
      expect(converter.fromSql(''), WarrantyStatus.none);
      expect(converter.fromSql('在保'), WarrantyStatus.none);
    });
  });
}
