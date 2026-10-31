# 计划：新增「已到账」状态（sold / completed 双阶段）

> 需求确认于 m01393。用户已确认：
> ① sold 与 completed **都计入已实现利润**，看板另单列「待收款」；
> ② 可回退：已完成 → 已卖出 → 在库；
> ③ 命名：`已卖出` / `已到账`（原「已售出」改名，`dbValue` 保持 `sold` 不变）。
>
> 状态：**待批准**。

## 目标确认

把「货卖了」和「钱到了」拆成两个状态，让看板能区分「确定的收入」和「真到手的钱」。

```
在库 in_stock → 已上架 listed → 已卖出 sold（货走了，钱在路上）→ 已到账 completed
                                        ↓                              ↓
                                   退货 returned                 退回已卖出
                                   报废 scrapped
```

范围边界：
- 只改状态机与口径展示，不动同步协议、不动数据结构（`status` 是 TEXT，加枚举值不需要迁移）。
- `sold` 的 `dbValue` 保持 `'sold'`，只改中文 label —— 已导出的快照不会因改名而失效。
- 不引入新状态之外的字段。

## 计划

| 优先级 | 待办 | 简易程度 | AFK | 验收方式 |
| --- | --- | --- | --- | --- |
| P0 | `ItemStatus` 加 `completed('completed','已到账')`；`sold` 的 label 改「已卖出」；`isRealized` 改为 `sold \|\| completed`；新增 `isSettled`（completed）、`isReceivable`（sold） | 简单 | 5 | 枚举往返测试通过；`isRealized` 对 sold/completed 都为 true |
| P0 | `profit.dart` 的 `ProfitSummary` 加 `pendingReceivableCents`（sold 的卖出价合计）与 `receivableCount`；确认 `profitCents` 逻辑无需改（走 `isRealized`） | 中等 | 4 | 单测：1 单 sold + 1 单 completed → realized 含两者、pendingReceivable 只含 sold |
| P0 | 补单测覆盖新状态：sold 未到账、completed 已到账、completed 退货路径 | 中等 | 4 | `flutter test` 新增用例全过 |
| P1 | 详情页：`sold` 显示「标记已到账」按钮；`completed` 显示「退回已卖出」，且**不直接给退货/报废按钮**（先退回才能退） | 中等 | 4 | 手点完整流转一圈 |
| P1 | 列表徽章配色 + 筛选器加「已到账」；`已卖出` 用警示色（钱没到手） | 简单 | 4 | 列表上能一眼分清两态 |
| P1 | 看板新增「待收款」指标卡（`pendingReceivableCents` + `receivableCount` 单） | 简单 | 4 | 有 sold 单时出现金额 |
| P1 | 编辑页状态下拉加「已到账」；`isSellSide` 判断补 completed（两个状态都显示卖出价/日期/渠道） | 简单 | 4 | 选「已到账」能填卖出信息 |
| P2 | 文档：`0001-architecture.md` §3 口径表加「已到账/已卖出」两行；`README.md` 状态流转图 | 简单 | 5 | 文档与代码一致 |
| P2 | 回归 `assert`/`analyze`/`test` 全绿 | 简单 | 4 | 三条全 0 |
| P2 | 重建 APK —— **需用户明确确认后才执行** | 中等 | 0 | 构建成功 + 新 SHA256 |

## 依赖与并行

```
P0-1 (枚举) → P0-2 (口径) → P0-3 (单测)
                                 ├→ P1-4 (详情页)
                                 ├→ P1-5 (列表)
                                 ├→ P1-6 (看板)
                                 └→ P1-7 (编辑页)
                                        ↓
                                   P2-8 → P2-9 → P2-10(需确认)
```

P0 三项必须串行（枚举改了才能算口径，口径定了才能写测试）。P1 四项改不同文件，可并行但建议逐个做。

## 风险

| 风险 | 影响 | 应对 |
| --- | --- | --- |
| 「待收款」到底算卖出价还是利润，容易含糊 | 看板数字对不上 | 定为**卖出价合计**（买家欠我的钱），措辞写清「待收货款」 |
| `soldCount` 语义变化（现在含 completed） | 看板「已售 N 单」口径漂移 | 保持 `soldCount` = 已卖出总数（含到账），另加 `receivableCount` 专指未到账 |
| 已完成的单不能直接退货 | 用户会想点退货 | 详情页把「已完成」的按钮组换成「退回已卖出」，并在提示里说明 |
| 编辑页 `isSellSide` 漏掉 completed | 选「已到账」时卖出价输入框不出现 | 显式枚举判断，不用 `!= inStock` 这类偷懒写法 |

## 与计划 0002（字典化）的关系

两个计划都改 `item_edit_page.dart`，但改的是不同区域（0003 改状态下拉附近的 `isSellSide`，0002 改品牌/型号那几个字段）。
**建议先做 0003**（改动小、独立、不依赖字典），做完再做 0002，避免两处同时改动同一个文件产生冲突。

## 下一步

`to-coding`。两个计划（0002 / 0003）都需要你先批；批哪个我按哪个走。
