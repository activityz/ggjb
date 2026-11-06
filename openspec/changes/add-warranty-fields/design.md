# 设计：保修状态与保修日期

## 上下文

- `Items` 表当前 22 列，末三位是 v4 追加的 `battery_health` / `list_price_cents` / `trade_in_cents`；`tables.dart` 里有一条硬注释：新列**必须追加在表定义最后**，否则新建库（按声明顺序建）与升级库（ALTER 追加到末尾）列序不一致，`sync/merge.dart:194 _verifySchema` 按列序逐位比对会直接判两端不兼容。
- `schemaVersion` 现在是 5（`app/lib/data/db/app_database.dart:35`），迁移按 `if (from < N)` 递增段落写，段落之间互不依赖。
- 编辑页 `_dateField(label, value, onTap)` + `showDatePicker` 是现成的日期输入组件；卖出侧 `if (isSellSide) ...[...]` 是现成的「按状态条件展开字段」先例。
- 详情页 `app/lib/features/item_detail/item_detail_page.dart:305-320` 在「时间与渠道」`GlassCard` 里用 `_kv` 逐行展示，`if (item.batteryHealth != null)` 是现成的条件行写法。
- Excel 侧 `excel_rows.dart` 的 `itemHeaders` 是导入导出共用表头，导入按表头名定位（`_cell(row, itemIndex[header])`），所以旧文件缺列时 `indexOf` 返回 -1，读列时需要显式挡掉。
- 既有测试基线：`flutter test` 286 绿（2026-11-04），widget 测试三件套（theme splashFactory / ProviderScope 三 override / drift settle 6 轮）。

## 决策

### D1 保修信息直接挂在 `items` 行上，不建保修表

一台机器只有一段当前保修（二手机转手后保修也不重置），没有「多次保修记录」这种事实。建子表会为了 n:1 的可能带来 join、同步表清单、级联删除三处成本，而收益是零。三列 nullable 即可，跟 `battery_health` 同一层级。

> **实现偏差（落地时定的）**：两个日期确实 nullable，但 `warrantyStatus` 做成了
> `text().map(WarrantyStatusConverter()).withDefault(const Constant('none'))`，
> 不是 nullable 列。理由两条：① 列可空的话实体字段就是 `WarrantyStatus?`，UI / 导出 /
> 同步十余处都要判空，而「空」的唯一含义本来就只有「无保修」；② `ALTER TABLE ADD
> COLUMN` 带常量默认值时不重写旧行，旧库升级后旧行读出来仍是「无保修」，与新建库一致。

### D2 三列追加在 `Items` 声明末尾，`schemaVersion` 5 → 6

顺序：`warrantyStatus` → `warrantyStart` → `warrantyEnd`，紧跟 `tradeInCents` 之后。迁移段落：

```dart
if (from < 6) {
  await m.addColumn(items, items.warrantyStatus);
  await m.addColumn(items, items.warrantyStart);
  await m.addColumn(items, items.warrantyEnd);
}
```

三个 `addColumn` 的顺序必须与表声明顺序一致，这条由 `_verifySchema` 的列序比对兜住——写反了不会立刻报错，会在第一次跨端同步时才炸。

不加重填、不建索引：保修日期不参与筛选与统计（本次范围外），建索引等于为未来猜一个查询。

### D3 状态用三态枚举 + TypeConverter，与既有枚举同款

```dart
enum WarrantyStatus { none('none', '无保修'), active('active', '在保'), expired('expired', '已过保') }
```

库内存 `dbValue` 文本，复用 `ItemStatusConverter` 的写法（`fromDb` 找不到时 `orElse` 回落到 `none`）。**不用** 布尔列：布尔表达不了「已过保」这个用户想显式标记、且详情页要单独展示的第三态；也**不用** 由 `warranty_end` 推导：到期日为空是常态（只知道还在保），推导会让这类记录永远显示「无保修」。

`dbValue` 用 `none` 而不是 `no`：`no`/`none` 在有些 SQL 方言里是保留字风险，且 `none` 与 `active`/`expired` 同长度风格统一。

### D4 日期与状态的一致性在写入端收口，不靠读端兜

规则：状态 != `active` 时两个日期一律写 `null`。落点在 `ItemRepository.save` 之前（编辑页 `_save` 组装 `ItemDraft` 时）与 `ItemDraft` 的语义约定两处：编辑页负责「用户切走了就不带日期」，repository 保持「draft 是什么就写什么」的纯粹性，不偷偷改值。

理由：读端兜（详情页/导出时判断状态再决定显不显示）会让脏数据一直在库里，一旦某处忘了判断就露出来；写端收口能保证「非在保 = 无日期」这个不变量在库层面成立（除了手工改库）。

日期顺序（到期 < 开始）**不拦**：用户可能真的填错，自用工具不替用户改事实，也不该因为一条录入错误阻止保存。

### D5 编辑页：下拉常驻，两个日期按 `_status == active` 展开

放在「电池健康」之后、`_section('卖出情况')` 之前，独立一个 `_section('保修')`。展开用一个 `_WarrantyDates` 内部 widget 还是直接 `if (...)` 内联？选内联 `if (...)`：与卖出侧同一写法，且不需要把 `_pickWarrantyStart/_pickWarrantyEnd` 抬成参数。

预填规则：**只在新建且用户首次把状态切到「在保」时**把开始日期填成 `_buyDate`（若为空则今天）。已存在记录 `_loadExisting` 时用库值覆盖，不做预填，避免把用户清空过的日期又填回来。

保存校验：日期都非必填；开始晚于到期不拦。

### D6 详情页：在保两行 + 已过保一行状态

「时间与渠道」卡片里，在「电池健康」行之后插入：

- `active`：`_kv('保修开始', _dateText(start) ?? '—')`、`_kv('保修到期', _dateText(end) ?? '—')`
- `expired`：`_kv('保修', '已过保')`
- `none`：什么都不加

按需求原文「在保时展示后面两个」，所以 `expired` 不展示日期，只留状态——这也符合用户填「已过保」时的实际用途：一眼知道这台不在保了，具体哪天到期已经不重要。

### D7 Excel：三列表头插在「旧机抵扣」之后

`itemHeaders` 顺序 = 导出列顺序。三列插在 `tradeIn` 之后、`expenseTotal` 之前，保持「商品属性 → 计算列 → 备注/批次」的既有分段。

导入时三列都缺（`indexOf == -1`）不算错误：整表视为「无保修」，与「旧表导入」场景一致。写值走 `ExcelSchema.warrantyFromLabel`（同时认中文标签与 `dbValue`），非法文本按列级错误报出（复用现有 `_parsePercentOrNull` 那类定位信息：第几行、哪一列、原值）。

导入的日期单元格复用现有日期解析（`datePattern` + 兼容 `2024/01/05`、`2024.1.5`）。

**一致性**：导入时若状态不是「在保」而三列里有日期，按 D4 同一规则丢弃日期，保持不变量。

### D8 测试 seam（需用户点头才写第一个测试）

| seam | 抓什么 | 漏什么 |
| --- | --- | --- |
| `WarrantyStatus` 与 Converter 往返（domain 单测） | `active` ↔ `active`、未知文本回落 `none` | 不测 UI |
| `ItemRepository.save` 持久化三字段（内存库） | 写入后 `load()` 读到的状态与两个日期 | 不测 Companion 生成细节 |
| 编辑页显隐联动（widget） | 选「在保」出现两个日期输入；改回「无保修」消失 | 不测 `showDatePicker` 的系统弹窗（只测入口存在与预填文案） |
| 保存时清空日期（widget 或 repository） | 状态=`expired` 且日期有值 → 落库为 null | 不测「日期顺序」因为故意不拦 |
| Excel 往返（纯 Dart，无 UI） | 导出→导入后三字段一致；缺三列的旧表 → 全 `none` | 不测 Excel 文件样式 |
| 迁移（内存库升级路径） | v5 库升到 v6 后旧行保修字段为 null、原字段不变 | 不做真机库文件拷贝测试 |

断言值一律用字面量（`WarrantyStatus.active`、`DateTime(2025, 3, 1)`），不按实现重算。

### D9 不做的事（本次范围外）

- 列表页保修角标、按「在保」筛选、按到期日排序/提醒
- 保修作为费用或影响利润的任何计算
- 「保修 N 个月」快捷按钮（自动算到期日）——用户没提，加了要先定「按月还是按天、月末怎么算」的口径

## 风险

- **跨端版本错配**：v6 与 v5 设备互相同步会被 `_verifySchema` 拒（列数不一致）。这是既有机制的预期行为，报错文案已提示「先把两端升级到同一版本」。需要在汇报里提醒用户先升两端。
- **列序写错**：`addColumn` 顺序与声明顺序不一致时本地一切正常、同步才炸。缓解：迁移段落三行顺序固定，并在 `app_database.dart` 版本历史注释里写明 v6 追加三列。
- **旧日期残留**：如果将来有别的入口（批量更新、导入）绕过 D4 规则，库里会出现「无保修 + 有日期」。缓解：导入路径也按 D4 处理（D7），并在 spec 里把它写成 requirement。
- **`schemaVersion` 忘记升**：drift 不会因为加了列就自动迁移，忘记升版本会在真机上抛「no such column」。缓解：tasks 里把「升版本」与「加段落」列为同一条任务。
