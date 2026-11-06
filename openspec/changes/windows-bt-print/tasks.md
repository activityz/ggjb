# Tasks

## 0. 测试缝报备

- [x] 0.1 确认下表为本次全部测试 seam；表外不写测试

  | seam（public 边界） | 抓住什么 | 漏掉什么 |
  | --- | --- | --- |
  | `parseBluetoothAddress(String)` | `AA:BB:CC:DD:EE:FF` → 48 bit 整数的字节序 | 真实设备地址 |
  | `nextRfcommPort(int attempt)` | 端口回退顺序 1 → 2 → 3 → 4 | 打印机真实端口 |
  | `createPrinterChannel()` 平台分派 | Android / Windows / 其它平台各自拿到哪种实现 | 真实通道行为 |
  | `PrinterController` 复用既有状态机 | 换实现后四态行为不变 | Windows 蓝牙链路 |

## 1. 依赖与抽象

- [x] 1.1 `app/pubspec.yaml` 加 `win32: ^5.15.0`（已在 lock，不应引起版本变化），版本号 `1.8.0+10` → `1.9.0+11`；`flutter pub get` 后 `git diff app/pubspec.lock` 必须为空
- [x] 1.2 `printer_channel.dart` 拆成接口 + `AndroidPrinterChannel`（原逻辑平移）+ `createPrinterChannel()` 工厂 + `UnsupportedPrinterChannel`；`app/test/features/scan/printer_channel_test.dart` 覆盖工厂在三种平台下返回的类型

## 2. Windows FFI 实现

- [x] 2.1 `app/lib/features/scan/windows_printer.dart`：`parseBluetoothAddress`（地址 → 48 bit）与 `nextRfcommPort`（回退序列），配 `app/test/features/scan/windows_printer_test.dart`：断言 `AA:BB:CC:DD:EE:FF` 解析成 `0xAABBCCDDEEFF`、回退顺序是 1,2,3,4 且第 5 次为 null
- [x] 2.2 实现 `WindowsPrinterChannel`：`BluetoothFindFirstDevice` 枚举已配对设备、`socket(AF_BTH, SOCK_STREAM, 0x0003)` + `connect(SOCKADDR_BTH)` 按端口回退建链、`send` 循环写完、`closesocket` 断开；所有结构体分配 `try/finally` 释放
- [x] 2.3 `printer_controller.dart` 改用 `createPrinterChannel()`，`printAvailableProvider` 放宽到 Android 或 Windows

## 3. UI 与文案

- [x] 3.1 `printer_page.dart`：Windows 上「扫描」按钮文案改为「刷新已配对设备」，未配对时给出「去 Windows 设置配对」的说明；Android 文案不变
- [x] 3.2 `qr_dialog.dart` 的打印按钮在 Windows 也显示（由 `printAvailableProvider` 决定，无需改组件）
- [x] 3.3 `README.md` 补 Windows 打印说明（蓝牙接电脑、先在系统里配对、失败看错误码），`docs/agent/memory.md` 记 FFI 通道要点

## 4. 收尾校验

- [x] 4.1 用 fvm 绝对路径跑 `flutter analyze`，输出必须 `No issues found!`
- [x] 4.2 用 fvm 绝对路径跑 `flutter test`，全量通过且无 skip，数字写回本文件与汇报
- [x] 4.3 `openspec validate windows-bt-print --strict` 通过
- [x] 4.4 逐项核对本文件与 `specs/windows-bt-print/spec.md` 的 scenario 一一对应
