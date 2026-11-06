import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/features/barcode/label_commands.dart';

/// seam: 40×30mm 标签的 TSPL 指令生成（纯函数）。
///
/// 断言的是打印机收到的字节内容；实际出纸效果只能真机打一张看。
void main() {
  const itemId = '123e4567-e89b-42d3-a456-426614174000';

  String textOf(List<int> bytes) => utf8.decode(bytes);

  group('尺寸与走纸', () {
    test('标签尺寸写死在指令里', () {
      final text = textOf(buildLabelCommands(code: itemId, title: 'iPhone 13'));

      expect(text, contains('SIZE 40 mm, 30 mm'));
    });

    test('带标签间隙与方向，并先清空画布', () {
      final text = textOf(buildLabelCommands(code: itemId, title: 'iPhone 13'));

      expect(text, contains('GAP 2 mm, 0 mm'));
      expect(text, contains('DIRECTION 1'));
      expect(text, contains('CLS'));
    });
  });

  group('二维码', () {
    test('二维码参数为 L 级容错、cell 6 dots、自动模式', () {
      final text = textOf(buildLabelCommands(code: itemId, title: 'iPhone 13'));

      expect(text, contains('QRCODE 73,8,L,6,A,0'));
    });

    test('二维码内容就是记录主键', () {
      final text = textOf(buildLabelCommands(code: itemId, title: 'iPhone 13'));

      expect(text, contains('"$itemId"'));
    });
  });

  group('文本行', () {
    test('标题与明文都出现在指令里', () {
      final text = textOf(buildLabelCommands(code: itemId, title: 'iPhone 13'));

      expect(text, contains('"iPhone 13"'));
      expect(text, contains(itemId));
    });

    test('标题超过 16 个字符被截断', () {
      const long = '一二三四五六七八九十一二三四五六七八九十';
      final text = textOf(buildLabelCommands(code: itemId, title: long));

      expect(text, contains('"一二三四五六七八九十一二三四五六"'));
      expect(text, isNot(contains(long)));
    });

    test('空标题不会生成空引号行', () {
      final text = textOf(buildLabelCommands(code: itemId, title: '   '));

      expect(text, isNot(contains('""')));
    });
  });

  group('指令完整性', () {
    test('以打印指令结尾', () {
      final text = textOf(buildLabelCommands(code: itemId, title: 'x')).trimRight();

      expect(text.endsWith('PRINT 1,1'), isTrue);
    });

    test('返回的是可直接写入蓝牙流的字节，全部落在 0-255', () {
      final bytes = buildLabelCommands(code: itemId, title: '中文标题测试');

      expect(bytes, isNotEmpty);
      for (final b in bytes) {
        expect(b, inInclusiveRange(0, 255));
      }
    });
  });
}
