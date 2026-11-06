# 设计：Windows 端蓝牙 SPP 打印

## Context

- Android 侧已有通道 `ggjb/printer`（`MainActivity.kt`），Dart 侧封装在 `printer_channel.dart`，状态机在 `printer_controller.dart`，指令由 `buildLabelCommands` 生成。
- `win32 5.15.0` 已在 lock 里（`share_plus` 等的传递依赖），镜像源有；本次只是把它提为直接依赖。
- 已确认它提供：`BluetoothFindFirstDevice` / `BluetoothFindNextDevice` / `BluetoothGetDeviceInfo` / `BluetoothSetServiceState` / `SOCKADDR_BTH` / `BLUETOOTH_ADDRESS` / `AF_BTH` / `SOCK_STREAM` / `connect` / `send`。
- **本机没有蓝牙标签机**，任何"能不能真的打出来"的结论都只能由用户在 Windows 上验证。

## Goals / Non-Goals

**Goals:**

- Windows 端能枚举已配对打印机、连接、把同一份 TSPL 字节写出去
- 不写 C++ 插件、不改 CMake、不加原生构建复杂度
- 平台差异收敛在 `PrinterChannel` 的一个实现里，上层（弹窗 / 状态机 / 指令）完全不动

**Non-Goals:**

- 不做配对流程（Windows 的配对有 PIN 交互，交给系统设置）
- 不做 USB / 打印队列方案
- 不做批量打印
- 不改 Android 链路

## Decisions

### D1 纯 Dart FFI，不写 C++ 插件

Flutter Windows 插件要改 `CMakeLists.txt` + `flutter_window.cpp`，每次改动都要全量重编 C++。而这些 API 都是普通 Win32 导出函数，`win32` 包已经把 `DynamicLibrary` 绑定好了，Dart 侧直接调即可——改动只在 Dart，迭代快。

代价：FFI 传错指针会**直接崩进程**（不是抛异常）。所以策略是：所有结构体分配集中在少数几个函数里，`try/finally` 释放，且不把指针传出这个文件。

### D2 只列已配对设备

`BLUETOOTH_DEVICE_SEARCH_PARAMS` 里只开 `fReturnAuthenticated` / `fReturnRemembered` / `fReturnConnected`，不开 `fReturnUnknown`。

理由：未配对设备要建链必须先配对，而配对会弹 Windows 的 PIN 对话框，App 无法代劳；列出来只会让用户点了没反应。UI 上直接写「先在 Windows 设置里配对」。

### D3 连接：AF_BTH 直接建 socket，不折腾虚拟串口

两条路都能到打印机：

| 路线 | 做法 | 问题 |
| --- | --- | --- |
| 虚拟串口 | `BluetoothSetServiceState` 启用 SPP 服务 → 系统分配 COM 号 → `CreateFile` 打开 | 要读注册表找 COM 号，且串口名在不同机器上不稳定 |
| **AF_BTH socket（选这个）** | `socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM)` + `connect(SOCKADDR_BTH)` | 端口号要猜 |

`socket()` 的第三个参数 `BTHPROTO_RFCOMM = 0x0003`（win32 没导出这个常量，自己定义）。

`SOCKADDR_BTH` 填法：

```dart
final addr = calloc<SOCKADDR_BTH>();
addr.ref.addressFamily = AF_BTH;
addr.ref.btAddr = _parseBluetoothAddress(mac); // 48 bit 整数
addr.ref.port = port;
addr.ref.serviceClassId = GUID_NULL;
```

`btAddr` 是 48 bit 整数，Windows 展示的是 `AA:BB:CC:DD:EE:FF`，解析时按字节顺序拼，**不能**直接 `int.parse(hex)` 之后左移——低位在前还是高位在前搞反了会连到不存在的地址。

### D4 RFCOMM 端口：先试 1，失败退 2/3/4

SPP 打印机的 RFCOMM 通道绝大多数是 1（厂商固件按 SPP 规范只声明一个通道）。SDP 查询能拿到准确端口，但要 `BluetoothSdpEnumAttributes` 解析属性链，代码量与收益不成比例。

所以策略是：**依次尝试 1 → 2 → 3 → 4，第一个连上的就用**，并把成功的端口记在内存里（同一次运行内不再重试）。四个都失败就报「连接失败，确认打印机已开机并与电脑配对」。

### D5 写入：`send` 可能只写一部分

`send()` 返回实际写入的字节数，短写是合法行为。循环直到写完，每次按返回值推进偏移；返回 `SOCKET_ERROR` 就断开并抛错。

单次 `send` 前把 `List<int>` 一次性转成 `Uint8List` 再分配原生内存，不做逐字节写。

### D6 抽象：`PrinterChannel` 变接口

```dart
abstract class PrinterChannel {
  Future<List<PrinterDevice>> scan();
  Future<void> connect(String address);
  Future<void> disconnect();
  Future<bool> isConnected();
  Future<void> write(List<int> bytes);
}

PrinterChannel createPrinterChannel() {
  if (Platform.isAndroid) return AndroidPrinterChannel();
  if (Platform.isWindows) return WindowsPrinterChannel();
  return const UnsupportedPrinterChannel();
}
```

原类改名 `AndroidPrinterChannel`（行为不变），`printerControllerProvider` 改用工厂。`printAvailableProvider` 从「仅 Android」放宽到「Android 或 Windows」。

注释里保留原意：这里用 `Platform` 而不是 `defaultTargetPlatform`，因为通道选择是真正的平台分派，不是给测试留的开关（测试用 override 注入假实现）。

### D7 不改库、不改同步

打印机地址仍然只在内存里（沿用 D4 的理由：落库要升 `schemaVersion`）。

## Risks / Trade-offs

- **本机无法验证** → 这是最大风险。代码只能保证"调用序列与结构体布局按文档写对"，实际能不能连上、端口是不是 1，只能你构建后在 Windows 上试。失败时看 `%LOCALAPPDATA%` 里没有日志，所以我在每条失败路径上都带上了 `GetLastError()` 的码值，报错会显示成「连接失败（错误 10060）」，便于对照微软文档。
- **FFI 崩进程** → 结构体分配集中、`try/finally` 释放；不在异步回调里持有原生指针。
- **端口猜错** → D4 的四次回退；四次都失败说明不是端口问题（多半没配对或打印机不在范围）。
- **`win32` 版本漂移** → 提为直接依赖时锁 `^5.15.0`，与 lock 现状一致，不会触发重解。

## Migration Plan

无数据迁移、无原生构建改动（只加 Dart 依赖）。发版后 Windows 端二维码弹窗多出「打印」按钮；未连接时点它会跳打印机页。回滚：删掉 `windows_printer.dart` 与工厂分派，`printAvailableProvider` 改回仅 Android。

## Open Questions

- 现场打印机的 RFCOMM 端口是否真的是 1。四条回退覆盖了常见取值，若实测都不通，需要改成 SDP 查询。
