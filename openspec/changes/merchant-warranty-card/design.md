# 设计：商家保修、序列号与保修卡

## 上下文

- `Items` 表当前 26 列（v6 末三位 `warranty_status/start/end`），`tables.dart:54-60` 有一条硬约束：新列只能追加在声明末尾，否则新建库（按声明顺序）与升级库（ALTER 追加）列序不一致，`sync/merge.dart` 的 `_verifySchema` 按列位逐位比对会判两端不兼容。
- 上一版保修三态的行为契约落在 `openspec/changes/add-warranty-fields/specs/warranty-tracking/spec.md`，该 change 尚未归档（tasks 27/29），`openspec/specs/` 里还没有这个 capability。**本 change 不碰它的 delta**，只在自己的 capability 里声明两组保修互不覆盖。
- 已有可复用件：`features/barcode/qr_export.dart` 的 `renderBoundaryPng`（RepaintBoundary → PNG）、`features/barcode/qr_dialog.dart` 的二维码展示与导出通路、`Attachments` 表的 BLOB 存图（含缩略图、软删除、随商品级联删除、随同步走）。
- 编辑页 `_dateField` + `showDatePicker`、详情页「标记已卖出」弹窗（`item_detail_page.dart:566`）都是现成的日期输入与弹窗样板。

## 决策

### D1 商家保修用两个独立日期列，不复用厂家保修三态

厂家保修回答「厂商还剩多久」，商家保修回答「本店承诺到哪天」；两者起止通常不同，且一个是三态枚举、一个是区间。合成一套的话，收货议价时抄下的厂家日期会在出货时被承诺日期覆盖，反过来也一样。

字段：`merchantWarrantyStart` / `merchantWarrantyEnd`，均 `dateTime().nullable()`。**不给**商家保修做状态枚举：它的语义就是「有承诺 + 有区间」，不存在「不知道到哪天但确实在保」这种厂家保修的含糊情形。

> 否决：把现有 `warranty_status` 改造成「商家保修状态」。收货场景仍要记厂家保修，改造成商家保修等于丢掉一个既有用途。

### D2 库内列名保持 `warranty_*` 不变，只改界面与导出用词

用户看到的是「厂家保修」，库里的 `warranty_status` 是内部标识。改列名要么走 SQLite 的 `ALTER TABLE RENAME COLUMN`，要么让 drift 重建表（`items` 有外键被 `expenses`/`attachments` 引用，重建要临时关外键、迁移子表引用，风险与收益不成比例）。

因此：`tables.dart` 里给这三列补一行注释「语义 = 厂家保修」，界面文案、Excel 表头改用「厂家保修」，Excel 导入同时认旧表头（详见 D9）。

> 否决：v7 迁移里顺手 `RENAME COLUMN`。改名不会带来任何用户可见收益，却把一次纯加列迁移变成有重建风险的迁移。

### D3 序列号是文本列，与既有「序列号/铭牌」照片附件并存

`AttachmentRole.serial` 存的是铭牌照片（证明），`items.serial` 存的是可查、可印、可搜索的文本（凭据）。两者不是替代关系：照片在详情页图片区，文本在「时间与渠道」卡片。

不做唯一约束：同一串号会被录错再修正，拆机件也可能重号，用唯一索引只会让用户卡在保存上。

### D4 v7 迁移：三列追加末尾，逐列判存

顺序固定：`serial` → `merchantWarrantyStart` → `merchantWarrantyEnd`，紧跟 `warrantyEnd` 之后。

```dart
if (from < 7) {
  await _addColumnIfMissing(m, items, items.serial);
  await _addColumnIfMissing(m, items, items.merchantWarrantyStart);
  await _addColumnIfMissing(m, items, items.merchantWarrantyEnd);
}
```

沿用 v6 的 `_addColumnIfMissing`（先查 `PRAGMA table_info` 再 add），保证中断重跑幂等。三列全 nullable，旧行升级后为 NULL = 没填，不做回填。不建索引：两组保修都不参与筛选与统计。

### D5 必填校验收口成一个纯函数，界面两处调用

```dart
/// 返回 null 表示通过，否则是给用户看的错误文案。
String? merchantWarrantyError(
  ItemStatus status,
  DateTime? start,
  DateTime? end,
);
```

规则：`status.isRealized`（sold / completed）且任一日期为空 → 返回缺失项文案；否则 null。日期顺序（到期早于开始）不拦，与厂家保修同一口径：自用工具不替用户改事实。

调用点：编辑页 `_save()`、详情页「标记已卖出」确认前。**Excel 导入不调用**——导入是历史数据迁移，旧文件没有这两列，一旦强制必填，所有旧表都导不进来。

### D6 默认值：开始 = 当天，到期 = 开始 + 1 年（闰日取月末）

`addOneYear(DateTime d)` → `DateTime(d.year + 1, d.month, d.day)`，若结果月份与 `d.month` 不一致（2 月 29 日滚到 3 月 1 日），回退到「该年该月最后一天」。

预填时机：状态从非卖出切到卖出且两日期都为空时预填；已有值不覆盖（用户改过的不能被一键重置）。`_onStatusChanged` 里判断。

### D7 保修卡存为图片附件，角色 `warranty_card`

`AttachmentRole` 加一个值 `warrantyCard('warranty_card', '保修卡')`。这一列是文本枚举，转换器 `fromDb` 有 `orElse` 兜底，所以**加值不需要升 schema**，旧设备读到未知角色会落到 `other`，不会崩。

同商品只留一张：生成前把该商品所有 `role == warrantyCard` 的未删除附件软删（`deletedAt = now`），再插新行。软删而非物理删，才能让删除动作随同步传到另一台设备。

> 否决：图片存文件、`note` 里存路径。换机器/重装后图片全丢，而且 `note` 会被导出进 Excel。
> 否决：单开一张 `warranty_cards` 表。为了 n:1 的可能多一张表参与同步与级联，收益为零。

### D8 卡面渲染：同一个 widget 渲染两份，一份离屏截图、一份缩放预览

卡面 `WarrantyCardView`（`features/warranty/`）按固定逻辑尺寸 360×540 布局，`MediaQuery.textScaler` 锁 1.0，字体不随系统放大（截图不能变形）。

生成流程：

1. 弹窗里显示 `FittedBox` 缩放后的预览，底部「生成保修卡」；
2. 弹窗的 `Stack` 里另放一份同参数的 `WarrantyCardView`，`Positioned(left: -1200)` 移出可视区，外面包 `RepaintBoundary`；
3. 点确认 → `renderBoundaryPng(key, pixelRatio: 3)` → 1080×1620 PNG；
4. 先 `save` 商家保修日期（用户可能改过），再插附件行，最后刷新。

移出屏幕而非 `Offstage`：`Offstage` 不参与布局与绘制，`toImage` 拿不到内容。

> 否决：用 `screenshot` / `rendering` 这类第三方包。现有 `renderBoundaryPng` 已验证可用（二维码导出在用），不引新依赖。

### D9 Excel：三列新增、三列改名，导入双表头

- 新增表头：「序列号」「商家保修开始」「商家保修到期」，插在「旧机抵扣」之后、厂家保修三列之前。
- 改名：`保修状态 → 厂家保修状态`、`保修开始 → 厂家保修开始`、`保修到期 → 厂家保修到期`。
- 导入建别名表：`{'保修状态': 厂家保修状态, '保修开始': 厂家保修开始, '保修到期': 厂家保修到期}`，新名优先，旧名回退。导出只写新名。
- 三新列全缺 → 留空，不报错；`保修状态` 列非法值仍按既有规则报行级错误（不静默当无保修）。

### D10 入口与状态

| 位置 | 未卖出 | 已卖出、无卡 | 已卖出、有卡 |
| --- | --- | --- | --- |
| 列表行内图标 | 置灰，点击提示「先标记卖出」 | 生成保修卡 | 查看保修卡 |
| 列表长按菜单 | 同上 | 生成保修卡 | 查看保修卡 |
| 详情页区块 | 不显示 | 生成保修卡 + 说明 | 查看保修卡 + 重置保修卡 |

列表行内已有二维码图标，新增图标用 `Icons.receipt_long`，与二维码同为 32×32 紧凑按钮，放在二维码左侧。

### D11 老数据补填

升级前已卖出、商家保修为空的商品：详情页在「时间与渠道」卡片里显示一行可点击的「商家保修 未填写 ›」，点开与「标记已卖出」同款的日期弹窗，只写这两个日期。这条路径不经过完整保存校验，不要求用户改别的东西。

## 测试 seam（写第一个测试前需用户确认）

| seam | 抓什么 | 漏什么 |
| --- | --- | --- |
| `merchantWarrantyError`（domain 纯函数） | sold/completed + 缺开始/缺到期/都缺各自文案；inStock 不拦 | 不测 UI 文案排版 |
| `addOneYear`（domain） | 2026-11-24 → 2027-11-24；2028-02-29 → 2029-02-28 | 不测时区 |
| `ItemRepository.save`（内存库） | 三列写入后 `load()` 读回一致；只写商家保修不动厂家保修 | 不测 Companion 生成细节 |
| 编辑页（widget） | 状态切「已卖出」→ 两日期自动预填；清空到期点保存 → 被拦并提示 | 不测 `showDatePicker` 系统弹窗内部 |
| 标记已卖出弹窗（widget） | 预填当天/+1年；改到期后落库 | 不测置换开关既有逻辑 |
| `WarrantyCardView`（widget） | 标题、序列号、商家保修两日期、三条条款都在；不含买入价/卖出价/利润字样 | 不测最终像素级排版 |
| 生成服务（widget + 内存库） | 截图字节以 PNG 魔数开头、宽高 1080×1620；落库后可查；再生成一次只剩一张 | 不测真机相册/分享 |
| 重置（service） | 附件被软删，商家保修日期保留 | 不测同步对端 |
| Excel（纯 Dart） | 新表头往返；旧表头仍能读厂家保修；缺三新列不报错 | 不测 Excel 样式 |
| v6 → v7 迁移（内存库） | 旧行三新列为 null、原字段不变；升级中断重跑幂等 | 不拷真机库文件 |

断言值一律写字面量（`DateTime(2027, 11, 24)`、`'2029-02-28'`），不按实现重算。

## 风险

- **两端版本错配**：v7 与 v6 无法互相同步（列数不同）。发版号必须能看出不兼容，汇报时提醒两端一起升。
- **离屏截图失败**：`renderBoundaryPng` 在拿到 `null`（还没布局完）时会静默返回空。缓解：截图前 `await` 两帧（`WidgetsBinding.instance.endOfFrame`），失败时给明确提示而不是插一条 0 字节附件。
- **老数据被必填卡住**：升级前已卖出的商品一进编辑页保存就会被拦。缓解：详情页补填入口（D11）；且提示文案直接说「缺少商家保修到期」，用户知道去点哪。
- **Excel 旧表头漏别名**：只兼容三个旧名，若用户手工把列改成「厂保状态」这类写法仍会当未知列忽略。这是既有行为（未知列忽略），不额外扩大兼容面。
- **保修卡体积**：1080×1620 PNG 约 200–400 KB，随附件同步会给同步包增重。单张可接受；不做压缩转码，避免文字发虚。
