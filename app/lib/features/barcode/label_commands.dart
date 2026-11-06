/// 40×30mm 标签的 TSPL 指令生成。
///
/// 为什么自己拼而不是引第三方包：打印只需要"把一段字节写进蓝牙流"，
/// 指令本身 300 字节不到；而现成的打印包会把整个依赖源搬到 pub.dev
/// （见 openspec/changes/qr-list-and-print/design.md 的 D2）。
library;

import 'dart:convert';

/// 标签纸尺寸（mm）。现场是 40×30。
const int labelWidthMm = 40;
const int labelHeightMm = 30;

/// 203dpi = 8 dots/mm，画布 320×240 dots。
const int labelWidthDots = 320;
const int labelHeightDots = 240;

/// QR 单元宽度（dots）。29 模块 × 6 = 174 dots ≈ 21.75mm，左右各余 73。
const int qrCellDots = 6;

/// 标题最多写这么多个字符（按字符数，不按字节）。
///
/// 40mm 宽减去两侧各 8 dots 只剩 304 dots，24 点阵汉字一位 24 dots，
/// 12 个汉字就到顶；留到 16 是给半角字符留余量。
const int maxTitleChars = 16;

/// 生成一张 40×30 标签的 TSPL 指令。
///
/// 布局：二维码在上（21.75mm 见方），标题一行，明文码值一行。
/// 返回的字节可以直接写进蓝牙 socket。
List<int> buildLabelCommands({required String code, required String title}) {
  final safeTitle = _sanitizeTitle(title);

  final lines = <String>[
    'SIZE $labelWidthMm mm, $labelHeightMm mm',
    'GAP 2 mm, 0 mm',
    'DIRECTION 1',
    'CLS',
    // ECC L（15% 容错对贴纸足够）、cell 6 dots、自动编码、0° 旋转
    'QRCODE 73,8,L,$qrCellDots,A,0,M2,S7,"$code"',
    if (safeTitle.isNotEmpty) 'TEXT 8,190,"TSS24.BF2",0,1,1,"$safeTitle"',
    'TEXT 8,214,"TSS16.BF2",0,1,1,"$code"',
    'PRINT 1,1',
  ];

  return utf8.encode('${lines.join('\r\n')}\r\n');
}

/// 清洗标题：去掉会破坏 TSPL 字符串的引号与换行，按字符截断。
///
/// 按 `runes` 截断而不是 `substring`：一个汉字在 UTF-16 里占一个 code unit，
/// 但 emoji 占两个，按长度切会切出半个字符，打出来是方块。
String _sanitizeTitle(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r'[\r\n\t"]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (cleaned.isEmpty) return '';

  final runes = cleaned.runes.toList(growable: false);
  if (runes.length <= maxTitleChars) return cleaned;
  return String.fromCharCodes(runes.take(maxTitleChars));
}
