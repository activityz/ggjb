# 设计：亏损归栏与明细下钻

## 上下文

- 现有口径写在 `app/lib/domain/profit.dart:13-14`：**了结亏损 = returned + scrapped**；sold/completed 的负利润混在「已实现利润」里（`aggregate` 第 246-257 行）。
- 看板五张卡在 `dashboard_page.dart:344-393`，其中「了结亏损」是唯一没有 `onTap` 的。
- 下钻走 `_OpenItems`（`dashboard_page.dart:23`）→ `ItemListPage(initialFilter:)` → `ItemFilter`（`providers.dart:71`）+ `itemListProvider`（`providers.dart:149`）。
- `ItemFilter` 只有状态 / 关键词 / 日期三个维度；`itemListProvider` 直接把筛选参数转给 `repository.watchList`，没有 Dart 层过滤。
- `ProfitSummary.closedCount = soldCount + lossClosedCount` 被看板空态判断（`dashboard_page.dart:258`）使用，不能因为口径调整而重复计数。

## 决策

### D1 归栏只看单笔利润的正负，不看状态

规则：`profitCents >= 0` 进利润栏（再按状态分「已到手 / 未到手」），`profitCents < 0` 进亏损栏。`profitCents == 0` 归利润栏、金额记 0，不计入「N 单亏钱」。

> 否决：按状态归栏（现状）。1000 买 800 卖的单在店里就是亏了 200，把它塞进「已到手利润 −200」会让利润栏出现负数，而「亏了多少」这个问题反而要自己减号相加。

### D2 `ProfitSummary` 字段：改语义 + 加两个新字段

| 字段 | 旧语义 | 新语义 |
| --- | --- | --- |
| `settledProfitCents` | completed 的全部利润（含负） | completed 中 **≥0** 的部分 |
| `unsettledProfitCents` | sold 的全部利润（含负） | sold 中 **≥0** 的部分 |
| `closedLossCents` | 退货 + 报废的全额亏损 | **所有**负利润之和 |
| `lossClosedCount` | 退货 + 报废单数 | 不变（保证 `closedCount` 不重复计数） |
| `soldLossCents` | — | 新增：sold/completed 中负利润之和 |
| `lossCount` | — | 新增：所有亏损单数（卡片显示「N 单亏钱」用它） |

`realizedProfitCents` 保持定义 = `settled + unsettled`，因此**变成只含盈利单**；`totalProfitCents = realizedProfitCents + closedLossCents` 公式不变，净额不变（正 + 负 = 净），这是本次改动最重要的自检点。

`closedCount = soldCount + lossClosedCount` 保持原样：`lossClosedCount` 不把贱卖算进去，否则贱卖单会被数两遍。

### D3 利润率分子改用已售净额

```dart
double? realizedMarginRate(int cost) =>
    cost == 0 ? null : (realizedProfitCents + soldLossCents) / cost;
```

`averageRealizedCents` 同理改用净额：`(realizedProfitCents + soldLossCents) ~/ soldCount`。分母（已售成本）不动——一批货有赚有亏时，"这批货的回报率"应该用净额除以全部成本，而不是只拿赚钱那部分去除。

### D4 明细过滤放在 provider 层，不写进 SQL

亏损判据依赖「单笔利润」，而利润 = 卖价 − 买价 − 该单费用合计，横跨两张表。在 SQL 里算要 join 费用并聚合，容易与 `ProfitLine` 口径漂移。

做法：`ItemFilter` 加 `bool onlyLoss = false`；`itemListProvider` 拿到 `watchList` 的流后 `.map` 过滤 `profitCents < 0`。

> 代价：列表多拉了一遍全量行。当前数据量是个人账本（千级），可接受；真到需要分页时再下推 SQL。
> 否决：在 `item_dao.listRows` 里拼 `sell_price - buy_price - expense < 0` —— 与 `ProfitLine.profitCents` 是两份口径，迟早对不上。

### D5 看板卡片

```dart
_MetricCard(
  title: '了结亏损',
  value: Money(summary.closedLossCents).toYuanString(),
  hint: '${summary.lossCount} 单亏钱',
  footnote: '贱卖的差价损失，加上退货/报废按「买入价 + 费用」全额计的亏',
  onTap: () => onOpenItems('了结亏损', onlyLoss: true),
)
```

`_OpenItems` 签名加 `bool onlyLoss = false`，`_openItems` 原样塞进 `ItemFilter`。

顺带把「已到手利润」「未到手利润」两张卡的 `footnote` 补一句「亏钱的单不在这里，看『了结亏损』」，避免下次又困惑一次。

### D6 明细页的「只看亏损」标签

列表页筛选条新增一个可关闭的标签（文案「只看亏损」），只在从看板带进来时出现；点关闭就回到全部。它不进筛选弹窗，因为这是个派生维度，不是用户日常会主动切的条件。

### D7 不做的事

- 不改单笔利润公式（`profitCents`）
- 不把亏损拆成「贱卖亏损 / 退货报废亏损」两张卡（本次只统一口，不新增展示维度）
- 不改 Excel 导出列（导出的「利润」仍是单笔净额，正负都有——它本来就是单笔事实，没被分栏）
- 不做亏损按月趋势图

## 测试 seam（写第一个测试前需用户确认）

| seam | 抓什么 | 漏什么 |
| --- | --- | --- |
| `ProfitCalculator.aggregate`（纯函数） | 贱卖进 `closedLossCents` 且不进 `settled/unsettled`；`lossCount` 计上贱卖；`closedCount` 不重复计数；总利润等于逐单相加 | 不测 UI |
| `ProfitSummary.realizedMarginRate`（纯函数） | 一赚一亏时分子是净额、分母是全部已售成本 | 不测按日期的分组 |
| `ItemFilter.onlyLoss` + `itemListProvider`（内存库 + provider 测试） | 只出 `profitCents < 0` 的行；与汇总的 `lossCount` 条数一致 | 不测 SQL 层面 |
| 看板卡片（widget） | 「了结亏损」卡可点、文案含「单亏钱」、点击后打开列表 | 不测真实滚动位置 |
| 列表页筛选标签（widget） | 带 `onlyLoss` 打开时显示「只看亏损」标签，关闭后恢复全部 | 不测组合标签的既有行为 |

断言值一律写字面量（`-1700`、`3`、`0.10`），不按实现重算。

## 风险

- **看板数字会变**：已到手/未到手利润会因为剔掉亏损而变小（亏损挪到另一张卡），用户第一眼可能以为数据丢了。缓解：两张卡的 footnote 明确指向「了结亏损」；README 版本历史写清。
- **净额不变是硬约束**：改完必须验证「利润栏 + 亏损栏 == 逐单利润直接相加」，这条断言写进测试，防止以后有人只改一边。
- **`closedCount` 重复计数**：`lossClosedCount` 一旦把贱卖算进去，空态判断与「已了结单数」都会虚高。缓解：贱卖单数只用新字段 `lossCount`，`lossClosedCount` 保持退货+报废。
- **provider 层过滤的性能**：数据量大时首屏会多算一遍全量费用聚合。当前量级无感，不做优化。
