import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/image_pipeline.dart';
import 'package:image/image.dart' as img;

Uint8List png(int width, int height) {
  final canvas = img.Image(width: width, height: height);
  img.fill(canvas, color: img.ColorRgb8(90, 120, 200));
  return Uint8List.fromList(img.encodePng(canvas));
}

bool isJpeg(Uint8List bytes) =>
    bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8;

/// seam: ImagePipeline.processSync —— 入库前的尺寸与质量约束。
void main() {
  test('横图按长边 1920 收缩，缩略图按 300 收缩', () {
    final result = ImagePipeline.processSync(png(2400, 1800));

    expect(result.width, 1920);
    expect(result.height, 1440);
    expect(isJpeg(result.bytes), isTrue);
    expect(isJpeg(result.thumb), isTrue);
    expect(result.sizeBytes, result.bytes.length);
    expect(result.thumbSizeBytes, lessThan(result.sizeBytes));
  });

  test('竖图按高收缩，宽按比例', () {
    final result = ImagePipeline.processSync(png(1800, 2400));

    expect(result.width, 1440);
    expect(result.height, 1920);
  });

  test('小图不放大', () {
    final result = ImagePipeline.processSync(png(100, 80));

    expect(result.width, 100);
    expect(result.height, 80);
  });

  test('正方形图两边都被限制', () {
    final result = ImagePipeline.processSync(png(600, 600), maxLongEdge: 300);

    expect(result.width, 300);
    expect(result.height, 300);
  });

  test('maxLongEdge/thumbLongEdge 可覆盖', () {
    final result = ImagePipeline.processSync(
      png(1000, 500),
      maxLongEdge: 400,
      thumbLongEdge: 100,
    );

    expect(result.width, 400);
    expect(result.height, 200);
    final thumb = img.decodeJpg(result.thumb)!;
    expect(thumb.width, 100);
  });

  test('半截图片报可读错误，不是空崩溃', () {
    final truncated = Uint8List.sublistView(png(200, 200), 0, 40);
    expect(
      () => ImagePipeline.processSync(truncated),
      throwsA(
        isA<ImagePipelineException>().having(
          (e) => e.message,
          'message',
          contains('无法解析'),
        ),
      ),
    );
  });

  // 缺陷#2：字节数不足图片头部长度时，img.decodeImage 抛 RangeError 而不是返回 null，
  // 于是 ImagePipeline 的「无法解析这张图片」分支走不到，用户看到的是 RangeError。
  // 实测：0 字节 → RangeError(length)；[1,2,3] → RangeError(6)；截断 PNG 头 10 字节 → RangeError(10)。
  // 过短字节抛的是 RangeError，必须被兜成 ImagePipelineException。
  test('长度不足头部的字节也报可读错误', () {
    expect(
      () => ImagePipeline.processSync(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<ImagePipelineException>()),
    );
  });

  test('缩略图长边不超过 300', () {
    final result = ImagePipeline.processSync(png(4000, 1000));
    final thumb = img.decodeJpg(result.thumb)!;

    expect(thumb.width, 300);
    expect(thumb.height, 75);
  });

  test('process 在 isolate 里跑出同样结果', () async {
    const pipeline = ImagePipeline();
    final result = await pipeline.process(png(2400, 1800));

    expect(result.width, 1920);
    expect(result.height, 1440);
  });
}
