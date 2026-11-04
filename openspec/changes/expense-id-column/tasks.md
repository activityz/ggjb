# 任务

## 1. 红灯（先写测试）

- [x] 1.1 `excel_export_test.dart`：断言费用表表头首项是「费用id」，且首格等于库里的费用 id
- [x] 1.2 `excel_import_test.dart`：同一份表连导两次，费用行数不增、id 不变
- [x] 1.3 `excel_import_test.dart`：本地软删的费用 `e1` 被表里的 `e1` 复活
- [x] 1.4 `excel_import_test.dart`：表头去掉「费用id」后仍能导入、无错误
- [x] 1.5 `excel_import_test.dart`：两行同费用 id → 报错且 `preview.ok == false`
- [x] 1.6 跑 `flutter test`，确认以上按预期变红（其余全绿）

## 2. 实现

- [x] 2.1 `excel_rows.dart`：加常量 `expenseId = '费用id'`，插进 `expenseHeaders` 首位
- [x] 2.2 `excel_export.dart`：费用行首格写 `expense.id`
- [x] 2.3 `excel_import.dart`：`_parseExpenses` 读 id 列、`Set seen` 查重、`ExpenseDraft(id: …)`

## 3. 收尾

- [x] 3.1 `flutter test` 全量通过、零 skip
- [x] 3.2 `flutter analyze` 干净
- [x] 3.3 `dart format` 改动文件
- [x] 3.4 汇报：贴表头前后对照与实际往返结果
