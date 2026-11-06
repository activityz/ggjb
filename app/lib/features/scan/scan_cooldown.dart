/// 扫码防重复触发。
///
/// 相机一秒会吐十几帧，同一张码会被反复识别。这里只认第一次，
/// 避免连续 open 好几个详情页、也避免弹一串「没找到」。
class ScanCooldown {
  ScanCooldown({this.window = const Duration(milliseconds: 1500)});

  /// 同一个码在这个时间窗内只放行一次。
  final Duration window;

  String? _lastCode;
  DateTime? _lastAt;

  /// [now] 可注入，测试里用固定时间点验证窗口边界。
  bool accept(String code, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final lastAt = _lastAt;

    if (_lastCode == code &&
        lastAt != null &&
        at.difference(lastAt) < window) {
      return false;
    }

    _lastCode = code;
    _lastAt = at;
    return true;
  }
}
