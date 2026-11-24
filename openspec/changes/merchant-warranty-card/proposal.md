# merchant-warranty-card

## Why

店里的机器卖给买家时会给一句「店内保修到某月某日」，现在这句话只能口头说、或者手写在备注里——买家过两周来问「保到哪天」，得翻聊天记录。序列号同理：真出故障时，认机靠的就是这串号，而库里只存了序列号铭牌的**照片**，没有可查、可印的文本。

已有的保修三态是**厂家保修**（厂商还剩多久），跟店里给买家的承诺是两回事：前者收货议价时用，后者出货交付时用，起止日期通常也不一样。把它们混在一个字段里，收货时会覆盖掉承诺，承诺时又会污染收货信息。

## What Changes

- `items` 追加三列：`serial`（序列号，可空文本）、`merchant_warranty_start`、`merchant_warranty_end`（商家保修起止，可空日期）
- `schemaVersion` 6 → 7，迁移只做 `ALTER TABLE ADD COLUMN`，不做任何猜测性回填
- **BREAKING（同步层面）**：两端必须都升到 v7 才能互相合并（既有 `_verifySchema` 按列数与列序比对，无需额外代码）
- 术语拆分：既有 `warranty_status/start/end` 与界面上原有的「保修」文案统一改称**厂家保修**；新增的一套称**商家保修**。库内列名保持不变（见 design D2）
- 编辑页：商品信息段新增「序列号」输入；原「保修」段改称「厂家保修」（行为不变）；卖出侧新增「商家保修」起止日期，状态切到「已卖出 / 已到账」时默认预填（开始 = 当天，到期 = 开始 + 1 年）
- 详情页：「标记已卖出」弹窗新增商家保修起止（同样默认预填、可改）；「时间与渠道」卡片按厂家保修、商家保修两组分别展示
- **商家保修必填**：状态为「已卖出 / 已到账」时，两个日期都为空则拦截保存，并指出缺的是哪一项
- 保修卡图片：列表页每行与详情页都能触发「生成保修卡」；点击先弹窗确认商家保修起止（可改），确认后截成竖版 1080×1620 PNG，内容为商品基本信息 + 商家保修起止 + 底部二维码 + 三条店内保修条款，**不显示任何价格**
- 保修卡落库方式：存进 `attachments` 表（新增角色 `warranty_card`），详情页在备注区下方独立成块展示；同一商品只保留最新一张，重新生成即替换
- 已有保修卡时，按钮文案由「生成保修卡」变为「查看保修卡」（两处入口一致）；详情页另有「重置保修卡」，删除该图后按钮回到「生成保修卡」，可重新选日期再生成
- 保修卡可导出 PNG（复用二维码弹窗已有的分享通路），便于发给买家
- Excel：新增「序列号」「商家保修开始」「商家保修到期」三列；原三列改表头为「厂家保修状态 / 厂家保修开始 / 厂家保修到期」，导入时**同时认新旧表头**，旧导出文件仍能正确导入

## Capabilities

### New Capabilities

- `merchant-warranty`：商品序列号、商家保修起止（含「卖出必填」与默认预填）、保修卡图片的生成 / 查看 / 重置，以及这两组保修信息在界面与表格中的分列

### Modified Capabilities

（无。`warranty-tracking` 描述的是厂家保修的行为，本次不改它的任何行为契约，只改界面与导出里的用词；该 capability 尚未归档，用词调整随 `add-warranty-fields` 归档时一并落地，避免两个未归档 change 改同一份 delta 打架。`data-integrity` / `test-infrastructure` / `dashboard-drilldown` 不受影响。）

## Impact

- 数据层：`domain/enums.dart`（`AttachmentRole` 加 `warranty_card`）、`data/db/tables.dart`（三列追加末尾）、`data/db/app_database.dart`（v7 迁移）、`data/repo/item_repository.dart`（`ItemDraft` 三字段）
- 界面：`features/item_edit/item_edit_page.dart`（序列号 + 厂家保修改名 + 商家保修必填）、`features/item_detail/item_detail_page.dart`（分组展示、标记已卖出弹窗、保修卡区块与两个按钮）、`features/item_list/item_list_page.dart`（行内按钮 + 长按菜单）
- 新增：`features/warranty/warranty_card.dart`（卡面 widget，纯展示、可单测）、`features/warranty/warranty_card_service.dart`（截图 + 存附件 + 查询 + 重置）
- 表格：`data/exchange/excel_rows.dart` / `excel_export.dart` / `excel_import.dart`（三列新增、三列改名 + 旧名兼容）
- 测试：新增序列号持久化、商家保修必填校验、默认预填、保修卡生成字节合法性、卡片 widget 文案、Excel 新旧表头往返；既有 382 条随结构升级复跑
- 不影响：利润口径（两组保修都不参与任何金额计算）、看板统计、二维码码值（仍为 `items.id`）、打印通道
