import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 一张图处理后的结果：压缩原图 + 缩略图 + 尺寸。
class ProcessedImage {
  const ProcessedImage({
    required this.bytes,
    required this.thumb,
    required this.width,
    required this.height,
  });

  /// 长边不超过 [ImagePipeline.maxLongEdge] 的 JPEG。
  final Uint8List bytes;

  /// 长边不超过 [ImagePipeline.thumbLongEdge] 的 JPEG，列表页专用。
  final Uint8List thumb;

  final int width;
  final int height;

  int get sizeBytes => bytes.length;
  int get thumbSizeBytes => thumb.length;
}

class ImagePipelineException implements Exception {
  const ImagePipelineException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 图片入库前的统一处理。
///
/// 决策依据（docs/design/0001-architecture.md §1.3）：图片以 BLOB 进库，
/// 所以必须在入库前压到可控体积，否则库会失控。
/// - 原图长边 1920px / JPEG q85
/// - 缩略图长边 300px / JPEG q80
/// - EXIF 方向在压缩时就烘焙进像素，之后不再依赖 EXIF
///
/// 放在独立 isolate 里跑，避免大图解码卡住 UI。
class ImagePipeline {
  const ImagePipeline({
    this.maxLongEdge = 1920,
    this.thumbLongEdge = 300,
    this.quality = 85,
    this.thumbQuality = 80,
  });

  final int maxLongEdge;
  final int thumbLongEdge;
  final int quality;
  final int thumbQuality;

  Future<ProcessedImage> process(Uint8List input) {
    final maxLong = maxLongEdge;
    final thumbLong = thumbLongEdge;
    final q = quality;
    final tq = thumbQuality;
    return Isolate.run(
      () => processSync(
        input,
        maxLongEdge: maxLong,
        thumbLongEdge: thumbLong,
        quality: q,
        thumbQuality: tq,
      ),
    );
  }

  /// 同步版本，供 isolate 内部和测试直接调用。
  static ProcessedImage processSync(
    Uint8List input, {
    int maxLongEdge = 1920,
    int thumbLongEdge = 300,
    int quality = 85,
    int thumbQuality = 80,
  }) {
    final decoded = img.decodeImage(input);
    if (decoded == null) {
      throw const ImagePipelineException('无法解析这张图片，可能格式不支持或文件已损坏');
    }

    // 手机拍的竖图常常是「横向像素 + EXIF 旋转」，先烘焙方向再缩放。
    final oriented = img.bakeOrientation(decoded);
    final main = _fit(oriented, maxLongEdge);
    final thumb = _fit(oriented, thumbLongEdge);

    return ProcessedImage(
      bytes: Uint8List.fromList(img.encodeJpg(main, quality: quality)),
      thumb: Uint8List.fromList(img.encodeJpg(thumb, quality: thumbQuality)),
      width: main.width,
      height: main.height,
    );
  }

  static img.Image _fit(img.Image src, int longEdge) {
    final longest = src.width >= src.height ? src.width : src.height;
    if (longest <= longEdge) return src;
    return src.width >= src.height
        ? img.copyResize(
            src,
            width: longEdge,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            src,
            height: longEdge,
            interpolation: img.Interpolation.average,
          );
  }
}
