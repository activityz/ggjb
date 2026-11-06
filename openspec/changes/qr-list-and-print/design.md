# 设计：列表入口与蓝牙标签打印（原生通道版）

## Context

- 现有二维码弹窗 `QrDialog`（`app/lib/features/barcode/qr_dialog.dart`）：`itemId` 必填、`title` 已有参数但没用；内部拿 `RepaintBoundary` 截图导出 PNG，走 `SharePlus`。
- 列表卡片（`app/lib/features/item_list/item_list_page.dart:520`）是一个 `Row`：左缩略图、右信息列（标题行在最上），整卡 `onTap` 进详情、`onLongPress` 弹操作菜单。
- **依赖源事实**：`bluetooth_print` 与 `permission_handler` 在项目使用的 `pub.flutter-io.cn` 镜像里不存在；改用 `PUB_HOSTED_URL=https://pub.dev` 解算后，`pubspec.lock` 里 **247 个包的 URL 被改成 pub.dev**、另有 61 处版本条目变动。这等于为了一个传输层把整个项目的依赖源迁走。
- 现场标签机 40×30mm、203dpi（8 dots/mm，即 320×240 dots 画布），型号未知。
- 库结构不动：打印机地址不落库（见 D4）。

## Goals / Non-Goals

**Goals:**

- 列表里一眼能给某条记录出码，不用先进详情
- 在 Android 上直接打 40×30 标签，不绕厂商 App
- 不新增任何 pub 依赖，`pubspec.lock` 不动
- 指令生成与蓝牙传输分离：前者是纯函数可完整测试，后者只在真机跑

**Non-Goals:**

- 不做批量连续打印
- 不做 Windows 蓝牙打印（桌面只保留导出 PNG）
- 不持久化打印机地址
- 首版只做 TSPL 指令集

## Decisions

### D1 列表入口：标题行右侧一个小图标，长按菜单再补一项

标题是 `Expanded(Text(...))`，在它右边插一个 20dp 的 `IconButton`（`Icons.qr_code_2`），`visualDensity: compact`。整卡的 `onTap` 不动——图标自身吃掉点击，卡片其余区域仍然进详情。

同时在 `_showActions` 菜单里加一条「二维码」，给不习惯找图标的人第二条路。

不在每行直接渲染二维码：一屏十几条，每行一个 QR 会让列表变成噪声，而且 `QrImageView` 有绘图成本。

### D2 传输层：自写 Android MethodChannel（经典蓝牙 SPP）

**为什么不用 `bluetooth_print`**：它只提供传输层，TSPL 指令本来就在 Dart 侧拼；代价却是整个项目依赖源迁到 pub.dev。而 40×30 标签机用的是经典蓝牙 SPP（RFCOMM），Android SDK 原生就有：

```
BluetoothAdapter.getDefaultAdapter()
adapter.startDiscovery() + BroadcastReceiver(BluetoothDevice.ACTION_FOUND)
device.createRfcommSocketToServiceRecord(UUID.fromString(
    "00001101-0000-1000-8000-00805F9B34FB"))
socket.outputStream.write(bytes)
```

通道契约（`ggjb/printer`）：

| 方法 | 参数 | 返回 |
| --- | --- | --- |
| `scan` | — | `List<{name, address}>`，10 秒超时 |
| `connect` | `address` | `true` / 抛错 |
| `disconnect` | — | `true` |
| `isConnected` | — | `bool` |
| `write` | `List<int>` | `true` / 抛错 |

三条实现约束：

1. **所有蓝牙操作放后台线程**（`Executors.newSingleThreadExecutor()`），结果 `runOnUiThread` 回给 Flutter，避免 ANR。
2. **同一时刻只保留一个 socket**：连接新设备先关旧的，否则 NFC/蓝牙栈会留半开连接。
3. **`connect` 前先 `cancelDiscovery()`**：发现流程进行中建链会被系统直接拒绝，这是 SPP 最常见的"连不上"原因。

### D3 指令集：TSPL，画布 320×240 dots

TSPL 是国产 40×30 标签机（佳博、芯烨、汉印、芝柯等）最普遍的一套。布局：

```
SIZE 40 mm, 30 mm
GAP 2 mm, 0 mm
DIRECTION 1
CLS
QRCODE 73,8,L,6,A,0,M2,S7,"<itemId>"
TEXT 8,190,"TSS24.BF2",0,1,1,"<标题，超出 16 字截断>"
TEXT 8,214,"TSS16.BF2",0,1,1,"<明文码值>"
PRINT 1,1
```

换算：QR `cell=6` dots → 29 模块 × 6 = **174 dots（21.75mm）**，左右各余 73 dots；标题 24 点阵、明文 16 点阵。总高 8 + 174 + 8 + 24 + 2 + 16 ≈ 232 dots，落在 240 内。

标题截断到 16 个字符：40mm 宽减去两侧各 8 dots 只有 304 dots，24 点阵汉字一位 24 dots，12 个汉字就到顶；多出来的靠二维码与明文核对。

**指令生成必须是纯函数**（`buildLabelCommands`），输入 `code` + `title`，输出 `List<int>`（latin-1 编码，中文标题走 UTF-8 由打印机字库按码表解释——TSPL 的中文文本按 GBK/UTF-8 视机型而定，首版先用 UTF-8，真机若乱码再换码表）。这样能断言"含 `SIZE 40 mm, 30 mm`""`QRCODE` 参数是 `L,6,A,0`""以 `PRINT 1,1` 结尾"，而不用真机。

### D4 打印机地址不落库

落库要给 `local_devices` 加列 → `schemaVersion` 6→7 → 同步前版本比对会拦住旧对端，等于为了"记住打印机"让两台机器都必须升级。打印是低频动作，重启后重连一次的代价远小于一次库版本迁移。

连接状态放内存 provider，App 退出即失效；界面上明确写「重启后需要重新连接」。

### D5 权限：manifest 声明 + 原生运行时申请

Android 12+ 的 `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` 是运行时权限，不申请会抛 `SecurityException`。既然已经写原生通道，就在 Kotlin 里用 `ActivityCompat.requestPermissions` 申请，不再引 `permission_handler`。

manifest：

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-feature android:name="android.hardware.bluetooth" android:required="false" />
```

`usesPermissionFlags="neverForLocation"` 是 Android 12+ 允许扫描且不索取定位的理由声明。

### D6 打印流程与失败面

Dart 侧 `printerProvider` 暴露 `scan()` / `connect(address)` / `disconnect()` / `print(commands)`，状态机四态：`idle` / `scanning` / `connected` / `failed`。

打印点下去的顺序：检查已连接 → `write` → 完成提示。三个失败面各自给话：

| 失败面 | 表现 | 处理 |
| --- | --- | --- |
| 未连接 | 点打印时无连接 | 提示「先连接打印机」，并直接跳到打印机页 |
| 连接超时 | `connect` 10s 未成 | 提示设备名 + 失败，保持未连接 |
| 写入超时 | `write` 5s 未完成 | 提示打印失败，建议重连 |

不做自动重连：隐式重连失败时用户会以为"打了但没出纸"。

### D7 打印内容只走指令，不走截图

标签不走 `RepaintBoundary` 截图：40×30 的位图经蓝牙传要 ~30KB（未压缩更大），TSPL 文本指令不到 300 字节，且质量取决于打印机自己的点阵字库，比缩放位图清楚。

导出 PNG 仍然保留（Windows 端唯一出路，也是「用厂商 App 打」的退路）。

## Risks / Trade-offs

- **Kotlin 通道只能在真机验证** → 本机跑不了 Android 构建；代码尽量薄、逻辑集中在一个文件，失败时看 `adb logcat` 就能定位。
- **指令集猜错**：现场若是 CPCL 或 ESC/POS 机型，TSPL 打出来是废纸或空白 → 首版按 TSPL 实现；真机试打一次即可判断，切指令集是 `label_commands.dart` 一个函数的替换。
- **中文标题编码**：TSPL 文本按机型字库解释，UTF-8 与 GBK 都可能 → 首版 UTF-8，真机乱码就把标题改成 ASCII 兜底（标题只用于人眼核对，明文与二维码才是关键信息）。
- **蓝牙 GAP 校准**：`GAP 2 mm, 0` 按常见标签纸设的；纸的间隙不同会走纸不准 → 打印机页提供一次性「校准走纸」（`GAPDETECT`）。
- **Android 12+ 未授权** → 进打印机页即申请；拒绝时整页只显示权限说明与「去设置」，不显示空列表。

## Migration Plan

无数据迁移、无依赖变更、无 lock 变更。发版后 Android 首次进打印机页会申请蓝牙权限；Windows 端表现与 1.7.0 完全一致。回滚：删掉 `printer_service.dart` / `printer_page.dart` 与 Kotlin 的通道代码、撤掉两处按钮入口即可。

## Open Questions

- 现场打印机的具体型号与指令集未知。首版按 TSPL 实现；若试打无效，需要型号来换 CPCL 或 ESC/POS。
