# qr-list-and-print

## Why

二维码现在只能从详情页出：在明细列表里一眼看到十几条，想给其中一条贴标签，得先点进详情、再点右上角图标。而打标签这一步目前只能「导出 PNG → 存到手机 → 打开打印机厂商 App → 选图 → 打印」，每贴一张要绕四步。

列表页直接出码、App 内直接蓝牙打出来，才算把「记完一笔就贴一张」这件事变成顺手动作。

## What Changes

- **列表页每条记录增加二维码按钮**：放在标题行右侧，点击打开与详情页同一个二维码弹窗（携带该条记录的标题），不改变整卡点击进详情的现有行为
- **二维码弹窗增加「打印」按钮**：通过蓝牙直连标签打印机，直接打 40×30mm 标签，内容为**二维码 + 标题 + 明文码值**
- **打印指令用 TSPL**：Dart 侧直接拼 TSPL 字节；按 203dpi（320×240 dots）排版
- **设置页新增「标签打印机」**：扫描附近蓝牙设备、选择并连接、断开；连接状态仅在本次运行内有效（不落库）
- **打印入口仅 Android**：`bluetooth_print` 没有 Windows 实现，桌面端不显示打印按钮，导出 PNG 照旧
- **不新增任何 pub 依赖**：蓝牙传输走自写的 Android MethodChannel（原生 RFCOMM SPP + 原生权限申请），TSPL 指令在 Dart 侧拼字节，`pubspec.lock` 不动
- 新增 Android 权限：`BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`（Android 12+ 运行时申请），旧系统回落到 `BLUETOOTH` / `BLUETOOTH_ADMIN` 与定位权限
- **不改数据库**：不加列、不升 `schemaVersion`（仍 6）、不动同步、不动 Excel
- 版本号 `1.7.0+9` → `1.8.0+10`
- **BREAKING（Android 原生代码）**：`MainActivity` 从空壳变成注册 MethodChannel 的实现，需一次 Android 构建验证；Windows 端不受影响

## Capabilities

### New Capabilities

- `qr-print`：通过蓝牙连接 40×30mm 热敏标签机，把一条记录的二维码标签（QR + 标题 + 明文）按 TSPL 指令直接打出来。

### Modified Capabilities

- `qr-scan`：新增「列表页可直接出码」的行为契约——列表每条记录有自己的二维码入口，点开即该条记录的弹窗。

## Impact

- 生产代码：
  - `app/pubspec.yaml`（只改版本号；不新增依赖）
  - `app/android/app/src/main/AndroidManifest.xml`（蓝牙权限与 feature）
  - `app/android/app/src/main/kotlin/me/local/ggjb/MainActivity.kt`（`ggjb/printer` MethodChannel）
  - `app/lib/features/barcode/qr_dialog.dart`（标题展示 + 打印按钮 + 平台开关）
  - `app/lib/features/barcode/label_commands.dart`（TSPL 指令生成，纯函数）
  - `app/lib/features/scan/printer_channel.dart`（MethodChannel 封装）
  - `app/lib/features/scan/printer_page.dart`（设置页的打印机管理页）
  - `app/lib/features/item_list/item_list_page.dart`（每条一个二维码按钮）
  - `app/lib/features/settings/settings_page.dart`（入口）
  - `app/lib/app/providers.dart`（打印能力与连接状态 provider）
- 测试：`label_commands_test`（TSPL 指令内容：尺寸、QRCODE 参数、标题与明文、PRINT 结尾）、`qr_dialog_test` 增打印按钮的平台显隐、`item_list_page_test` 增每行二维码入口
- 不影响：库结构、同步协议、Excel、利润口径、扫码定位（码值仍是 `items.id`）
- 已知风险：指令集按 TSPL 实现；若现场机器是 CPCL 或 ESC/POS，打出来会无效——需要型号再补一版

## 非目标

- 不做批量打印/连续打多张（一次一张）
- 不做 Windows 蓝牙打印（桌面端只能导出 PNG）
- 不持久化打印机地址（重启后需重新连接）
- 首版只实现 TSPL，不做 CPCL / ESC-POS 指令集
- 不做打印预览与字号自定义
