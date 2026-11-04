## ADDED Requirements

### Requirement: 列表必须标出置换单与抵扣金额

`tradeInCents > 0` 的商品在明细列表卡片上 SHALL 有可辨识的置换标识，并显示抵扣金额。判定口径只有一个：`tradeInCents` 非空且大于 0。

#### Scenario: 置换成交的单子出现在列表里

- **WHEN** 某商品状态为已卖出且 `tradeInCents = 80000`（800 元）
- **THEN** 卡片标题旁出现「置换」徽章
- **AND** 价格行显示「抵 ¥800」

#### Scenario: 非置换单

- **WHEN** 商品的 `tradeInCents` 为 null 或 0
- **THEN** 卡片上没有「置换」徽章
- **AND** 卡片上没有任何抵扣金额文字

### Requirement: 详情必须标出置换单与抵扣金额

商品详情页 SHALL 在页头给出置换标识，并把旧机抵扣作为独立可见的一行展示；有挂牌价时一并保留。

#### Scenario: 打开置换单的详情

- **WHEN** 用户点开 `tradeInCents = 80000` 的商品
- **THEN** 页头出现「置换」标识
- **AND** 卖出信息里「旧机抵扣」显示 ¥800
- **AND** 若 `listPriceCents` 有值，「挂牌价」照常显示

#### Scenario: 打开非置换单的详情

- **WHEN** 商品的 `tradeInCents` 为 null 或 0
- **THEN** 页头没有「置换」标识
- **AND** 不出现「旧机抵扣」行

### Requirement: 抵扣金额不并入利润

旧机抵扣 SHALL 只作为留痕展示，MUST NOT 计入利润、总投入或待收货款。利润仍为 `卖出价 - 买入价 - 费用`。

#### Scenario: 置换单的利润

- **WHEN** 商品买入 700 元、卖出 1500 元、旧机抵扣 800 元、无其他费用
- **THEN** 该单利润为 800 元（1500 − 700）
- **AND** 不是 1600 元（把抵扣当收入），也不是 0 元（把抵扣当成本）
- **AND** 汇总里的「置换抵扣合计」单独累计 800 元
