# 任务

> 纪律：本清单按 TDD 排序，每个 seam 先红后绿；§2 的 seam 表见 design.md。

## 1. 领域口径

- [x] 1.1 `app/lib/domain/profit.dart`：`ProfitSummary` 增加 `soldLossCents`（sold/completed 的负利润合计）与 `lossCount`（全部亏损单数）；`lossClosedCount` 保持「退货 + 报废单数」
- [x] 1.2 `ProfitCalculator.aggregate`：按 `profitCents` 正负分栏——`>=0` 进 `settled`/`unsettled`，`<0` 进 `loss`；sold/completed 的负利润另记 `soldLossCents`；退货报废仍全额计亏
- [x] 1.3 `realizedMarginRate` 与 `averageRealizedCents` 的分子改用净额（`realizedProfitCents + soldLossCents`），分母不变
- [x] 1.4 `merge` / `operator ==` / `hashCode` 同步补两个新字段

## 2. 测试先行（红灯）

- [x] 2.1 `profit_test.dart`：贱卖的单进 `closedLossCents`、不进 `settled/unsettled`；`lossCount` 计上贱卖；`closedCount` 不因贱卖重复计数
- [x] 2.2 同上：**净额不变**断言——「利润栏 + 亏损栏」等于逐单利润直接相加；四类状态混合给出字面量结果（−1700 / 3）
- [x] 2.3 同上：利润率一赚一亏时分母 2000、分子 200、结果 10%
- [x] 2.4 新增 `app/test/app/item_filter_loss_test.dart`：`onlyLoss` 经 `itemListProvider` 只出亏损行；与日期筛选可叠加 —— 4 条
- [x] 2.5 新增 `app/test/features/dashboard/loss_card_test.dart`：卡片 hint 为「2 单亏钱」；点击回调打开的是亏损明细 —— 2 条
- [x] 2.6 新增 `app/test/features/item_list/loss_filter_label_test.dart`：「只看亏损」标签出现与点掉后恢复全部 —— 2 条
- [x] 2.7 全量 `flutter test`：438 条全绿（基线 425 + 新增 13）

## 3. 实现

- [x] 3.1 `providers.dart`：`ItemFilter` 加 `bool onlyLoss`（含 `copyWith` / `==` / `hashCode`）
- [x] 3.2 `itemListProvider` 在流上 `.map` 过滤 `profitLine.profitCents < 0`
- [x] 3.3 `dashboard_page.dart`：`_OpenItems` 签名加 `bool onlyLoss`；`_openItems` 透传进 `ItemFilter`
- [x] 3.4 「了结亏损」卡接 `onTap`，`hint` 改「N 单亏钱」，`footnote` 说明含贱卖与退货报废
- [x] 3.5 「已到手利润」「未到手利润」两张卡 footnote 补一句「亏钱的单不在这里，看『了结亏损』」
- [x] 3.6 `item_list_page.dart`：筛选条显示可关闭的「只看亏损」标签；空态 `hasFilter` 计入 `_onlyLoss`；`initState` / `_onRefresh` 透传

## 4. 验证

- [x] 4.1 `flutter test` → `+438: All tests passed!`
- [x] 4.2 `flutter analyze` → `No issues found!`
- [x] 4.3 `openspec validate loss-scope-and-drilldown --strict` → `Change 'loss-scope-and-drilldown' is valid`
- [ ] 4.4 手工核对（待用户）：造一条贱卖单 + 一条退货单，看板上「了结亏损」两者都算进去，点开明细是这两条；再点掉「只看亏损」标签确认恢复全部

## 5. 收尾

- [x] 5.1 与 `merchant-warranty-card` 一起发版，共用 `1.10.0+12`（未单独升号）
- [x] 5.2 `README.md` 1.10.0 那一行补「亏损卡口径涵盖贱卖，可点开明细」
- [ ] 5.3 汇报里提醒：看板「已到手 / 未到手利润」会因剔除亏损而变小，「了结亏损」变大，总利润不变

## 6. 缺陷修复：看板卡片手指点不动（用户验收发现）

- [x] 6.1 根因：`GlassCard._wrapGesture` 无条件装 `GestureDetector`（为按压光斑挂 `onTapDown/onTapUp`），它进手势竞技场且在卡片内侧先赢，外层 `onTap` 永远收不到 —— 五张指标卡全部点不动；此前「直接调回调」的测试对这个故障是瞎的
- [x] 6.2 红灯：`loss_card_test.dart` 改为真实指针点击（`tester.tap`），并新增「看板五张卡都能点开明细」；修复前 2 条全红（第一张卡就失败）
- [x] 6.3 `app/lib/ui/glass_card.dart`：无 `onTap`/`onLongPress` 时不装手势层
- [x] 6.4 `app/lib/features/dashboard/dashboard_page.dart`：`_MetricCard` 把 `onTap` 交给 `GlassCard`（保留光斑与按压反馈，去掉外层 `GestureDetector`）；可点卡标题行加箭头
- [x] 6.5 新增 `app/test/ui/glass_card_test.dart`：无 `onTap` 不抢外层点击 / 自带 `onTap` 能交回调用方
- [x] 6.6 `flutter test` → `+441: All tests passed!`（基线 438 + 新增 3）；`flutter analyze` → `No issues found!`
- [x] 6.7 重出 Windows 免安装包（1.10.0+12，含此修复）供用户复测
