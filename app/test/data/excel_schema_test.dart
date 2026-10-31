import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/exchange/excel_rows.dart';
import 'package:ggjb/domain/enums.dart';

void main() {
  group('ExcelSchema 表头', () {
    test('商品表 22 列且没有重复列名', () {
      expect(ExcelSchema.itemHeaders.length, 22);
      expect(
        ExcelSchema.itemHeaders.toSet().length,
        ExcelSchema.itemHeaders.length,
      );
    });

    test('费用表 7 列且没有重复列名', () {
      expect(ExcelSchema.expenseHeaders.length, 7);
      expect(
        ExcelSchema.expenseHeaders.toSet().length,
        ExcelSchema.expenseHeaders.length,
      );
    });

    test('只读列都在商品表头里', () {
      for (final header in ExcelSchema.computedHeaders) {
        expect(
          ExcelSchema.itemHeaders,
          contains(header),
          reason: '只读列「$header」必须出现在导出表头里，否则导入时对不上号',
        );
      }
    });

    test('名称列是导入的必需列，且不在只读集合里', () {
      expect(ExcelSchema.itemHeaders, contains(ExcelSchema.title));
      expect(ExcelSchema.computedHeaders, isNot(contains(ExcelSchema.title)));
    });
  });

  group('状态映射', () {
    test('每个状态的标签都能反解回自己', () {
      for (final value in ItemStatus.values) {
        expect(ExcelSchema.statusFromLabel(ExcelSchema.statusLabel(value)), value);
      }
    });

    test('手敲 dbValue 也认', () {
      for (final value in ItemStatus.values) {
        expect(ExcelSchema.statusFromLabel(value.dbValue), value);
      }
    });

    test('空白与未知值返回 null，不抛异常', () {
      expect(ExcelSchema.statusFromLabel(''), isNull);
      expect(ExcelSchema.statusFromLabel('   '), isNull);
      expect(ExcelSchema.statusFromLabel('待定'), isNull);
    });

    test('前后空格会被裁掉', () {
      expect(ExcelSchema.statusFromLabel('  已到账 '), ItemStatus.completed);
    });

    test('「已卖出」与「已到账」是两个不同状态，不能混', () {
      expect(ExcelSchema.statusFromLabel('已卖出'), ItemStatus.sold);
      expect(ExcelSchema.statusFromLabel('已到账'), ItemStatus.completed);
      expect(ItemStatus.sold, isNot(ItemStatus.completed));
    });
  });

  group('费用种类与侧别映射', () {
    test('种类标签往返', () {
      for (final value in ExpenseKind.values) {
        expect(ExcelSchema.kindFromLabel(ExcelSchema.kindLabel(value)), value);
      }
    });

    test('种类 dbValue 也认', () {
      for (final value in ExpenseKind.values) {
        expect(ExcelSchema.kindFromLabel(value.dbValue), value);
      }
    });

    test('种类未知值返回 null', () {
      expect(ExcelSchema.kindFromLabel(''), isNull);
      expect(ExcelSchema.kindFromLabel('打赏'), isNull);
    });

    test('侧别标签往返', () {
      for (final value in ExpenseSide.values) {
        expect(ExcelSchema.sideFromLabel(ExcelSchema.sideLabel(value)), value);
      }
    });

    test('侧别 dbValue 也认', () {
      for (final value in ExpenseSide.values) {
        expect(ExcelSchema.sideFromLabel(value.dbValue), value);
      }
    });

    test('侧别未知值返回 null', () {
      expect(ExcelSchema.sideFromLabel('两边'), isNull);
    });
  });

  group('日期格式', () {
    test('常量是 yyyy-MM-dd，与导出写出的格式一致', () {
      expect(ExcelSchema.datePattern, 'yyyy-MM-dd');
    });
  });
}
