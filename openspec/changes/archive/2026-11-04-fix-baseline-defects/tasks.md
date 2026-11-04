# 任务

## 1. 红灯

- [x] 1.1 取消 `test/data/excel_import_test.dart` 里 2 条 skip（缺陷#3 缺名称列、缺陷#4 新行落库）
- [x] 1.2 取消 `test/sync/merge_test.dart` 1 条、`test/sync/sync_e2e_test.dart` 2 条 skip（缺陷#1）
- [x] 1.3 取消 `test/domain/image_pipeline_test.dart` 1 条 skip（缺陷#2）
- [x] 1.4 取消 `test/features/operating/operating_cost_page_test.dart` 1 条 skip（缺陷#5）
- [x] 1.5 跑 `flutter test`，记录 7 条失败的断言原文

## 2. 缺陷#4 导表丢行（最严重，先修）

- [x] 2.1 `ItemRepository.save`：id 非空时先判存在性，不存在走 insert
- [x] 2.2 跑 `test/data/item_repository_test.dart` + `test/data/excel_import_test.dart`

## 3. 缺陷#1 同步统计

- [x] 3.1 `merge.dart` 把本地 id 快照挪到事务内第一句
- [x] 3.2 跑 `test/sync/merge_test.dart` + `test/sync/sync_e2e_test.dart`

## 4. 缺陷#3 缺列分支

- [x] 4.1 `excel_import.dart` 的 `titleColumn == null` 改为 `< 0`

## 5. 缺陷#2 图片错误

- [x] 5.1 `image_pipeline.dart` 用 try/catch 包住 `decodeImage`

## 6. 缺陷#5 运营成本刷新

- [x] 6.1 删除成功后 invalidate 三个 provider

## 7. 收尾

- [x] 7.1 `flutter test` 全量（目标：283 条全绿、0 skip）
- [x] 7.2 `flutter analyze` No issues
- [x] 7.3 汇报：每个缺陷的「改前行为 / 改后行为 / 覆盖用例」
