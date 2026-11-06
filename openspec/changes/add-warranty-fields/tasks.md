# 任务

> 纪律：本清单按 TDD 排序，每个 seam 先红后绿；§2 的 seam 表需用户确认后才写第一个测试。

## 1. 数据层：枚举与表结构

- [x] 1.1 `app/lib/domain/enums.dart` 新增 `WarrantyStatus`（`none/active/expired`，中文标签「无保修/在保/已过保」）与 `WarrantyStatusConverter`
- [x] 1.2 `app/lib/data/db/tables.dart` 在 `Items` 声明**最后**追加 `warrantyStatus`（text，可空，带 converter）/ `warrantyStart`（dateTime，可空）/ `warrantyEnd`（dateTime，可空），并补注释说明列序与同步校验的关系
- [x] 1.3 `app/lib/data/db/app_database.dart`：`schemaVersion` 改 6；`onUpgrade` 加 `if (from < 6)` 三列（顺序与声明一致）；版本历史注释加 v6 一行
  > 加固：三列走 `_addColumnIfMissing(m, items, col)`（先查 `PRAGMA table_info` 再 add）。drift 只在迁移全部跑完后才写 `user_version`（`engines.dart` _runMigrations：「set version now, after migrations ran successfully」），中断重跑会撞 `duplicate column name` 导致 App 打不开库；判存后重跑幂等，已加列留在末尾、列序仍正确。
- [x] 1.4 跑 `build_runner` 重新生成 `app_database.g.dart`，确认生成列顺序为 `warranty_status → warranty_start → warranty_end` 且在表尾

## 2. 测试先行（红灯）— 需先确认 seam

- [x] 2.1 `app/test/domain/warranty_test.dart`（4 个用例）：`WarrantyStatusConverter` 往返（`active` ↔ `active`）、未知文本回落 `none`、默认值 `none`
- [x] 2.2 新建 `app/test/data/warranty_persistence_test.dart`：写入「在保 + 两个日期」后 `load()` 读回一致；不填保修时状态为 `none`、日期为 null；改回无保修会覆盖旧值；旧行不写保修列读出 `none`
- [x] 2.3 同上文件「编辑时把状态改回无保修会覆盖旧值」用例（覆盖 D4 不变量）
- [x] 2.4 新建 `app/test/features/item_edit/warranty_field_test.dart`：默认不出现两个日期；切到「在保」→ 两个日期出现，且「保修开始」等于买入日期（新建默认今天）
  > 注：表单是懒加载 ListView，断言前必须 `scrollUntilVisible`，否则拿到的「0 个」是没构建而不是被隐藏
- [x] 2.5 同上文件「已有在保单改成『已过保』」用例：日期字段消失且保存后库里两个日期为 null（切「无保修」同一路径，`hasDates == false` 分支）
- [x] 2.6 新建 `app/test/data/warranty_excel_test.dart`「导出再导入」用例：在保状态与 `yyyy-MM-dd` 日期往返不掉
- [x] 2.7 同上文件：旧表缺三列 → 解析为 `none`、`preview.ok == true`；另加「非在保丢了日期」「中文标签与 `dbValue` 都认」
- [x] 2.8 每个 seam 先红后绿；全量 `flutter test` 从 286 → 320 条

## 3. 生产实现

- [x] 3.1 `app/lib/data/repo/item_repository.dart`：`ItemDraft` 加 `warrantyStatus` / `warrantyStart` / `warrantyEnd`；`save()` 的 `ItemsCompanion` 补三项映射（不传时用 `none` 默认）
- [x] 3.2 `app/lib/features/item_edit/item_edit_page.dart`：控制器与状态字段 `_warrantyStatus` / `_warrantyStart` / `_warrantyEnd`；`_loadExisting` 回填；`dispose` 无新增控制器（日期走 `DateTime?`）
- [x] 3.3 编辑页 `_section('保修')` + `DropdownButtonFormField<WarrantyStatus>`；`if (_warrantyStatus == WarrantyStatus.active) ...[两行 _dateField]`
- [x] 3.4 编辑页 `_pickWarrantyStart` / `_pickWarrantyEnd`（`showDatePicker`，区间 2000–2100，初始值取已选值或今天）；状态首次切到「在保」时把开始日期预填为 `_buyDate ?? today`
- [x] 3.5 `_save()`：状态 != `active` 时把两个日期置 null；`ItemDraft` 三字段传值
- [x] 3.6 `app/lib/features/item_detail/item_detail_page.dart`：「电池健康」行之后按 D6 三分支展示
- [x] 3.7 实现名：`warrantyStatus/warrantyStart/warrantyEnd` 常量 + `warrantyLabel/warrantyFromLabel`（未知值返回 null 让导入报错，不当无保修）
  > 另：`warrantyStatus` 列为 text + converter + `withDefault(Constant('none'))`，不是可空列——避免 `WarrantyStatus?` 到处判空，且 ALTER 加带常量默认值的列不会重写旧行 `app/lib/data/exchange/excel_rows.dart`：三个表头常量 + `itemHeaders` 插入位置 + `warrantyStatusLabel/FromLabel` 互转
- [x] 3.8 状态列总是写（默认「无保修」），日期为空就不写 `app/lib/data/exchange/excel_export.dart`：三列写入（无保修行留空）
- [x] 3.9 缺列/空值 → `none`；非法值 → 行级错误并跳过；非在保不解析日期直接丢 `app/lib/data/exchange/excel_import.dart`：三列读取（缺列按 `none`）、非法值报列级错误、非在保丢弃日期

## 4. 验证

- [x] 4.1 `flutter test`：321 条全绿（基线 286 + 新增保修用例 + 3 条迁移用例：v5→v6 数据无损、DDL 与新建库逐字相同、升级中断重跑幂等）
- [x] 4.2 `flutter analyze` → `No issues found!`（65.5s） `flutter analyze` → `No issues found!`
- [x] 4.3 `openspec validate add-warranty-fields --strict` → `Change 'add-warranty-fields' is valid` `openspec validate add-warranty-fields`
- [ ] 4.4 手工核对（待用户跑一次真机/桌面）：新建→选在保→填日期→保存→详情页显示两行；改回无保修→详情页不再显示
- [ ] 4.5 手工核对（待用户）：导出 Excel 三列存在且日期格式正确；把三列删掉再导入不报错

## 5. 收尾

- [x] 5.1 汇报里提醒：两端设备需同时升到 v6 才能互相同步（`_verifySchema` 会拒列数不一致）
- [x] 5.2 归档前确认 tasks 全勾选、`openspec validate` 通过
- [x] 5.3 App 版本号 `1.5.1+7` → `1.6.0+8`（`app/pubspec.yaml`）：schemaVersion 5→6 是显式不兼容变更，发版号必须看得出来；同步在 `README.md` 版本历史补 1.6.0 一行（`tools/build-all.ps1` 从 pubspec 读版本号组装 dist 文件名，无需改）
