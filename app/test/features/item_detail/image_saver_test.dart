import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/features/item_detail/image_saver.dart';

/// seam: ImageSaver —— 保存图片时「预填什么文件名、交给底层什么字节、结果怎么表达」。
///
/// 真实的系统「另存为」对话框无法在测试里驱动，所以注入 `SaveBytes`：
/// 测试只断言我们这一侧的决定（文件名规则、原图字节、三种结果），
/// 平台对话框本身留给手工核对。
void main() {
  test('保存成功：文件名按规则拼、字节原样传给底层、返回 saved', () async {
    final calls = <({String fileName, Uint8List bytes})>[];
    final saver = ImageSaver(
      saveBytes: ({required fileName, required bytes}) async {
        calls.add((fileName: fileName, bytes: bytes));
        return '/downloads/$fileName';
      },
      clock: () => DateTime(2026, 11, 24, 17, 30, 5),
    );

    final image = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
    final outcome = await saver.save(
      title: 'iPhone 13 Pro 128G 蓝色',
      mime: 'image/png',
      bytes: image,
    );

    expect(outcome, isA<SaveOutcomeSaved>());
    expect((outcome as SaveOutcomeSaved).path, '/downloads/ggjb-iPhone 13-20261124-173005.png');
    expect(calls.single.fileName, 'ggjb-iPhone 13-20261124-173005.png');
    expect(calls.single.bytes, image, reason: '必须是原图字节，不能是缩略图');
  });

  test('标题含路径分隔符与 Windows 保留字符时一律剔除', () async {
    final names = <String>[];
    final saver = ImageSaver(
      saveBytes: ({required fileName, required bytes}) async {
        names.add(fileName);
        return '/downloads/$fileName';
      },
      clock: () => DateTime(2026, 11, 24, 17, 30, 5),
    );

    await saver.save(
      title: r'A/B\C:D*E?F"G<H>I|J',
      mime: 'image/png',
      bytes: Uint8List.fromList([1]),
    );

    final name = names.single;
    for (final bad in [r'\', '/', ':', '*', '?', '"', '<', '>', '|']) {
      expect(name.contains(bad), isFalse, reason: '文件名里不该出现 $bad：$name');
    }
    expect(name, startsWith('ggjb-'));
    expect(name, endsWith('.png'));
  });

  test('标题为空或全是非法字符时回退为「图片」', () async {
    final names = <String>[];
    final saver = ImageSaver(
      saveBytes: ({required fileName, required bytes}) async {
        names.add(fileName);
        return '/downloads/$fileName';
      },
      clock: () => DateTime(2026, 11, 24, 17, 30, 5),
    );

    await saver.save(title: '   ', mime: 'image/png', bytes: Uint8List(1));
    await saver.save(title: '///***', mime: 'image/png', bytes: Uint8List(1));

    expect(names[0], 'ggjb-图片-20261124-173005.png');
    expect(names[1], 'ggjb-图片-20261124-173005.png');
  });

  test('扩展名跟随附件 mime', () async {
    final names = <String>[];
    final saver = ImageSaver(
      saveBytes: ({required fileName, required bytes}) async {
        names.add(fileName);
        return '/downloads/$fileName';
      },
      clock: () => DateTime(2026, 11, 24, 17, 30, 5),
    );

    await saver.save(title: '图', mime: 'image/jpeg', bytes: Uint8List(1));
    await saver.save(title: '图', mime: 'image/jpg', bytes: Uint8List(1));
    await saver.save(title: '图', mime: 'image/png', bytes: Uint8List(1));
    await saver.save(title: '图', mime: 'application/octet-stream', bytes: Uint8List(1));

    expect(names[0], endsWith('.jpg'));
    expect(names[1], endsWith('.jpg'));
    expect(names[2], endsWith('.png'));
    expect(names[3], endsWith('.png'), reason: '未知类型按 PNG 处理，与库里的实际字节一致');
  });

  test('用户在另存为里取消：返回 cancelled，不算失败', () async {
    final saver = ImageSaver(
      saveBytes: ({required fileName, required bytes}) async => null,
      clock: () => DateTime(2026, 11, 24, 17, 30, 5),
    );

    final outcome = await saver.save(
      title: '图',
      mime: 'image/png',
      bytes: Uint8List.fromList([1]),
    );

    expect(outcome, isA<SaveOutcomeCancelled>());
  });

  test('保存失败：返回 failed，消息可读且不含堆栈原文', () async {
    final saver = ImageSaver(
      saveBytes: ({required fileName, required bytes}) async {
        throw FileSystemException('Cannot write to file', '/readonly/x.png');
      },
      clock: () => DateTime(2026, 11, 24, 17, 30, 5),
    );

    final outcome = await saver.save(
      title: '图',
      mime: 'image/png',
      bytes: Uint8List.fromList([1]),
    );

    expect(outcome, isA<SaveOutcomeFailed>());
    final message = (outcome as SaveOutcomeFailed).message;
    expect(message, contains('保存失败'));
    expect(message.contains('FileSystemException'), isFalse);
    expect(message.contains('#0'), isFalse, reason: '不能把堆栈甩给用户');
  });
}
