# add-warranty-fields

## Why

二手机器最值钱的信息之一是「还有没有保修、保到哪天」—— 它在收货议价时决定报价，在挂着卖时决定文案，卖出后还要能回答买家「还剩几个月」。现在这一信息只能塞进备注自由的文本里，既不能筛、也不能算，卖完就找不回来。

## What Changes

- `items` 表追加三列：`warranty_status`（保修状态）、`warranty_start`（保修开始日期）、`warranty_end`（保修到期日期），全部 nullable，旧行升级后为 NULL = 无保修
- 保修状态是**三态枚举**：`无保修 / 在保 / 已过保`（库内存 `none / active / expired` 文本，与既有枚举存储风格一致）
- 编辑页新增「保修」区块：状态下拉常驻；**仅当状态 = 在保时才展开**「保修开始」「保修到期」两个日期选择器，选「在保」时开始日期默认预填买入日期
- 状态切回「无保修 / 已过保」时，保存把两个日期写 NULL，不留孤儿日期
- 到期日期非必填（只知道「还在保」不知道具体日子是常态）
- 详情页「时间与渠道」卡片：状态为「在保」时展示「保修开始 / 保修到期」两行；无保修不展示这两行，已过保只展示「保修」状态行
- Excel 导入导出增加三列表头：`保修状态 / 保修开始 / 保修到期`，按表头名定位；旧表没有这三列视为无保修，导出无保修行留空
- `schemaVersion` 5 → 6，迁移只做 `ALTER TABLE ADD COLUMN`，不做任何猜测性回填
- **BREAKING（同步层面）**：`sync/merge.dart` 的 `_verifySchema` 按列数与列序判断两端兼容，因此两台设备必须都升级到 v6 才能互相合并；同版本内同步无需额外代码

## Capabilities

### New Capabilities

- `warranty-tracking`：商品保修信息的录入、条件展示与表格往返（含「不在保就不展示日期」的显隐契约）

### Modified Capabilities

（无。`data-integrity` 管的是导入/合并的正确性判据，本次没有改变任何既有 requirement 的行为；版本兼容约束写在本 change 的 design.md 与 `warranty-tracking` 的 scenario 里。）

## Impact

- 生产代码：
  - `app/lib/domain/enums.dart`（新枚举 + TypeConverter）
  - `app/lib/data/db/tables.dart`（`Items` 末尾追加三列）
  - `app/lib/data/db/app_database.dart`（`schemaVersion = 6` + `if (from < 6)` 三个 `addColumn`）
  - `app/lib/data/repo/item_repository.dart`（`ItemDraft` 三字段 + `ItemsCompanion` 映射）
  - `app/lib/features/item_edit/item_edit_page.dart`（状态下拉 + 条件展开日期 + 保存/清空）
  - `app/lib/features/item_detail/item_detail_page.dart`（状态行 + 在保时两行）
  - `app/lib/data/exchange/excel_rows.dart` / `excel_export.dart` / `excel_import.dart`（三列表头与双向映射）
- 测试：新增 `warranty_test`（枚举与转换器）、`item_repository_test` 保修持久化用例、`item_edit_page_test` 显隐联动用例、`excel_roundtrip_test` 三列往返用例；既有用例随表结构升级复跑
- 不影响：利润口径（保修不参与任何金额计算）、列表页展示与筛选、字典表、看板统计
