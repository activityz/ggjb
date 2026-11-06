import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 把 [RepaintBoundary] 当前渲染结果截成图片。
///
/// 单独抽出来是为了可测：分享/保存要走平台通道，在测试里跑不了，而
/// 「截出来的字节是不是一张合法 PNG」完全可以在测试里断言。
Future<ui.Image?> renderBoundaryImage(
  GlobalKey boundaryKey, {
  double pixelRatio = 4,
}) async {
  final object = boundaryKey.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return null;
  return object.toImage(pixelRatio: pixelRatio);
}

/// 同上，但直接给出 PNG 字节。
Future<Uint8List?> renderBoundaryPng(
  GlobalKey boundaryKey, {
  double pixelRatio = 4,
}) async {
  final image = await renderBoundaryImage(boundaryKey, pixelRatio: pixelRatio);
  if (image == null) return null;
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
