# loss-scope-and-drilldown

## Why

卖亏了的单在「了结亏损」里看不见，因为这张卡只统计「已退货 / 已报废」，而贱卖的亏损（1000 买、800 卖）被算进「已到手 / 未到手利润」里当负数，直接把利润栏拉低。站在店主的视角，这两件事都是「这一单亏了钱」，分在两栏里既不好核对，也容易被利润栏的负数混淆——他要想知道「我这个月到底亏在哪几单」，现在没有入口。

另外这张卡是看板上唯一点了没反应的一张：其它四张都能点开明细。

## What Changes

- **口径调整（BREAKING，看板数字会变）**：把「亏损」定义为**任何单笔利润为负的单**，涵盖已卖出、已到账、已退货、已报废四种状态；对应地，利润栏只统计**利润为正**的单。总利润口径不变——正利润加负利润仍是同一个净额，只是分栏变了
- `ProfitSummary` 字段语义随之收紧：`settledProfitCents` / `unsettledProfitCents` 只含盈利单；新增 `soldLossCents`（已卖出/已到账里的亏损合计）；`closedLossCents` 变成全部亏损单的合计；`lossClosedCount` 变成亏损单数
- 利润率分子改用「已售净额」（盈利 − 贱卖亏损），分母仍是已售商品的成本合计：分母不跟着改，否则「这批货赚了多少」会被算成只赚不亏
- 看板「了结亏损」卡：数字与单数按新口径算，`hint` 从「N 单退货/报废」改为「N 单亏钱」，`footnote` 说明含贱卖与退货报废两种来源
- 看板「了结亏损」卡可点击，打开明细列表，只列亏损单（按当前看板的时间筛选走）
- `ItemFilter` 新增「只看亏损」维度，明细列表页按它过滤；该筛选项不出现在列表页的筛选条里，只由看板下钻带入
- 已到手/未到手两张卡的 `footnote` 补一句「亏钱的单不在这里，点上面看了结亏损」，避免同样的困惑再出现一次

## Capabilities

### New Capabilities

- `loss-accounting`：单笔盈亏如何归栏——什么算亏损、什么算利润、两组数字如何相加得到总利润，以及利润率的分母口径

### Modified Capabilities

- `dashboard-drilldown`：「了结亏损」卡新增可点击与明细一致性要求（原先只覆盖三颗胶囊）

## Impact

- 领域层：`app/lib/domain/profit.dart`（`ProfitSummary` 字段与 `ProfitCalculator.aggregate` 分栏逻辑、`realizedMarginRate` 分子）
- 看板：`app/lib/features/dashboard/dashboard_page.dart`（卡片文案与 `onTap`、`_OpenItems` 签名、`_HeroCard` 提示文案）
- 列表：`app/lib/app/providers.dart`（`ItemFilter` 新维度）、`app/lib/data/repo/item_repository.dart` 或 provider 层的亏损过滤、`app/lib/features/item_list/item_list_page.dart`（接收并展示「只看亏损」状态）
- 测试：`profit_test.dart` 汇总口径用例随新定义调整并新增「贱卖计入亏损」用例；`dashboard_page_test.dart` 新增卡片可点击与计数一致；新增明细过滤用例
- 不影响：单笔利润公式（`profitCents`）不变、待收货款、在途占用、运营成本、Excel 导出列
