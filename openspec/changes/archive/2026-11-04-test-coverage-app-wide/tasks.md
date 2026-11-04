# 任务

## 1. 基线转绿

- [x] 1.1 `dict_seeds_test` 对齐 9 类字典 / 7 类扁平数据，补 `kindOperating`
- [x] 1.2 `excel_schema_test` 商品表 22 列 → 25 列

## 2. 数据层

- [x] 2.1 `app_database_test`（8 条）：schemaVersion=5、七表、六索引、外键、字典种子、v5 渠道排序
- [x] 2.2 `item_dao_test`（18 条）
- [x] 2.3 `dict_dao_test`（13 条）
- [x] 2.4 `attachment_dao_test`（8 条）
- [x] 2.5 `operating_dao_test`（8 条）
- [x] 2.6 `stat_dao_test`（12 条）

## 3. 仓库层

- [x] 3.1 `item_repository_test`（21 条）：save 全量替换、状态迁移、aggregate、图片

## 4. 同步层

- [x] 4.1 `merge_test`（7 条）：四类冲突裁决
- [x] 4.2 `sync_e2e_test`（13 条）：真 HTTP 往返、配对码、令牌、CORS
- [x] 4.3 `auto_sync_test`（8 条）：六种状态机分支

## 5. 交换层与领域层

- [x] 5.1 `excel_export_test`（8 条）
- [x] 5.2 `excel_import_test`（13 条）
- [x] 5.3 `date_period_test`（20 条）
- [x] 5.4 `image_pipeline_test`（9 条）
- [x] 5.5 `theme_test`（13 条）

## 6. 页面层

- [x] 6.1 `dashboard_page_test`（3 条）：三胶囊下钻状态集合 + 筛选弹窗无分类
- [x] 6.2 `item_list_page_test`（3 条）：多状态组合标签
- [x] 6.3 `item_detail_page_test`（8 条）：按钮可见性矩阵 + 状态流转
- [x] 6.4 `item_edit_page_test`（6 条）：三道校验 + 编辑保留 id/设备
- [x] 6.5 `operating_cost_page_test`（8 条）
- [x] 6.6 `dict_manage_page_test`（1 条冒烟，交互受 ReorderableListView 限制）

## 7. 收尾

- [x] 7.1 `flutter test` 282 条全绿
- [x] 7.2 `flutter analyze` No issues
- [x] 7.3 发现的 5 个缺陷拆到 `fix-baseline-defects`
