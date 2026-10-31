import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/money.dart';

void main() {
  group('Money.tryParseYuan', () {
    test('整数元', () {
      expect(Money.tryParseYuan('12')?.cents, 1200);
      expect(Money.tryParseYuan('0')?.cents, 0);
    });

    test('两位小数', () {
      expect(Money.tryParseYuan('12.34')?.cents, 1234);
      expect(Money.tryParseYuan('12.3')?.cents, 1230);
      expect(Money.tryParseYuan('.5')?.cents, 50);
      expect(Money.tryParseYuan('12.')?.cents, 1200);
    });

    test('超过两位小数按四舍五入', () {
      expect(Money.tryParseYuan('12.345')?.cents, 1235);
      expect(Money.tryParseYuan('12.344')?.cents, 1234);
      expect(Money.tryParseYuan('12.999')?.cents, 1300);
    });

    test('容忍千分位逗号与货币符号与空格', () {
      expect(Money.tryParseYuan('1,234.5')?.cents, 123450);
      expect(Money.tryParseYuan(' ¥ 88 ')?.cents, 8800);
      expect(Money.tryParseYuan('￥1，000')?.cents, 100000);
    });

    test('负数', () {
      expect(Money.tryParseYuan('-5.5')?.cents, -550);
      expect(Money.tryParseYuan('-0.01')?.cents, -1);
    });

    test('全角数字', () {
      expect(Money.tryParseYuan('１２．３４')?.cents, 1234);
    });

    test('非法输入返回 null', () {
      expect(Money.tryParseYuan(''), isNull);
      expect(Money.tryParseYuan('   '), isNull);
      expect(Money.tryParseYuan('abc'), isNull);
      expect(Money.tryParseYuan('12.3.4'), isNull);
      expect(Money.tryParseYuan('-'), isNull);
      expect(Money.tryParseYuan('.'), isNull);
    });

    test('parseYuanOrZero 容错', () {
      expect(Money.parseYuanOrZero('abc').cents, 0);
      expect(Money.parseYuanOrZero('9.9').cents, 990);
    });
  });

  group('Money.toYuanString', () {
    test('整数元省略小数', () {
      expect(const Money(1200).toYuanString(), '¥12');
      expect(const Money(1200).toYuanString(forceDecimals: true), '¥12.00');
    });

    test('有角分显示两位', () {
      expect(const Money(1234).toYuanString(), '¥12.34');
      expect(const Money(1205).toYuanString(), '¥12.05');
    });

    test('千分位', () {
      expect(const Money(123456789).toYuanString(), '¥1,234,567.89');
      expect(const Money(123456789).toYuanString(thousands: false), '¥1234567.89');
    });

    test('负数', () {
      expect(const Money(-1234).toYuanString(), '-¥12.34');
    });

    test('不带符号的纯数字用于回填输入框', () {
      expect(const Money(1234).toPlainString(), '12.34');
      expect(const Money(1200).toPlainString(), '12');
    });
  });

  group('Money 运算', () {
    test('加减与比较', () {
      expect((const Money(100) + const Money(250)).cents, 350);
      expect((const Money(100) - const Money(250)).cents, -150);
      expect(-const Money(100), const Money(-100));
      expect(const Money(100).compareTo(const Money(250)), lessThan(0));
      expect(const Money(100).isZero, isFalse);
      expect(const Money(0).isZero, isTrue);
    });

    test('相等性', () {
      expect(const Money(100), const Money(100));
      expect(const Money(100).hashCode, const Money(100).hashCode);
    });
  });
}
