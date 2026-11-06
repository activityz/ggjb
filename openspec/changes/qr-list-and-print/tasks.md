# Tasks

## 0. 测试缝报备

- [x] 0.1 确认下表为本次全部测试 seam；表外不写测试

  | seam（public 边界） | 抓住什么 | 漏掉什么 |
  | --- | --- | --- |
  | `buildLabelCommands(code, title)`（纯函数） | 尺寸行 `SIZE 40 mm, 30 mm`、`QRCODE` 参数、标题截断、明文、`PRINT 1,1` 结尾 | 打印机实际出纸效果 |
  | `printerProvider` 状态机（MethodChannel 用假 handler） | 未连接 / 连接中 / 已连接 / 失败四态，以及打印前的连接检查 | 真实蓝牙链路 |
  | `QrDialog` 的打印按钮 | 平台显隐、未连接时提示并跳转、已连接时发出指令 | 蓝牙写入时序 |
  | `ItemListPage` 每行的二维码按钮 | 点按钮出对应记录的弹窗、点整卡仍进详情 | 真机触摸热区 |

## 1. Android 原生通道与权限

- [x] 1.1 `AndroidManifest.xml` 补 `BLUETOOTH_SCAN`（`neverForLocation`）/ `BLUETOOTH_CONNECT` / 旧系统回落权限与 `uses-feature`；`flutter analyze` 与 `flutter test` 不受影响
- [x] 1.2 `MainActivity.kt` 注册 `ggjb/printer` MethodChannel，实现 `scan` / `connect` / `disconnect` / `isConnected` / `write`：蓝牙操作走后台线程、连接前 `cancelDiscovery`、同一时刻只保留一个 socket
- [x] 1.3 `app/lib/features/scan/printer_channel.dart` 封装 MethodChannel（类型转换、异常转 `PrinterException`），Android 之外调用直接抛「本平台不支持」

## 2. TSPL 指令（纯函数）

- [x] 2.1 `app/lib/features/barcode/label_commands.dart` 实现 `buildLabelCommands`，配 `app/test/features/barcode/label_commands_test.dart`：断言含 `SIZE 40 mm, 30 mm`、`QRCODE 73,8,L,6,A,0`、以 `PRINT 1,1` 结尾
- [x] 2.2 同一测试覆盖：标题超 16 字被截断、空标题不崩、返回 `List<int>` 且每字节在 0–255

## 3. 连接状态与打印服务

- [x] 3.1 `printerProvider` + 四态状态机，`app/test/features/scan/printer_provider_test.dart` 用假 MethodChannel handler 覆盖：未连接打印被拦下、连接成功转 connected、连接抛错转 failed
- [x] 3.2 `app/lib/features/scan/printer_page.dart`：扫描列表、连接、断开、校准走纸（`GAPDETECT`）、权限被拒时的整页提示

## 4. 入口与文档

- [x] 4.1 `QrDialog` 显示标题、加「打印」按钮（`printAvailableProvider` 控制显隐）；未连接时提示并跳打印机页；`app/test/features/barcode/qr_dialog_test.dart` 增这两条
- [x] 4.2 `item_list_page.dart` 标题行右侧加二维码按钮、标题传进弹窗、长按菜单加一项；`app/test/features/item_list/item_list_page_test.dart` 增「点二维码出弹窗」「点整卡仍进详情」
- [x] 4.3 `settings_page.dart` 增「标签打印机」入口
- [x] 4.4 `README.md` 补打印说明（仅 Android、TSPL、重启后需重连），`docs/agent/memory.md` 记两条：不经 pub 依赖走原生通道的理由、TSPL 布局参数

## 5. 收尾校验

- [x] 5.1 用 fvm 绝对路径跑 `flutter analyze`，输出必须 `No issues found!`
- [x] 5.2 用 fvm 绝对路径跑 `flutter test`，全量通过且无 skip，数字写回本文件与汇报
- [x] 5.3 `openspec validate qr-list-and-print --strict` 通过
- [x] 5.4 逐项核对本文件与 `specs/qr-print/spec.md`、`specs/qr-scan/spec.md` 的 scenario 一一对应
