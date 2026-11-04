# 设计：去掉分类筛选 + 置换单可见化

## 上下文

- 筛选当前是两条链路：`ItemFilter`（Riverpod family 的 key）→ `itemListProvider` → `ItemRepository.watchList` → `ItemDao.watchList`。`category` 从 `ItemListPage._category` 一路传到底。
- `aggregate(category:)` 已无生产调用方（看板在需求 #6 里就不传了），只被 `item_repository_test` 用着。
- 置换数据：`items.trade_in_cents`（旧机抵扣，可空）、`items.list_price_cents`（挂牌价，可空）。`ProfitLine` 已带 `tradeInCents`，但 `profitCents` 不参与计算，只累加到 `ProfitSummary.tradeInTotalCents`。
- 列表卡片 `_ItemTile`（`item_list_page.dart:450-600`）现在只有 `_StatusBadge` 一个徽章；详情页「旧机抵扣」在 `item_detail_page.dart:251-252`，位置在「卖出信息」区块最后。

## 决策

### D1 分类筛选从 UI 到 DAO 整条链路删掉

删除顺序（自下而上改，编译一次到底）：`ItemDao.watchList(category:)` → `ItemRepository.watchList(category:)` + `aggregate(category:)` → `ItemFilter.category`（含 copyWith/==/hashCode/clearCategory） → `itemListProvider` 透传 → `ItemListPage._category` 与 `_FilterRow` 的分类下拉。

不保留「参数在但没人传」的形态：`ItemFilter` 是 family 的 key，留着它会让 `==` 多一个恒 null 的比较项，也让后来的人以为分类筛选还能用。

**保留** `items.category` 字段本身与它的下游：编辑页输入、`stat_dao.byCategory`、导表列、`excel_import` 的映射。这些跟「筛选」无关。

### D2 置换判定只认 `tradeInCents > 0`

`listPriceCents`（挂牌价）不是置换的证据——普通挂售也会有挂牌价；`tradeInCents` 才代表「这单用了旧机抵扣」。空值与 0 都算非置换（导表可能写 0）。

判定封装成一个私有 getter `bool get isTradeIn => (item.tradeInCents ?? 0) > 0`，列表卡与详情页共用同一口径，避免各写各的。

### D3 列表：置换徽章与状态徽章并列，抵扣金额独立成块

标题行放 `_StatusBadge`（现有）后再跟一个 `_TradeBadge('置换')`，用 `palette.accent` 而不是状态色——它不是状态，是交易方式，混进状态色会让人以为多了个状态。

价格行不动「买 / 卖 / 利润」三段，抵扣另起：在「卖」的 `_PriceTag` 之后插一个 `抵 ¥800` 的小字（`palette.accent`，字号 12）。不塞进「卖」标签里，否则一眼看过去会以为卖价是 800。

### D4 详情：页头标识 + 卖出信息里独立一行

页头价格区下方加一行小标签「置换成交 · 旧机抵扣 ¥800」（accent 色），有挂牌价时第二段接「挂牌价 ¥X」。原「卖出信息」区块里的 `_kv('旧机抵扣', …)` 保留（明细要能逐项看），但去掉 `if (item.listPriceCents != null)` 的并列关系，让它不依赖挂牌价是否存在。

### D5 利润口径一行代码都不动

`ProfitLine.profitCents` 现在就不含 `tradeInCents`，`aggregate` 只把它累加到 `tradeInTotalCents`（`profit.dart:234-238`、`:268`）。本 change 只做展示层，规格里那条「利润 800 不是 1600」是防回归断言，不是新逻辑。

### D6 连带删两条测试用例，新增四条

- 删 `item_dao_test` 的「category trim」用例、`item_repository_test` 的「aggregate 按分类过滤」用例——它们验证的正是要删除的能力。
- 新增：列表卡片出现置换徽章与抵扣金额 / 非置换单没有 / 详情页出现置换标识与抵扣 / 置换单利润口径。
- `item_list_page_test` 与 `item_detail_page_test` 的既有用例不受影响（它们不涉及分类）。

## 风险

- `ItemFilter` 的 `==` / `hashCode` 少一项后，family 缓存行为不变（只是 key 空间变窄）；已有测试覆盖 `statuses` 的内容比较，不会退化。
- 列表卡片宽度：标题行多了徽章，长标题会更容易被挤成省略号。`Text` 已 `maxLines: 1 + ellipsis`，可接受；不为了排版去改字号。
- 详情页「挂牌价」在非置换单上的展示逻辑未变，只调整了与「旧机抵扣」的并列关系，需要一条点击回归确认没把挂牌价弄丢。
