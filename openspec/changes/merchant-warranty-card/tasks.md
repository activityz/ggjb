# 任务

> 纪律：本清单按 TDD 排序，每个 seam 先红后绿；§2 的 seam 表（见 design.md）需用户确认后才写第一个测试。

## 1. 数据层与领域函数

- [x] 1.1 `app/lib/domain/enums.dart`：`AttachmentRole` 追加 `warrantyCard('warranty_card', '保修卡')`（文本枚举加值，不改 schema，旧端读到未知值回落 `other`）
- [x] 1.2 `app/lib/data/db/tables.dart`：`Items` 声明**最后**追加 `serial`（text，可空）、`merchantWarrantyStart`（dateTime，可空）、`merchantWarrantyEnd`（dateTime，可空）；在 `warrantyStatus` 三列上补注释「语义 = 厂家保修」
- [x] 1.3 `app/lib/data/db/app_database.dart`：`schemaVersion` 改 7；`onUpgrade` 加 `if (from < 7)` 三列（顺序 `serial → merchantWarrantyStart → merchantWarrantyEnd`，全部走 `_addColumnIfMissing`）；版本历史注释加 v7 一行
- [x] 1.4 新增 `app/lib/domain/merchant_warranty.dart`：`merchantWarrantyError(status, start, end)` 与 `addOneYear(date)`（闰日回退到当月最后一天）
- [x] 1.5 `app/lib/data/repo/item_repository.dart`：`ItemDraft` 加 `serial` / `merchantWarrantyStart` / `merchantWarrantyEnd`；`save()` 的 `ItemsCompanion` 补三项映射；`markSold` 加两个可选参数，新增 `setMerchantWarranty`
- [x] 1.6 跑 `build_runner` 重新生成 `app_database.g.dart`，确认三新列在表尾、顺序与迁移段落一致

## 2. 测试先行（红灯）— 需先确认 seam

- [x] 2.1 `app/test/domain/merchant_warranty_test.dart`：`addOneYear`（2026-11-24 → 2027-11-24；2028-02-29 → 2029-02-28）；`merchantWarrantyError`（sold 缺开始 / 缺到期 / 都缺 / inStock 不拦）—— 11 条
- [x] 2.2 `app/test/data/merchant_warranty_persistence_test.dart`：三字段写入后 `load()` 读回一致；两组保修互不串味；Companion 直写 —— 5 条
- [x] 2.3 `app/test/features/item_edit/merchant_warranty_field_test.dart`：状态切「已卖出」→ 两日期自动预填（当天 / +1 年）；已有值不被覆盖；清空到期点保存 → 被拦并提示缺「商家保修」
- [x] 2.4 同上文件：序列号填了会落库、留空保存后为空 —— 与 2.3 合计 6 条
- [x] 2.5 `app/test/features/item_detail/sold_dialog_warranty_test.dart`：「标记已卖出」弹窗预填当天/+1 年；改到期后确认 → 落库；详情页展示与补填入口 —— 4 条
- [x] 2.6 `app/test/features/warranty/warranty_card_view_test.dart`：卡面出现标题、序列号、商家保修两日期、三条条款原文；不出现任何价格 —— 2 条
- [x] 2.7 `app/test/features/warranty/warranty_card_view_test.dart` 截图用例：PNG 魔数 + 解码后 1080×1620
- [x] 2.8 `app/test/features/warranty/warranty_card_service_test.dart`：存、查、连存两次只留一张、重置后日期保留 —— 5 条
- [x] 2.9 `app/test/data/merchant_warranty_excel_test.dart`：新表头三列往返；旧表头「保修状态 / 保修开始 / 保修到期」仍读成厂家保修；缺三新列不报错；坏日期报行错 —— 5 条
- [x] 2.10 `app/test/data/app_database_test.dart`：v6→v7 三新列为空、厂家保修原值不动；v5→v7 六列；中断重跑幂等
- [x] 2.11 `app/test/features/warranty/warranty_card_entry_test.dart`：未卖出给说明、无卡给生成、有卡给查看+重置 —— 3 条

## 3. 生产实现

- [x] 3.1 编辑页商品信息段加「序列号」输入（`_serial` 控制器，`_loadExisting` 回填，`_save` 传值）
- [x] 3.2 编辑页「保修」段文案改「厂家保修」，下拉标签改「厂家保修状态」；详情页对应行改「厂家保修开始 / 厂家保修到期 / 厂家保修 已过保」
- [x] 3.3 编辑页卖出侧加「商家保修」两行 `_dateField`；`_onStatusChanged` 在切到 `isRealized` 且两日期为空时预填（当天 / `addOneYear`）
- [x] 3.4 编辑页 `_save()` 调 `merchantWarrantyError`，非 null 时 toast + 中断保存（与卖出价校验同一位置）
- [x] 3.5 详情页「时间与渠道」卡片：厂家保修一组、商家保修一组（缺失时显示可点击的补填行，点开日期弹窗只写这两列）
- [x] 3.6 详情页「标记已卖出」弹窗加商家保修两日期选择，默认当天/+1 年；确认前调 `merchantWarrantyError`
- [x] 3.7 新增 `app/lib/features/warranty/warranty_card_view.dart`：360×540 固定逻辑尺寸卡面（标题 / 品牌型号 / 内存颜色 / 成色 / 序列号 / 卖出日期 / 商家保修区间 / 三条条款 / 底部二维码 + 明文码值），不含任何价格
- [x] 3.8 新增 `app/lib/features/warranty/warranty_card_service.dart`：`latest` / `save`（先软删旧卡再插新行，同一事务）/ `reset`
- [x] 3.9 新增 `app/lib/features/warranty/warranty_card_dialog.dart`：生成前确认日期（可改）+ 查看 + 导出 PNG + 重置；渲染走 Overlay 离屏截图（`renderBoundaryPng(pixelRatio: 3)`）
  > 实现调整：原计划在详情页内联实现，落地时抽成共享弹窗，列表页与详情页共用同一套流程，避免两份生成逻辑。
- [x] 3.10 详情页保修卡区块（备注之后）：未生成给「生成保修卡」，已生成给缩略图 +「查看保修卡」+「重置保修卡」
- [x] 3.11 列表页行内加 `Icons.receipt_long` 按钮 + 长按菜单「保修卡」项，两处都打开同一个弹窗
- [x] 3.12 导出 PNG：复用 `qr_dialog` 的临时文件 + `SharePlus` 通路
- [x] 3.13 Excel：`excel_rows.dart` 加三新表头常量与位置、三旧表头改名 + 别名表；`excel_export.dart` 写三新列；`excel_import.dart` 读三新列 + 双表头兼容

## 4. 验证

- [x] 4.1 `D:/develop/flutter/fvm/versions/3.47.1/bin/flutter.bat test` 全绿：425 条（基线 382 + 新增 43），`All tests passed!`
- [x] 4.2 同上 `analyze` → `No issues found!`
- [x] 4.3 `openspec validate merchant-warranty-card --strict` → `Change 'merchant-warranty-card' is valid`
- [ ] 4.4 手工核对（待用户）：已卖出商品生成保修卡 → 详情页显示 → 导出 PNG → 重置 → 改日期重新生成

## 5. 收尾

- [x] 5.1 `app/pubspec.yaml` 版本号 `1.9.0+11` → `1.10.0+12`；`installer/ggjb.iss` 的 `#define AppVersion` 同步改为 `1.10.0`
- [x] 5.2 `README.md` 版本历史补 1.10.0 一行（含 v7 不兼容说明），并把漏记的 1.9.0 一并补上
- [ ] 5.3 汇报里提醒：两端设备需同时升到 v7 才能互相同步
