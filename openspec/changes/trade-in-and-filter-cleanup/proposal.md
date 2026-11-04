# trade-in-and-filter-cleanup

## Why

两条用户反馈：

1. **筛选里的分类该去掉。** 需求 #6 只清了看板的分类筛选，明细页筛选条左侧还挂着一个「全部分类」下拉。分类是商品的属性（编辑页要填、统计页要分组、导表要带），但不是用户翻账时想用的筛子——真正要的是「某个时间段卖出去的」。留着它让筛选条挤成两截，还得先读一遍字典。

2. **置换单看不出来。** 数据层早就存了 `items.trade_in_cents`（旧机抵扣）和 `list_price_cents`（挂牌价），详情页也有一行「旧机抵扣」，但列表卡片完全不提，详情页那行藏在「卖出信息」区块末尾。结果：置换来的单子和现金买的单子在列表里长得一模一样，用户翻列表对不上「这台是拿旧机抵了 800 换的」。

## What Changes

- 明细页筛选条移除分类下拉与 `_category` 状态，只留日期筛选
- 连带清掉只为它服务的筛选链：`ItemFilter.category`、`ItemDao.watchList(category:)`、`ItemRepository.watchList(category:)`、`ItemRepository.aggregate(category:)`
- 列表卡片：`tradeInCents > 0` 的单子在标题旁加「置换」徽章，价格行加「抵 ¥XXX」
- 详情页：页头加「置换」标识，卖出信息区块的抵扣行提为独立一行显眼展示（挂牌价保留原处）
- 利润口径不变：抵扣仍然只留痕、不并入利润

## Capabilities

### New Capabilities

- `item-filtering`：明细列表的筛选维度（只保留日期，分类退出筛选）
- `trade-in-display`：置换单在列表与详情里的可见标识与抵扣金额展示

### Modified Capabilities

（无。`item-filtering` 此前没有 spec 条目，本次补齐为新增 capability。）

## Impact

- 生产代码：`app/lib/app/providers.dart`、`app/lib/data/dao/item_dao.dart`、`app/lib/data/repo/item_repository.dart`、`app/lib/features/item_list/item_list_page.dart`、`app/lib/features/item_detail/item_detail_page.dart`
- 测试：`item_dao_test`（category 用例）、`item_repository_test`（aggregate category 用例）、`item_list_page_test`、`item_detail_page_test`，并新增置换展示用例
- 不影响：编辑页的分类输入、统计页 `byCategory` 分组、导表的分类列、利润计算
