import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/app/providers.dart';

/// seam: 扫码入口的平台开关。
///
/// 用 provider 而不是在 widget 里直接写平台判断，是为了让
/// 「Android 上有按钮 / 桌面上没有按钮」两条规格都能在桌面宿主上测到。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_test 默认把平台设成 android，所以要逐条显式指定。
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android 上提供扫码入口', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(scanAvailableProvider), isTrue);
  });

  test('桌面端不提供扫码入口', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(scanAvailableProvider), isFalse);
  });

  test('可被 override 成有扫码能力', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final container = ProviderContainer(
      overrides: [scanAvailableProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);

    expect(container.read(scanAvailableProvider), isTrue);
  });
}
