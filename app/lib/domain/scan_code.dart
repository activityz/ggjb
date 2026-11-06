/// 扫码文本 → 记录标识的规范化与判定。
///
/// 这一层只做两件事：把解码器吐出来的字符串洗成纯码值，判断它是不是
/// 本应用的记录标识。真正的查库在 `ItemRepository.resolveScan`，
/// 相机在 `features/scan/scan_page.dart` —— 三者之间只有一条 `String` 流动。
library;

/// 空白与零宽字符。
///
/// 扫码枪与部分解码器会在尾部附带 `\r\n`；某些实现还会混入 BOM / 零宽
/// 空格。记录标识（UUID）本身不含任何空白，所以一律剔除，比逐个位置
/// trim 更稳。
final RegExp _blankOrZeroWidth = RegExp(r'[\s\u200B\u200C\u200D\uFEFF]');

/// 清洗解码结果：只留有效字符。
String normalizeScanText(String raw) => raw.replaceAll(_blankOrZeroWidth, '');

/// UUID v4 的格式。
///
/// 只认 v4：本项目主键由 `Uuid().v4()` 生成。放宽到任意 UUID 会让别的
/// 应用的码也能过校验，最后只在查库那一步才失败，提示就变成「没找到」
/// 这种含糊结论。
final RegExp _itemIdPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// 是不是一条记录的标识。
bool isItemId(String value) => _itemIdPattern.hasMatch(value);

/// 一次扫码的结论。
sealed class ScanResolution {
  const ScanResolution();
}

/// 命中：码值合法，接下来可以拿去查库。
final class ScanHit extends ScanResolution {
  const ScanHit(this.itemId);

  /// 归一成小写，与库里 `Uuid().v4()` 写出来的形态一致。
  final String itemId;
}

/// 为什么没认出来。
enum ScanMissReason {
  /// 洗完之后不是合法的记录标识 —— 不是本应用的码。
  malformed,

  /// 格式合法，但库里没有这条可用记录（不存在或已删除）。
  notFound,
}

/// 未命中。
final class ScanMiss extends ScanResolution {
  const ScanMiss(this.reason, this.raw);

  final ScanMissReason reason;

  /// 清洗后的原文，用于提示与排查。
  final String raw;
}

/// 把扫码原文解析成「合法标识」或「格式错误」。
///
/// 不做查库：这一层是纯函数，才能在测试里覆盖脏字符、大小写、非 v4
/// 这些分支，而不必拉起相机或数据库。
ScanResolution resolveScanText(String raw) {
  final code = normalizeScanText(raw);
  if (!isItemId(code)) return ScanMiss(ScanMissReason.malformed, code);
  return ScanHit(code.toLowerCase());
}
