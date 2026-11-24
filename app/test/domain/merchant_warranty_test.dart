import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/enums.dart';
import 'package:ggjb/domain/merchant_warranty.dart';

/// seam: 商家保修的默认到期日与「卖出必填」判据 —— 两个纯函数。
///
/// 断言值来自规格里的 worked example（design D6 与 spec 的 scenario），
/// 不按实现重算：`2029-02-28` 是「2028-02-29 加一年」这个事实，
/// 不是代码用同样的分支推出来的结果。
void main() {
  group('addOneYear', () {
    test('普通日期加一年，月日不变', () {
      expect(addOneYear(DateTime(2026, 11, 24)), DateTime(2027, 11, 24));
    });

    test('闰日加一年落到平年的当月最后一天', () {
      expect(addOneYear(DateTime(2028, 2, 29)), DateTime(2029, 2, 28));
    });

    test('年末最后一天加一年', () {
      expect(addOneYear(DateTime(2026, 12, 31)), DateTime(2027, 12, 31));
    });
  });

  group('merchantWarrantyError', () {
    final start = DateTime(2026, 11, 24);
    final end = DateTime(2027, 11, 24);

    test('已卖出且两个日期齐全：通过', () {
      expect(merchantWarrantyError(ItemStatus.sold, start, end), isNull);
    });

    test('已到账且两个日期齐全：通过', () {
      expect(merchantWarrantyError(ItemStatus.completed, start, end), isNull);
    });

    test('已卖出但缺开始日：提示缺开始', () {
      final message = merchantWarrantyError(ItemStatus.sold, null, end);
      expect(message, isNotNull);
      expect(message, contains('开始'));
    });

    test('已卖出但缺到期日：提示缺到期', () {
      final message = merchantWarrantyError(ItemStatus.sold, start, null);
      expect(message, isNotNull);
      expect(message, contains('到期'));
    });

    test('已卖出且两个都缺：仍拒绝，并点明是商家保修', () {
      final message = merchantWarrantyError(ItemStatus.sold, null, null);
      expect(message, isNotNull);
      expect(message, contains('商家保修'));
    });

    test('在库不要求填商家保修', () {
      expect(merchantWarrantyError(ItemStatus.inStock, null, null), isNull);
    });

    test('已上架不要求填商家保修', () {
      expect(merchantWarrantyError(ItemStatus.listed, null, null), isNull);
    });

    test('退货与报废不要求填商家保修', () {
      expect(merchantWarrantyError(ItemStatus.returned, null, null), isNull);
      expect(merchantWarrantyError(ItemStatus.scrapped, null, null), isNull);
    });
  });
}
