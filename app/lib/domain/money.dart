/// 金额的唯一表示：内部一律用 int 表示「分」。
///
/// 纪律：
/// - 全项目禁止用 double 保存或传递金额。
/// - 入库字段一律以 `_cents` 结尾且为 INTEGER。
/// - 只在展示层调用 [toYuanString]，只在输入层调用 [tryParseYuan]。
library;

class Money implements Comparable<Money> {
  const Money(this.cents);

  /// 以「分」为单位的整数金额。
  final int cents;

  static const Money zero = Money(0);

  bool get isZero => cents == 0;
  bool get isNegative => cents < 0;

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  Money operator -() => Money(-cents);

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => toYuanString();

  /// 解析用户输入的「元」金额字符串，失败返回 null。
  ///
  /// 容忍：前后空格、千分位逗号（中英文）、货币符号、全角数字、结尾多余小数点。
  /// 小数超过两位时按四舍五入截到两位。
  static Money? tryParseYuan(String raw) {
    var s = _normalize(raw);
    if (s.isEmpty) return null;

    var negative = false;
    if (s.startsWith('-') || s.startsWith('−')) {
      negative = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    if (s.isEmpty) return null;
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(s)) return null;

    final dot = s.indexOf('.');
    final intPart = dot < 0 ? s : s.substring(0, dot);
    final fracPart = dot < 0 ? '' : s.substring(dot + 1);
    if (intPart.isEmpty && fracPart.isEmpty) return null;

    final yuan = intPart.isEmpty ? 0 : int.tryParse(intPart);
    if (yuan == null) return null;

    var total = yuan * 100;
    if (fracPart.isNotEmpty) {
      total += (fracPart.codeUnitAt(0) - 0x30) * 10;
    }
    if (fracPart.length >= 2) {
      total += fracPart.codeUnitAt(1) - 0x30;
    }
    if (fracPart.length >= 3 && (fracPart.codeUnitAt(2) - 0x30) >= 5) {
      total += 1;
    }
    return Money(negative ? -total : total);
  }

  /// 解析失败即视为 0，用于「填了就记，没填就是 0」的容错场景。
  static Money parseYuanOrZero(String raw) => tryParseYuan(raw) ?? Money.zero;

  static String _normalize(String raw) {
    final buf = StringBuffer();
    for (final rune in raw.trim().runes) {
      // 全角数字与全角符号 → 半角
      if (rune >= 0xFF10 && rune <= 0xFF19) {
        buf.writeCharCode(rune - 0xFF10 + 0x30);
      } else if (rune == 0xFF0E) {
        buf.write('.');
      } else if (rune == 0xFF0D || rune == 0x2013 || rune == 0x2014) {
        buf.write('-');
      } else if (rune == 0x3000 || rune == 0x20) {
        continue; // 空格丢弃
      } else if (rune == 0x2C || rune == 0xFF0C) {
        continue; // 千分位逗号丢弃
      } else if (rune == 0xA5 || rune == 0xFFE5) {
        continue; // ¥ ￥ 丢弃
      } else {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  /// 转为「元」字符串。默认带 ¥ 与千分位。
  ///
  /// - [symbol] 是否带 ¥
  /// - [thousands] 是否加千分位
  /// - [forceDecimals] 强制显示两位小数（默认：是整数元就省略小数）
  String toYuanString({
    bool symbol = true,
    bool thousands = true,
    bool forceDecimals = false,
  }) {
    final negative = cents < 0;
    final abs = cents.abs();
    final yuan = abs ~/ 100;
    final fen = abs % 100;

    final yuanText = thousands ? _groupThousands(yuan.toString()) : yuan.toString();
    final showFen = forceDecimals || fen != 0;
    final buf = StringBuffer();
    if (negative) buf.write('-');
    if (symbol) buf.write('¥');
    buf.write(yuanText);
    if (showFen) {
      buf.write('.');
      buf.write(fen.toString().padLeft(2, '0'));
    }
    return buf.toString();
  }

  /// 纯数字形式，用于输入框回填与导出："1234" / "1234.50"
  String toPlainString({bool forceDecimals = false}) =>
      toYuanString(symbol: false, thousands: false, forceDecimals: forceDecimals);

  static String _groupThousands(String digits) {
    if (digits.length <= 3) return digits;
    final buf = StringBuffer();
    final firstGroup = digits.length % 3;
    if (firstGroup > 0) {
      buf.write(digits.substring(0, firstGroup));
    }
    for (var i = firstGroup; i < digits.length; i += 3) {
      if (buf.isNotEmpty) buf.write(',');
      buf.write(digits.substring(i, i + 3));
    }
    return buf.toString();
  }
}
