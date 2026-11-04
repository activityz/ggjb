## Why

`flutter test` 目前是 `+68 -4`：4 条失败来自 v5 未提交改动（字典新增「运营成本」第 9 类、商品表新增「电池健康 / 挂牌价 / 旧机抵扣」三列）先落地、测试期望值没跟上；同时需求 #6（看板三颗状态胶囊下钻、去掉看板分类筛选）已实现但零测试覆盖。基线红的状态下，新写的测试无法区分「本来就坏」和「刚被写坏」，TDD 的红灯信号失效。

## What Changes

- **对齐 4 条测试期望值**（不改生产代码，只改测试里的数字）：
  - `app/test/domain/dict_seeds_test.dart:7` kinds 数 8 → 9
  - `app/test/domain/dict_seeds_test.dart:34` 常量数 9 → 8
  - `app/test/domain/dict_seeds_test.dart:41` 扁平字典类数 6 → 7
  - `app/test/data/excel_schema_test.dart:8` 商品表列数 22 → 25
- **为 #6 补回归测试**：看板三胶囊下钻的状态集合、数字与列表条数一致、看板筛选弹窗不再有分类维度、明细页多状态组合标签可清除。
- **不改任何生产代码行为**。若测试暴露 #6 的实现与预期不符，另开修复项，不在本 change 里顺手改。

## Capabilities

### New Capabilities

- `dashboard-drilldown`：看板指标下钻到明细列表的筛选语义（状态集合口径、时间范围继承、数字与条目数一致）与明细页多状态筛选的表现。

### Modified Capabilities

（无。v5 那批功能——运营成本页、置换字段、日期区间——的 spec 由各自 change 承担，本 change 只把测试期望对齐到已存在的行为，不重新定义行为。）

## Impact

- 测试：`app/test/domain/dict_seeds_test.dart`、`app/test/data/excel_schema_test.dart`、新增 `app/test/features/item_list/item_list_page_test.dart` 与 `app/test/features/dashboard/dashboard_page_test.dart`
- 生产代码：无改动预期
- 文档：`openspec/specs/dashboard-drilldown/spec.md`（归档后成为当前真相）
- 旧数据兼容：用户已确认无需考虑，现有数据均为测试数据

## 非目标

- 不补 v5 其余未提交改动的 spec（运营成本页、统计页、同步逻辑）
- 不为旧版 Excel 文件加表头别名兼容（`毛利` → `利润` 改名后旧文件导入该列被忽略，用户已确认不管）
- 不做 `flutter build`，不做真机/桌面运行验证
