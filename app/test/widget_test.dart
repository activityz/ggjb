import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/enums.dart';

void main() {
  group('ItemStatus', () {
    test('dbValue 与 fromDb 互逆', () {
      for (final status in ItemStatus.values) {
        expect(ItemStatus.fromDb(status.dbValue), status);
      }
    });

    test('只有 sold 与 completed 计入已实现利润', () {
      expect(ItemStatus.sold.isRealized, isTrue);
      expect(ItemStatus.completed.isRealized, isTrue);
      final notRealized = ItemStatus.values.where(
        (s) => s != ItemStatus.sold && s != ItemStatus.completed,
      );
      for (final status in notRealized) {
        expect(status.isRealized, isFalse, reason: '${status.name} 不该算已实现');
      }
    });

    test('只有在库与已上架算在途占用', () {
      expect(ItemStatus.inStock.isActive, isTrue);
      expect(ItemStatus.listed.isActive, isTrue);
      expect(ItemStatus.sold.isActive, isFalse);
      expect(ItemStatus.completed.isActive, isFalse);
      expect(ItemStatus.returned.isActive, isFalse);
      expect(ItemStatus.scrapped.isActive, isFalse);
    });

    test('sold 待收、completed 已结算，两者互斥', () {
      expect(ItemStatus.sold.isReceivable, isTrue);
      expect(ItemStatus.completed.isReceivable, isFalse);
      expect(ItemStatus.sold.isSettled, isFalse);
      expect(ItemStatus.completed.isSettled, isTrue);
    });

    test('库里出现未知值时回落到在库，不抛异常', () {
      expect(ItemStatus.fromDb('nonsense'), ItemStatus.inStock);
      expect(ItemStatus.fromDb(''), ItemStatus.inStock);
    });
  });

  group('费用枚举', () {
    test('ExpenseKind 全部可往返', () {
      for (final kind in ExpenseKind.values) {
        expect(ExpenseKind.fromDb(kind.dbValue), kind);
      }
    });

    test('ExpenseSide 全部可往返', () {
      for (final side in ExpenseSide.values) {
        expect(ExpenseSide.fromDb(side.dbValue), side);
      }
    });

    test('未知值有兜底', () {
      expect(ExpenseKind.fromDb('x'), ExpenseKind.other);
      expect(ExpenseSide.fromDb('x'), ExpenseSide.buy);
    });
  });

  group('AttachmentRole', () {
    test('全部可往返', () {
      for (final role in AttachmentRole.values) {
        expect(AttachmentRole.fromDb(role.dbValue), role);
      }
    });

    test('未知值回落到 other', () {
      expect(AttachmentRole.fromDb('x'), AttachmentRole.other);
    });
  });
}
