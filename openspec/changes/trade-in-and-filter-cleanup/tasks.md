# 任务

## 1. 测试先行（红灯）

- [x] 1.1 新增 `item_list_page_test` 用例：置换单（tradeInCents=80000、卖出价可空）卡片出现「置换」与「抵 ¥800」
- [x] 1.2 新增用例：`tradeInCents` 为 null 的商品不出现「置换」与「抵」
- [x] 1.3 新增 `item_detail_page_test` 用例：置换单详情出现「置换」标识与「旧机抵扣」金额
- [x] 1.4 新增用例：非置换单详情不出现「置换」标识
- [x] 1.5 新增 `profit_test` 用例：卖出 1500、成本 700、抵扣 800 → 利润 800、`tradeInTotalCents` 800
- [x] 1.6 新增 `item_list_page_test` 用例：筛选条不存在「全部分类」文字
- [x] 1.7 跑 `flutter test` 确认上述用例红，记录输出

## 2. 分类筛选下线

- [x] 2.1 `ItemDao.watchList` 删 `category` 参数与 `query.where(...category...)`
- [x] 2.2 `ItemRepository.watchList` / `aggregate` 删 `category` 参数
- [x] 2.3 `ItemFilter` 删 `category` 字段、copyWith 的 category/clearCategory、`==` 与 `hashCode` 对应项
- [x] 2.4 `itemListProvider` 不再透传 category
- [x] 2.5 `ItemListPage` 删 `_category` 状态与 initState 赋值、`_FilterRow` 的 category 参数与下拉、`hasFilter` 里的 `_category != null`
- [x] 2.6 删 `item_dao_test` 的「category trim」用例与 `item_repository_test` 的「aggregate 按分类过滤」用例

## 3. 置换可见化

- [x] 3.1 `_ItemTile` 加 `_TradeBadge`（`palette.accent`，11px，圆角 4），标题行紧随 `_StatusBadge`
- [x] 3.2 价格行在「卖」之后插入 `抵 ¥X`（`Money(tradeInCents).toYuanString()`，accent，12px，tabular figures）
- [x] 3.3 `ItemDetailPage` 页头加「置换成交 · 旧机抵扣 ¥X」标签；有挂牌价时并列显示
- [x] 3.4 详情「旧机抵扣」`_kv` 行与挂牌价解除并列依赖

## 4. 验证

- [x] 4.1 `flutter test` 全绿（282 + 新增 − 删除）
- [x] 4.2 `flutter analyze` No issues
- [x] 4.3 手工核对：置换单与非置换单在列表里能一眼分开
