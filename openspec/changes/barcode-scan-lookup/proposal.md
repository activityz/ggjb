# barcode-scan-lookup

## Why

现在要找某一笔记录，只能在明细里按关键词搜、按状态筛、翻列表——手里拿着实物（一台机器、一个配件）时，"对号入座"这一步全靠人回忆标题和买入日期。给每笔记录出一张二维码贴在实物上，扫一下就直接打开它的详情，就把"找记录"从搜索问题变成了无关的问题。

**硬件约束决定了码型**：现场热敏标签机用 **40×30mm** 标签。Code-128 编 36 字符 UUID 需要 431 个模块，203dpi 下即便 1 点/模块也要 53.9mm，远超 40mm 纸宽；换成 QR 后同样的 UUID 只占 29×29 模块（含静区 37×37，5 点/模块约 23mm），40×30mm 放得下还留余量——所以码值可以直接用主键，数据库一动不用动。

## What Changes

- **详情页新增「二维码」按钮**：弹窗展示该记录的 QR 码（编 `items.id` 原文，36 字符 UUID）+ 下方明文；弹窗内可「导出 PNG」（按 40×30mm 比例出图），走既有 `SharePlus` 通路（与 Excel 导出同一模式）
- **QR 参数**：容错等级 M（15%）、version 3（29×29 模块）、四边静区 4 模块、**强制白底黑码**（应用是深色主题，QR 底色不能跟随皮肤）
- **顶栏新增扫码按钮**：`home_shell` 全局 `AppBar`，**只在 Android 显示**（`mobile_scanner` 7.5.0 无 Windows 平台实现），取景页只解 `qrCode` 格式
- **扫码结果直接打开详情**：识别到的码做 UUID 校验后按主键查 `items`（过滤软删），命中 `push` 现有 `ItemDetailPage`，未命中弹「没找到这一笔」
- **只读 → 编辑 → 保存，二维码不变**：扫码进的是现有详情页（只读展示 + 「编辑」跳 `ItemEditPage`），保存后详情刷新；码值就是主键，编辑改不了它
- **新增一个直接依赖**：`qr_flutter ^4.1.0`（它依赖的 `qr` 已由 `mobile_scanner` 带进 lock）；`mobile_scanner ^7.5.0` 用于扫码
- **不改数据库**：不加列、不升 `schemaVersion`（仍是 6）、不改同步字段、不改 Excel 表头
- 版本号 `1.6.0+8` → `1.7.0+9`
- **BREAKING（仅 Android 构建侧）**：`mobile_scanner` 引入 CameraX/ML Kit，首次构建会拉新依赖；两端版本号不同不影响同步（库结构未变）

## Capabilities

### New Capabilities

- `qr-scan`：一笔记录对应一张能打在 40×30mm 标签上的二维码，码值即记录主键；扫码定位到该记录并进入只读详情，编辑保存后二维码不变。

### Modified Capabilities

（无。本次不改 `items` 表结构、不改导入合并判据、不改利润口径，`data-integrity` / `dashboard-drilldown` / `test-infrastructure` 的既有 requirement 行为均不变。）

## Impact

- 生产代码：
  - `app/pubspec.yaml`（`mobile_scanner`、`qr_flutter`、版本号）
  - `app/lib/domain/scan_code.dart`（扫码文本清洗 `normalizeScanText`、主键格式校验 `isItemId`、`resolveScanText`）
  - `app/lib/app/providers.dart`（`scanAvailableProvider`，供 widget 测试 override）
  - `app/lib/data/dao/item_dao.dart`（按主键取未删除记录）
  - `app/lib/data/repo/item_repository.dart`（`resolveScan` 串起校验与查库）
  - `app/lib/features/home/home_shell.dart`（顶栏扫码按钮 + 扫完跳详情）
  - `app/lib/features/scan/scan_page.dart`（`MobileScanner` 取景页，QR 限定、防重复触发）
  - `app/lib/features/item_detail/item_detail_page.dart`（二维码按钮 + 弹窗 + 导出 PNG）
  - `app/lib/features/barcode/qr_dialog.dart`（二维码渲染、40×30 尺寸参数与 PNG 落盘）
- 测试：`scan_code_test`（清洗与 UUID 校验）、`item_dao_scan_test`（按主键查：命中/软删/查无）、`barcode_dialog_test`（码值 = 主键、存在 QR 组件、导出的 PNG 字节）、`home_shell_scan_test`（平台开关与命中/未命中）
- 依赖与平台：`mobile_scanner` 的 Android 清单自带 `CAMERA` 权限；`minSdk 23` 已满足；iOS/macOS 不构建
- 不影响：利润计算、看板统计、列表页与筛选、字典、Excel 往返、同步协议（列结构与 v6 完全一致）

## 非目标

- 不做批量打印/标签排版（一次只导出一张 PNG）
- 不做 Windows 摄像头扫码，也不做扫码枪键盘输入兜底
- 二维码不进 Excel，不参与导入导出
- 不做扫码历史、扫码统计
- 不再引入短码列：码值即主键，没有"重新生成"这回事
