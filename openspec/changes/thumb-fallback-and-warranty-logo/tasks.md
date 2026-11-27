# 任务

> 纪律：按 TDD 排序，一个 seam 一个循环；seam 表在 design.md D7，写第一个测试前已报备。

## 1. 资源与依赖

- [x] 1.1 把店主给的 logo 裁到内容边界（原图 `C:\Users\25852\Desktop\Snipaste_2026-11-24_12-33-36.png`，903×473，内容 bbox `(49,169)-(860,344)` → 裁出 **811×175**，白底保留），存为 `app/assets/brand/shop_logo.png`
- [x] 1.2 `app/pubspec.yaml` 声明 `flutter: assets: [assets/brand/]`
- [x] 1.3 版本号 `1.10.0+12` → `1.10.1+13`，`installer/ggjb.iss` 的 `#define AppVersion` 同步为 `1.10.1`

## 2. 红灯（先红）

- [x] 2.1 S1 `warranty_card_service_test.dart`：`save()` 后该附件 `thumb` 非空，且解码长边 = 256、宽高比不变 —— 红：`Expected: not null / Actual: <null>`
- [x] 2.2 S2 `thumb_fallback_test.dart`：真库插一条 `thumb=NULL`、`bytes` 有内容的附件 → 打开详情页 → 不出现 `CircularProgressIndicator`，出现 `MemoryImage` —— 红：找到 1 个 `CircularProgressIndicator`（复现用户报的现象）
- [x] 2.3 S3 同上文件：`thumb` 为空且 `bytes` 为零长度 → 出现「无预览」，无转圈 —— 红：找不到「无预览」。**偏差说明**：`attachments.bytes` 是 NOT NULL 列，「两列都为 NULL」在库里表达为零长度 blob，spec 的措辞已同步改掉
- [x] 2.4 S4 `warranty_card_view_test.dart`：卡头有 `AssetImage(shopLogoAsset)`、截图 1080×1620、卡头区域深色像素 > 500、无 overflow —— 红：编译期 `Undefined name 'shopLogoAsset'`
- [x] 2.5 S5 详情页缩略图 `tester.tap` → 打开大图（`InteractiveViewer`）—— 真实指针，防手势被内层吃掉

## 3. 实现（后绿）

- [x] 3.1 `_ThumbView`：`loading` 才转圈；空 thumb 回退 `attachmentBytesProvider`；两者皆空 / `error` 显示「无预览」静态占位
- [x] 3.2 `WarrantyCardService.save()`：用 `image` 包把 PNG 缩到长边 256 生成 `thumb` 一并写入；解不开的字节返回 null（不让保存整体失败）
- [x] 3.3 `WarrantyCardView`：卡头改为「左 logo（高 26，等比）+ 右侧保修卡(13px)/店内保修凭证/售出日期」，`shopLogoAsset` 常量导出
- [x] 3.4 `warranty_card_dialog._renderPng`：截图前 `precacheImage` logo（含 `mounted` 守卫）

## 4. 验证

- [x] 4.1 `flutter test` → `+446: All tests passed!`（基线 441 + 本次 5 条）
- [x] 4.2 `flutter analyze` → `No issues found!`
- [x] 4.3 `openspec validate thumb-fallback-and-warranty-logo --strict` → `is valid`
- [x] 4.4 用用户真实库**副本**验证（`AppDatabase(NativeDatabase(copy))` + 真详情页）：该记录 `thumb` 为 NULL、`bytes` 91556 字节 → `SPINNERS=0`、`MEMORY_IMAGES=2`；一次性测试跑完即删，不入库
- [ ] 4.5 手工核对（待用户）：详情页图片模块不再转圈；新生成的保修卡带 logo、尺寸 1080×1620

## 5. 收尾

- [x] 5.1 `README.md` 版本历史补 1.10.1 一行（缩略图兜底 + 保修卡 logo）
- [x] 5.2 `docs/agent/memory.md` 记一条：`attachments.thumb` 可为空，视图必须回退原图，否则永久转圈
- [ ] 5.3 出包（等用户开口）：`ggjb-1.10.1-windows-setup.exe` / `ggjb-1.10.1-windows-x64.zip` / `ggjb-1.10.1-release.apk`
