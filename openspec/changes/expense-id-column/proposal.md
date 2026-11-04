# 费用表带上费用 id

## Why

导出→导入现在是「费用全量替换」：费用表只写「商品id」，不写费用自己的 id。
每次导入都把该商品原有费用打成墓碑、再插一批新 id 的行。后果有三个：

1. `expenses` 表的墓碑行随导入次数线性增长，库文件越导越大。
2. 同步时这些墓碑会被推到对端，白白占用一次传输。
3. 用户改过备注或金额的费用，导入后变成另一条记录，历史 id 断裂。

用户要求：给费用表加一列 id，让导入能原地覆盖。

## What Changes

- 导出：费用表新增首列「费用id」，写 `expenses.id`。
- 导入：读「费用id」列；带 id 且本地存在 → 原地复活并覆盖（沿用 `ItemRepository.save`
  里已有的「有 id 就复活+覆盖」分支），不再新插、不再留墓碑。
- 兼容：旧导出文件没有这一列时，按 `id = null` 处理，落回今天的「插新行」行为，不报错。
- 校验：同一个费用 id 在表里出现两次 → 报错（与商品「同 id 两次」一致）。

## Capabilities

### New Capabilities

- `expense-identity`: 费用在导出/导入往返中保持身份，重复导入不产生墓碑堆积。

### Modified Capabilities

（无。商品侧的 id 往返与 `data-integrity` 契约不变。）

## Impact

- `app/lib/data/exchange/excel_rows.dart`：`expenseHeaders` 增列常量。
- `app/lib/data/exchange/excel_export.dart`：费用行写 id。
- `app/lib/data/exchange/excel_import.dart`：解析 id 列 + 重复 id 校验 + 传给 `ExpenseDraft`。
- 测试：`excel_export_test.dart`、`excel_import_test.dart`、`excel_roundtrip_test.dart`。
- 不涉及数据库 schema、不涉及同步协议、不涉及 UI。
