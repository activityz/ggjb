# windows-bt-print

## Why

电脑上现在只能「导出 PNG → 用厂商工具打」，而标签机就在手边。手机那条通道是 Android 原生 MethodChannel，Windows 端连打印按钮都不显示。

Windows 侧其实也能直连：SPP（RFCOMM）是 Windows 蓝牙栈的标准能力，而 `win32 5.15.0` 已经把需要的 API 都暴露给 Dart 了——`BluetoothFindFirstDevice`、`BluetoothSetServiceState`、`SOCKADDR_BTH`、`AF_BTH`、`connect`、`send`。不用写 C++ 插件，纯 Dart FFI 就能打通。

## What Changes

- 新增 Windows 蓝牙打印通道（纯 Dart FFI，走 `win32`）：
  - **只列已配对设备**（`fReturnAuthenticated = true`）；配对在 Windows「设置 → 蓝牙和其他设备」里完成，App 不实现配对流程
  - 连接用 `socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM)` + `connect(SOCKADDR_BTH)`，写入用 `send`
  - 复用现有 `buildLabelCommands` 生成的 TSPL 字节，与 Android 完全同一份指令
- **打印入口在 Windows 也出现**：`printAvailableProvider` 从「仅 Android」放宽到「Android 或 Windows」
- `PrinterPage` 在 Windows 上复用同一套 UI（扫描 → 已配对列表 → 连接 → 断开 → 校准走纸）
- 把现有的 `PrinterChannel` 抽成接口：Android 走 MethodChannel，Windows 走 FFI，其它平台不支持
- 新增直接依赖 `win32: ^5.15.0`（它已在 lock 里，是 `share_plus` 等的传递依赖，镜像源有，不会改变锁文件版本）
- **不改数据库**：不加列、不升 `schemaVersion`、不动同步
- 版本号 `1.8.0+10` → `1.9.0+11`

## Capabilities

### New Capabilities

- `windows-bt-print`：Windows 桌面端通过经典蓝牙 SPP 连接已配对的标签打印机，按同一套 TSPL 指令打印 40×30mm 标签。

### Modified Capabilities

（无。`qr-print` 的 Android 行为不变，本次只是新增一个平台实现。）

## Impact

- 生产代码：
  - `app/pubspec.yaml`（`win32` + 版本号）
  - `app/lib/features/scan/printer_channel.dart`（抽成接口 + 平台分派）
  - `app/lib/features/scan/windows_printer.dart`（FFI 实现：枚举、连接、写、断开）
  - `app/lib/features/scan/printer_controller.dart`（`printAvailableProvider` 放宽）
  - `app/lib/features/scan/printer_page.dart`（Windows 文案：配对在系统设置里做）
- 测试：`windows_printer_test`（`SOCKADDR_BTH` 填充、蓝牙地址解析、端口回退顺序，都是纯计算）、`printer_channel_test`（平台分派选中右实现）
- 不影响：Android 打印链路、扫码、二维码弹窗、库结构与同步
- 已知风险：**本机没有蓝牙标签机，Windows 通道无法在这里验证**；RFCOMM 端口号在 SPP 打印机上通常是 1，若不报文需要真机试错

## 非目标

- 不实现蓝牙配对流程（配对交给系统设置）
- 不改 Android 通道
- 不做 Windows 打印队列（USB/驱动）方案
- 不做批量打印
