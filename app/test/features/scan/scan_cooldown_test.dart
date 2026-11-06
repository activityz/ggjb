import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/features/scan/scan_cooldown.dart';

/// seam: 扫码防重复触发。
///
/// 相机每秒会吐十几帧，同一张码会被反复识别；这里只认第一次，
/// 避免连开好几个详情页。纯逻辑，不碰相机。
void main() {
  const code = '123e4567-e89b-42d3-a456-426614174000';
  const other = '123e4567-e89b-42d3-a456-426614174001';
  final t0 = DateTime(2026, 11, 6, 9);

  test('第一次识别放行', () {
    final cooldown = ScanCooldown();

    expect(cooldown.accept(code, now: t0), isTrue);
  });

  test('同一码在窗口内再次识别被拦下', () {
    final cooldown = ScanCooldown();
    cooldown.accept(code, now: t0);

    expect(
      cooldown.accept(code, now: t0.add(const Duration(milliseconds: 800))),
      isFalse,
    );
  });

  test('同一码超过窗口后重新放行', () {
    final cooldown = ScanCooldown();
    cooldown.accept(code, now: t0);

    expect(
      cooldown.accept(code, now: t0.add(const Duration(milliseconds: 1600))),
      isTrue,
    );
  });

  test('换了码立刻放行', () {
    final cooldown = ScanCooldown();
    cooldown.accept(code, now: t0);

    expect(
      cooldown.accept(other, now: t0.add(const Duration(milliseconds: 100))),
      isTrue,
    );
  });
}
