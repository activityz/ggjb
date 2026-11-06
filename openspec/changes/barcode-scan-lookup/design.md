# 设计：40×30mm 标签上的二维码与扫码定位

## Context

- **打印硬件：40×30mm 热敏标签（打印头 50mm 宽，本次只用 40mm 宽）**。Code-128 编 36 字符 UUID 需要 431 个模块，203dpi 下 1 点/模块就要 53.9mm，宽度直接出界；QR 是二维码，瓶颈从宽度换成"较短的边"，29×29 模块塞进 40×30 毫无压力。这个对照决定了本次用二维码。
- 主键与不可变性：`Items.id` 是 UUID v4（`app/lib/data/db/tables.dart:10`），保存走 `insertOnConflictUpdate`/update，编辑不改 id。
- 主键查询已有索引：`items.id` 是主键，扫码按主键查是最优路径，不需要额外的码列。
- 详情页现状：`ItemDetailPage(itemId)`（`app/lib/features/item_detail/item_detail_page.dart:24`）已是只读展示 + 「编辑」跳 `ItemEditPage` + 返回 `saved == true` 时 `_refresh()`。
- 顶栏：全局 `AppBar` 在 `_HomeShellState._buildAppBar`（`app/lib/features/home/home_shell.dart:101`），`actions` 已有同步与刷新。
- 导出通路：Excel 导出是「临时文件 → `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`」（`app/lib/features/settings/settings_page.dart:781-791`），PNG 沿用同一条路。
- 平台能力：`mobile_scanner 7.5.0` 的 plugin 平台只有 android / ios / macos / web，**没有 Windows**。
- 主题：应用有两套皮肤且默认亮色，但用户可能切深色。二维码必须白底深色，不能跟随皮肤。
- 库结构：本次**不改表**，`schemaVersion` 保持 6，同步 `_verifySchema` 的列数判据不受影响。
- 既有基线：`flutter test` 321 绿、`flutter analyze` 干净。

## Goals / Non-Goals

**Goals:**

- 二维码在 40×30mm 标签上打得出来、手机扫得稳
- 码值与记录身份绑定且与可编辑字段解耦，靠数据结构本身而不是靠维护逻辑
- 相机解码不进测试，定位逻辑走一条可测的窄缝

**Non-Goals:**

- 不引入短码列（宽度已不是约束，40 bit 短码带来的迁移成本换不到收益）
- 不做批量标签排版
- 不做 Windows 摄像头扫码与扫码枪键盘输入
- 二维码不进 Excel

## Decisions

### D1 码型：QR，容错 M，version 3（29×29 模块）

40×30mm / 203dpi 下的尺寸核算：

| 项 | 数值 | 说明 |
| --- | --- | --- |
| 数据 | 36 字符 UUID（Byte 模式 36 字节） | version 3 + 容错 M 容量 42 字节，够 |
| 模块矩阵 | 29 × 29 | 不含静区 |
| 含静区（四边各 4 模块） | 37 × 37 | 37 × 0.625mm = **23.1mm** |
| 模块尺寸 | 5 点 = 0.625mm | 手机识别下限一般 0.4mm，余量充足 |
| 高度分配 | QR 23.1mm + 明文 4mm | 30mm 标签够用 |

不选容错 H：36 字节要升到 version 5（37×37），含静区 45 模块 = 28.1mm，加明文就顶到 30mm 边上，没有余量。M（15% 容错）对贴纸标签足够——标签不会磨掉 15% 面积还能用。

不选 `Barcode` 系列：Code-128 在 40mm 宽上无解（D1 对照见 Context）。

### D2 码值 = `items.id`，零迁移

二维码能装下 36 字符，就没有理由再引一个派生短码：

- **不加 `code` 列** → 不升 `schemaVersion`（保持 6）、不写迁移、不做旧数据回填
- **不动同步** → `_verifySchema` 比列数，列不变就两端仍可互相同步，版本号不同也不影响
- **主键查询天然有索引** → 扫码走 `items.id` 主键，比新增列的普通索引更快

"编辑后二维码不变"不是一条要维护的规则，而是"编辑不改主键"的直接结果。

### D3 渲染：`qr_flutter`，强制白底

`QrImageView(data: item.id, version: QrVersions.auto, errorCorrectionLevel: QrErrorCorrectLevel.M, backgroundColor: Colors.white, padding: EdgeInsets.all(4 * module))`。

三条硬约束：

1. **白底不可跟随皮肤**：深色主题下黑底白码的对比是反的，多数扫码器按"深色模块"阈值判断会失败。弹窗内固定 `Colors.white` 底 + `Colors.black` 前景。
2. **静区不能省**：`padding` 至少 4 个模块（约 2.5mm），少了识别率断崖下降。
3. **尺寸下限 29 模块**：弹窗里按 240dp 最小宽度渲染，模块 ≈ 8dp，屏幕上可直接对扫。

明文 8 组 4 位分段展示（`123E4567-E89B-42D3-A456-426614174000` 太长，分段便于肉眼核对），等宽数字。

### D4 导出 PNG：按 40×30 出图

40 : 30 的逻辑画布取 360 × 270 dp，`toImage(pixelRatio: 4)` → 1440 × 1080 px。

核算：1440px 对应 40mm，QR 占 23.1mm → 832px，除以 29 模块 ≈ **28.7px ≈ 0.8mm/模块**（比屏幕上的 0.625mm 还宽），打印不会被缩到不可读。

落盘 `getTemporaryDirectory()/ggjb-qr-<id前8位>.png` → `SharePlus.instance.share(...)`。

不自己用 canvas 重画：`RepaintBoundary` 保证"屏幕看到的就是导出的"，改字体/留白只改一处。分享失败只提示，不写库。

### D5 扫码入口只在 Android 出现

`scanAvailableProvider = Provider<bool>((_) => !kIsWeb && Platform.isAndroid)`，`home_shell` 读它决定是否插入扫码 `IconButton`。测试用 `overrideWithValue(true/false)` 覆盖两分支——widget 测试跑在桌面宿主上，硬编码 `Platform.isAndroid` 会让「Android 上有按钮」这条 scenario 无法测。

Windows 端不出现按钮：用户已确认只用手机摄像头，不给"按钮在但点了没反应"的假入口。

### D6 扫码页：`MobileScanner`，限定 QR

`ScanPage` 只做：取景 → 拿到第一个 QR 字符串 → `Navigator.pop(raw)`。`formats: [BarcodeFormat.qrCode]` 收窄解码范围。

防重复触发：`ScanCooldown`（同一码 1.5 秒内只放行一次），纯逻辑对象，单独可测，不需要相机。

权限被拒时显示「没有相机权限」+ 去设置的提示，不黑屏。

### D7 定位窄缝

`domain/scan_code.dart` 只做纯函数：`normalizeScanText`（去空白/零宽）、`isItemId`（UUID v4 格式）、`resolveScanText`（合法 → `ScanHit(id)`，否则 `ScanMiss(malformed, raw)`）。查库在 `ItemRepository.resolveScan`：格式合法 → 按主键查（过滤软删）→ 命中 `ScanHit(id)` 或 `ScanMiss(notFound)`。

相机与定位之间只有一条 `String`，测试覆盖全部判定分支，唯一漏掉的是相机解码本身（只能真机验）。

### D8 详情页：只加一个入口，不改只读语义

`AppBar.actions` 在「编辑」左边插二维码图标 → `showDialog(QrDialog(...))`。详情页仍是同一个只读页面，扫码进入与列表进入没有两套逻辑。

## Risks / Trade-offs

- **深色主题下白底弹窗很扎眼** → 这是可扫性的代价，不可省；弹窗本身是短时操作，可接受。
- **36 字符明文在 40mm 上印出来很小** → 明文只用于核对，不是主要输入方式；导出 PNG 里字号按 40mm 宽度留足。
- **`mobile_scanner` 首次 Android 构建拉 CameraX/ML Kit** → 构建变慢、需要网络；构建仍等用户开口。
- **`RepaintBoundary` 截图依赖布局完成** → 导出按钮在弹窗渲染后才可用；测试用 `tester.runAsync` 跑 `toImage`，断言 PNG 魔数与非空长度。
- **`qr_flutter` 4.x 最后发版 2023 年** → 纯 Dart + CustomPainter，无平台代码；若解算冲突，退化为 `qr` 包生成矩阵 + 自绘 `CustomPainter`（`qr 3.0.3` 已在 lock 里）。

## Migration Plan

无数据迁移、无 schema 变更、无同步协议变更。发版顺序无要求，两端版本号不同也能正常同步与合并。回滚：移除两个依赖与新增文件、撤掉两处入口即可。

## Open Questions

无。40×30mm 与 QR version 3 的尺寸已按 203dpi 核算；300dpi 只会更宽松。
