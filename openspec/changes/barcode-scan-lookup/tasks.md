# Tasks

## 0. 测试缝报备（QR 方案，开工即按此执行）

- [x] 0.1 确认下表为本次全部测试 seam；表外不写测试

  | seam（public 边界） | 抓住什么 | 漏掉什么 |
  | --- | --- | --- |
  | `normalizeScanText` / `isItemId` / `resolveScanText` | 脏字符清洗、UUID 格式判定、malformed 分支 | 相机解码 |
  | `ItemDao.findActiveById` | 命中、软删过滤、查无此条 | 上层跳转 |
  | `scanAvailableProvider` | 平台开关两分支 | 真实平台判定 |
  | `QrDialog` | 明文码值 = 主键、存在 QR 组件、白底 | 打印后的实际尺寸 |
  | 导出 PNG 字节 | 非空 + PNG 魔数 | 打印机上的可扫性 |
  | `ScanCooldown` | 同一码 1.5s 内只放行一次 | 相机多帧真实时序 |
  | `HomeShell` 顶栏（override `scanAvailable`） | 有/无按钮、命中跳详情、未命中提示 | 真机相机权限弹窗 |

## 1. 依赖与领域层

- [x] 1.1 `app/pubspec.yaml` 加 `qr_flutter: ^4.1.0`（`mobile_scanner ^7.5.0` 已在），版本号 `1.6.0+8` → `1.7.0+9`；用 `D:/develop/flutter/fvm/versions/3.47.1/bin/flutter.bat pub get` 验证解算通过（`image` 仍须钉在 4.3.0，`archive` 仍须是 3.x）
- [x] 1.2 `app/lib/domain/scan_code.dart`：`normalizeScanText` / `isItemId`（UUID v4）/ `resolveScanText`，配 `app/test/domain/scan_code_test.dart`（断言值用写死的 UUID 字面量，不按实现重算）
- [x] 1.3 `scanAvailableProvider` + `app/test/app/providers_test.dart` 覆盖 override 前后两个取值

## 2. 按码定位记录

- [x] 2.1 `ItemDao.findActiveById`（按主键取单条并过滤 `deletedAt`）+ `app/test/data/item_dao_scan_test.dart` 覆盖命中 / 软删 / 查无（drift 用 `NativeDatabase.memory()`）
- [x] 2.2 `ItemRepository.resolveScan(String raw)` 串起格式校验与查库，返回 `ScanHit(itemId)` / `ScanMiss(reason)`；`app/test/data/item_repository_test.dart` 增 malformed / notFound / 命中三态

## 3. 详情页二维码与导出

- [x] 3.1 `app/lib/features/barcode/qr_dialog.dart`：`QrImageView(data: item.id, errorCorrectionLevel: M, 白底黑码, 静区 4 模块)` + 分段明文；`app/test/features/barcode/qr_dialog_test.dart` 断言明文 = 主键、存在 `QrImageView`、底色为白
- [x] 3.2 弹窗内「导出 PNG」：`RepaintBoundary.toImage(pixelRatio: 4)` → 临时目录 → `SharePlus`；`app/test/features/barcode/qr_export_test.dart` 断言字节非空且 PNG 魔数正确
- [x] 3.3 `ItemDetailPage` 顶栏加二维码入口；`app/test/features/item_detail/qr_button_test.dart` 覆盖「点击后出现二维码弹窗」
- [x] 3.4 `README.md` 功能清单补「二维码生成与扫码定位」，按仓库既有写法

## 4. 扫码页与顶栏入口

- [x] 4.1 `ScanCooldown`（同一码 1.5s 内只放行一次）+ `app/test/features/scan/scan_cooldown_test.dart`
- [x] 4.2 `app/lib/features/scan/scan_page.dart`（`MobileScanner` 限定 `BarcodeFormat.qrCode`，识别后 pop 原始码值；权限被拒给提示）
- [x] 4.3 `home_shell` 顶栏按 `scanAvailableProvider` 插入扫码入口，命中 push `ItemDetailPage`，未命中弹「没找到这一笔」；`app/test/features/home/home_shell_scan_test.dart` 覆盖有按钮 / 无按钮 / 命中 / 未命中
- [x] 4.4 `docs/agent/memory.md` 记两条环境事实：`mobile_scanner` 无 Windows 平台实现；现场标签纸 40×30mm，二维码必须白底（不跟深色主题）

## 5. 收尾校验

- [x] 5.1 用 fvm 绝对路径跑 `flutter analyze`，输出必须 `No issues found!`
- [x] 5.2 用 fvm 绝对路径跑 `flutter test`，全量通过且无 skip，数字写回本文件与汇报
- [x] 5.3 `openspec validate barcode-scan-lookup --strict` 通过
- [x] 5.4 逐项核对本文件与 `specs/qr-scan/spec.md` 的 scenario 一一对应，未覆盖的写明原因
