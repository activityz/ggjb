# test-coverage-app-wide

## Why

需求 #6 落地后，项目只有 5 个测试文件、68 条用例，data/dao、sync、repo、8 个页面基本裸奔。任何一次重构都没有安全网，TDD 的红灯机制也无从谈起（`AGENTS.md` §2 要求 test-first，但先得有一条能红的线）。

## What Changes

把测试面从「domain + schema」扩到「所有能脱离 UI 框架验证的层」，同时给 4 个关键页面加 widget 测试：

- 数据层：item / dict / attachment / operating / stat 五个 DAO，app_database（schemaVersion、表、索引、种子）
- 仓库层：`ItemRepository` 的 save 全量替换、状态迁移矩阵、aggregate、图片读写
- 同步层：`MergeService` 冲突裁决、`SyncClient`/`SyncHost` 真 HTTP 往返、`AutoSyncService` 六种状态机
- 交换层：导出 xlsx 的内容口径、导入的字段映射与逐行报错
- 领域层：`DatePeriod` 区间端点与 label、`ImagePipeline` 缩放与坏输入、`AppPalette` lerp/copyWith
- 页面层：看板下钻、明细多状态、详情页按钮矩阵、编辑页三道校验、运营成本、字典管理冒烟

**不改生产代码**（发现的 5 个缺陷另拆 `fix-baseline-defects`，已归档）。

## Capabilities

### New Capabilities

（无。本 change 不改产品行为，只补验证；`openspec/specs/` 不新增条目。）

### Modified Capabilities

（无。）

## Impact

- 新增 22 个测试文件（`app/test/**`），修改 2 个既有测试的滞后期望值
- 用例从 68 条涨到 282 条，`flutter test` 全绿、`flutter analyze` 干净
- 生产代码零改动
