# 提案：缩略图兜底 + 保修卡加店铺 logo

## 为什么（Why）

### 1. 详情页「图片」模块有一张图永远转圈（缺陷）

用户在商品详情页看到图片模块里那张图**一直转圈**，不是慢，是永远出不来。根因有两层，缺一不可：

- **写入层**：保修卡图片由 `WarrantyCardService.save()` 直接写 `attachments`，只给 `bytes`，`thumb` 留空。库里实证：该商品唯一一条附件 `role=warranty_card`、`bytes` 有 91556 字节、`thumb` 为 **NULL**。
- **视图层**：`_ThumbView` 只看 `attachmentThumbProvider`，把「没有缩略图」当成「还在加载」，于是渲染 `CircularProgressIndicator`。而没有缩略图是**永久状态**，转圈也就永久。

只补写入层不够：历史数据、从另一台设备同步来的附件、以及任何绕过 `ItemRepository.addImage` 的写入路径都会留下空 `thumb`。所以两层都要修。

### 2. 保修卡要带店铺 logo（新增）

店主给了一张「保定天怡数码」的 logo（563×407，实际内容 507×109），要求印在保修卡上。卡是给买家的凭证，有招牌才有辨识度。

## 改什么（What Changes）

- `_ThumbView`：缩略图为空 → 回退读原图字节，按缩略图尺寸渲染；原图也为空 → 显示「无预览」静态占位。任何情况下都不再无限转圈。
- `WarrantyCardService.save()`：保存保修卡时同时生成并写入 `thumb`（长边 256 的 PNG），与其它附件行为一致。
- 保修卡卡头：左侧店铺 logo（高 26、白底、等比），右侧保留「保修卡 / 店内保修凭证」与售出日期。
- 新增资源 `app/assets/brand/shop_logo.png`（从店主原图裁到内容边界，白底保留），并在 `app/pubspec.yaml` 声明 `assets/brand/`。
- 生成保修卡前 `precacheImage` logo，否则导出的 1080×1620 PNG 里没有 logo。

## Capabilities

- **New**：`item-media` —— 附件缩略图的读取与兜底规则、保修卡入库时的缩略图写入
- **Modified**：`merchant-warranty` —— 卡面构图加入店铺 logo

（`merchant-warranty` 的基线 spec 目前仍在未归档的 `merchant-warranty-card` change 里，不在 `openspec/specs/`，故本 change 以 ADDED 增量给出，归档时并入同一份 spec。）

## Impact

- 代码：`app/lib/features/item_detail/item_detail_page.dart`（`_ThumbView`）、`app/lib/features/warranty/warranty_card_service.dart`、`app/lib/features/warranty/warranty_card_view.dart`、`app/lib/features/warranty/warranty_card_dialog.dart`、`app/pubspec.yaml`
- 资源：新增 `app/assets/brand/shop_logo.png`
- 数据库：**不改表结构、不升 `schemaVersion`**（`attachments.thumb` 早已存在）
- 同步：`thumb` 本来就在快照里，无协议变更
- 已生成的旧保修卡不用重做：视图层兜底即可正常显示；只在重新生成后才写上新 `thumb`

## 非目标

- 不做缩略图后台回填/懒生成（旧附件按需回退原图，百 KB 量级无感）
- 不改图片模块的角色过滤（保修卡既在专用区块、也在图片模块，保持现状）
- 不动二维码、打印、导出、Excel
