# fix-baseline-defects

## Why

全项目测试铺开后，有 5 处行为缺陷可以稳定复现：导表写入静默丢失、同步增量统计恒为「+0 / 覆盖 N」、坏图片把 `RangeError` 抛给用户、缺「名称」列的错误分支不可达、运营成本删完界面不刷新。这 5 条都已写成 skip 用例挂在测试里，行为与规格不符，但用户拿不到正确信号（提示成功却什么都没写、提示「覆盖」却其实是新增）。不修掉它们，测试基线的绿是假的。

## What Changes

- **导表不再丢行**：`ExcelImportService.apply` 对 parse 阶段新分配 id 的行必须插入；`ItemRepository.save` 在 id 指向不存在的行时改为插入，而不是 update 0 行后仍计成功。
- **缺列报对错**：表头缺「名称」列时命中专门的错误分支（`_headerIndex` 用 -1 表示缺失，判断从 `== null` 改成 `< 0`）。
- **同步统计正确**：`_tableDelta` 在合并事务开始前快照本地 id，远端独有行计入 inserted。
- **图片错误可读**：捕获 `decodeImage` 抛出的 `RangeError`/其他异常，统一转成 `ImagePipelineException('无法解析…')`。
- **运营成本即时刷新**：删除后 `invalidate` 列表、合计与看板汇总三个 provider。
- **测试转正**：取消 5 个缺陷用例的 `skip`，全部真红后修，最终转绿。

## Capabilities

### New Capabilities

- `data-integrity`: 导入、同步、图片解码、运营成本删除这四条路径上的「用户看到的数字必须等于库里的事实」。

### Modified Capabilities

（无。`dashboard-drilldown` 的行为不变。）

## Impact

- 生产代码：`app/lib/data/exchange/excel_import.dart`、`app/lib/data/repo/item_repository.dart`、`app/lib/sync/merge.dart`、`app/lib/domain/image_pipeline.dart`、`app/lib/features/operating/operating_cost_page.dart`
- 测试：`app/test/data/excel_import_test.dart`、`app/test/sync/merge_test.dart`、`app/test/sync/sync_e2e_test.dart`、`app/test/domain/image_pipeline_test.dart`、`app/test/features/operating/operating_cost_page_test.dart` 取消 skip
- 数据兼容：无 schema 变更，无迁移
