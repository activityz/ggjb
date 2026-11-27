# 设计

## 口径与根因

`attachments` 表里 `bytes`（原图）与 `thumb`（缩略图）是两列，`thumb` 可为空。视图层 `_ThumbView` 只订阅 `attachmentThumbProvider`，而它的 `bytes == null` 分支被当成「加载中」（`CircularProgressIndicator`）。缩略图为空是**持久状态**，所以转圈永不停止。

实证（用户机器上的库，只读打开）：

```
attachment stats: total=1  thumb_null=1  thumb_empty=0  bytes_null=0
role=warranty_card count=1 thumb_null=1
sample: ('1304d5c9-…', 'warranty_card', 91556, None, 1795492624)
```

写入侧原因同样明确：`WarrantyCardService.save()` 的 `AttachmentsCompanion.insert(...)` 没有 `thumb` 字段。

## D1 两层都改：视图兜底 + 写入补缩略图

- **视图兜底**（必须有）：历史数据、跨设备同步、将来任何新写入路径都可能留空 `thumb`。只补写入，老图还是转圈。
- **写入补缩略图**（也必须有）：让保修卡与其它附件一致，避免每次显示都去解码 90KB+ 原图；也让缩略图列的数据自洽。

被否：只在写入侧补（老数据照样转圈）；只在视图侧兜底（永远多解一张大图，且数据仍然不规范）。

## D2 「空缩略图」不能和「加载中」共用一个占位

`FutureProvider` 的三态必须分开表达：

- `loading` → 转圈（真的在查库）
- `data(null)` → **不是加载中**：先回退原图，原图也空则「无预览」
- `error` → 同「无预览」，不抛给用户看堆栈

落法：`_ThumbView` 里 `async.when(loading: 转圈, error: 无预览, data: (thumb) => thumb == null || thumb.isEmpty ? _fallbackToFullImage() : Image.memory(thumb))`，`_fallbackToFullImage` 订阅 `attachmentBytesProvider` 并复用同一套尺寸。

被否：把 `attachmentThumbProvider` 改成「thumb 为空时返回 bytes」——那会让 `attachmentBytesProvider` 与它语义重叠，且缩略图缓存里塞进原图，后面想加内存缓存会踩坑。兜底留在视图层，provider 只管取它名字对应的东西。

## D3 「无预览」用静态占位

断图标（`Icons.image_not_supported_outlined`）+「无预览」8px 灰字，不带动画。**任何**情况都不再出现旋转指示器常驻。

## D4 logo 资源：裁到内容边界再入库

原图 563×407，大量白边，实际内容 bbox 为 `(28,167)-(534,275)`（507×109，白底 254/255）。裁到 bbox 后白底保留：卡面本身是纯白，白底贴白底不会出现灰框，也就不必做去背（去背反而会让抗锯齿边缘发脏）。

- 资源路径：`app/assets/brand/shop_logo.png`（裁切后约 507×109）
- `pubspec.yaml` 声明 `assets: [assets/brand/]`
- 尺寸：卡面逻辑高 26 → 宽约 121；3 倍截图后 78px 高，够清晰（原图 109px 高，不放大）

被否：把 logo 直接内联成 base64 —— 不可维护；用 SVG —— 需要新增依赖。

## D5 卡头布局与高度预算

现状卡头是单行：`保修卡(20px) + 店内保修凭证 + Spacer + 售出日期`。改成：

```
[logo 高26]              [保修卡(13px, w800) / 店内保修凭证(8.5px, 灰) 右对齐]
[售出日期 8.5px 灰，右对齐，与上一行同列]
```

- logo 与右侧两行同高（26）以内，整行高度基本不变，卡面其余部分（型号/成色/序列号、商家保修块、三条条款、二维码）一行不动。
- 「保修卡」字号从 20 降到 13 —— 品牌 logo 已经承担视觉识别，文档名不再需要霸占标题位；否则 360 宽里 logo 与 20px 标题必然打架。
- 卡面高度有 `Spacer` 兜底，但仍以「渲染无 overflow」为硬验收（widget 测试里 overflow 会抛异常）。

## D6 截图前必须预热 logo

`warranty_card_dialog` 是「离屏 Overlay → `endOfFrame` → 60ms → `renderBoundaryPng`」。`Image.asset` 首帧是异步解码，冷启动第一张卡极可能截到空白 logo。所以生成前 `await precacheImage(const AssetImage(logoAsset), context)`，再做截图。测试里同样要先 `precacheImage` 再断言像素。

## D7 seam（先报备，等确认再写第一个测试）

| # | public 边界 | 抓住什么 | 漏掉什么 |
| --- | --- | --- | --- |
| S1 | `WarrantyCardService.save()` → 读回 `attachments` 行 | 保存后 `thumb` 非空、长边 ≤256 | 缩略图画质 |
| S2 | `ItemDetailPage` + 真库（thumb=NULL, bytes 有）→ 图片模块 | 不再有转圈、原图能显示 | 具体像素 |
| S3 | 同上，thumb 与 bytes 都为 NULL | 出现「无预览」、无转圈 | — |
| S4 | `WarrantyCardView` 渲染 → `renderBoundaryPng` | 卡头有 logo 像素、尺寸 1080×1620、无 overflow | 印刷色彩 |
| S5 | 详情页缩略图真实点击（`tester.tap`）打开大图 | 点击链路没被手势层吃掉（上次的坑） | — |

S2/S3 走「真库 + 真 provider + 真页面」，不 mock 内部协作者；断言值来自 spec 的字面量（`无预览`、`thumb == null`、`1080×1620`）。
