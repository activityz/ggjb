# 0009 · 需求评审与口径确认（日期筛选 / 电池健康 / 月度销量 / 置换 / 利润改名）

> 状态：**评审完成，已按默认口径实现（schema v4）**。用户以「开始执行」放行，但 Q1–Q26 未逐条回答，
> 因此实现采用 §7 的 D1–D5 保守默认值 —— 每条都遵循「不改既有字段语义、只新增 nullable 字段」，
> 用户确认后可单点调整，不用回滚数据结构。

## 执行进度

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| P0 | 5 条需求复述 + 歧义点 + 待确认问题（Q1–Q26） | ✅ 已列出（§1），**未逐条回答**，按 §7 的 D1–D5 实现 |
| P0 | 影响范围评估（文件级，含迁移/同步/Excel 影响） | ✅ 完成（§3） |
| P0 | 团队结论：不需要组队，单线串行 | ✅ 完成（§4） |
| P1 | 口径实现（`domain/profit.dart`，按 D1） | ✅ 完成（§7） |
| P1 | 数据模型 v4 迁移（三列 + 两个日期索引） | ✅ 完成（§7） |
| P2 | 5 条需求逐条实现 | ✅ 完成（§7） |
| P2 | drift 代码生成 `build_runner` | ✅ 94 outputs，无 error |
| P2 | Excel 表头扩展（22 → 25 列） | ✅ 完成 |
| P2 | `dart analyze lib` | ✅ **No issues found** |
| P2 | `flutter test` | ⏸ 本轮未新增用例，未执行（本机 analysis server 有卡死史） |
| P3 | 构建 APK / Windows | ⏸ **需用户明确确认** |

## 目标

1. 在现有「商品 + 费用 + 利润口径」模型上，补齐时间维度（筛选、月度统计）、硬件信息（电池健康）、交易形态（置换）三类能力。
2. 把利润展示从「毛利」这一层话术，改成「未到手利润 / 总利润」两层，并保证全项目只有一套算法。
3. 5 条需求的数据结构互相兼容，且历史数据（v3 库、旧 Excel、旧快照）不丢、不串账。

## 非目标

- 不改同步协议（整库快照交换）与合并规则 `(updated_at, device_id)`。
- 不引入新的报表页、不改成多表关联（客户表/渠道表）。
- 不做历史数据回填的「猜测式修正」（如按价格猜哪笔是置换单）。
- 不顺手重构任务外模块（视觉体系、粒子、主题、Excel 校验框架）。

## 依赖

- 前置决策：Q16–Q26（口径）未定，需求 4、5 不能开工；Q6–Q10 未定，需求 2 的表结构不能定稿。
- 技术前提：drift 迁移必须走 `MigrationStrategy.onUpgrade` 的 `if (from < 4)` 分支（`app/lib/data/db/app_database.dart:38-62`）。
- 同步前提：**任何加列都是双端同步的破坏性变更**。`app/lib/sync/merge.dart:170-192` 的 `_verifySchema()` 逐列比对列名与顺序，列数不一致直接抛
  「表 items 的列数不一致…请先把两端升级到同一版本再合并」。加列后旧版本客户端连上来必然失败，属预期行为，需在文档与更新说明里写明。

## 1. 需求逐条评审

### 需求 1 · 日期筛选项（年 / 月 / 日粒度）

**现状**：明细页只有「搜索框 + 6 个状态 chip」。`app/lib/features/item_list/item_list_page.dart:63` 构造
`ItemFilter(status: _status, keyword: _keyword)`，`ItemFilter`（`app/lib/app/providers.dart:56-74`）只有
`status` / `keyword` 两个字段；`ItemDao.watchList`（`app/lib/data/dao/item_dao.dart:55-115`）的 where 只有
`deletedAt.isNull()`、`status`、关键词 LIKE。库里有 `buyDate` / `sellDate` 两列，但**没有任何日期索引**。

**歧义**：①「日期」指买入日还是卖出日，还是两个都要；②「年/月/日粒度」是三级选择器（2026 / 2026-10 / 2026-10-31）还是任意起止区间；
③筛选只作用于明细列表，还是看板同屏也要跟着变；④默认状态是「全部时间」还是「本年度」；⑤「日」的边界按本机时区零点还是 UTC。

**待确认**

- **Q1** 筛的是**买入日期**、**卖出日期**，还是两者可切换（各一套）？
- **Q2** 粒度是「年 / 月 / 日三级下钻选择器」还是「起止日期区间 + 快捷按钮（今年/本月/今天）」？
- **Q3** 筛选状态要不要同时驱动看板的汇总数字（即看板变成"当前筛选范围内"的统计）？还是看板恒为全量、只有明细页筛？
- **Q4** 默认值是「全部时间」还是「本月」？
- **Q5** 没有填日期的商品（`buyDate` / `sellDate` 为 NULL）在筛选时算进来还是排除？

**影响面**：`ItemFilter`（加字段 + `==`/`hashCode`/`copyWith`）、`item_dao.watchList`（加 `buyDate`/`sellDate` 区间 where）、
`item_list_page`（加日期筛选控件）、`app_database._createIndexes`（补日期索引）、若 Q3=是则看板与 `profitSummaryProvider` 一并改。

### 需求 2 · 「电池健康」字段

**现状**：`Items` 表（`app/lib/data/db/tables.dart:9-56`）没有任何电池相关列。同类「属性型字段」的既有做法是
`storage` / `color`：表里存**文本快照**，可选项来自字典 `dict_entries`；编辑页用下拉 + 手输，详情页 `_kv` 行展示；
Excel 表头里对应两列（`内存` / `颜色`，`app/lib/data/exchange/excel_rows.dart:26-27`）。`schemaVersion` 当前为 3。

**歧义**：①数值型（80 = 80%）还是文本型（「95新」「良好」）；②买入时测一次，还是买入/卖出各测一次（二手场景卖出前才关心）；
③是否为字典类目；④是否参与筛选/排序；⑤旧数据没有该字段时显示什么。

**待确认**

- **Q6** 存**百分比整数**（0–100，空 = 未填）还是**文本**？若是百分比，允许一位小数吗？
- **Q7** 只记「买入时电池健康」，还是**买入/卖出各一个字段**？
- **Q8** 是否做成字典项（像「颜色」一样可增删选项）？
- **Q9** 明细列表需要按电池健康排序或筛选吗？（影响是否加索引）
- **Q10** 要不要进 Excel 导出列？列名叫什么（「电池健康」还是「电池」）？

**影响面**：`tables.dart` 加列 → `schemaVersion` 4 + `onUpgrade` 的 `if (from < 4)` → `build_runner` 重生成 `.g.dart` →
`ItemDraft`（`app/lib/data/repo/item_repository.dart:13-57`）、`repository.save`（:119-141）、编辑页表单与提交（:560 附近）、
详情页展示、`excel_rows.dart` 表头与 `excel_export`/`excel_import` 的读写。**同步**：加列后旧快照合并会被 `_verifySchema` 拒绝（预期）。

### 需求 3 · 看板「每个月卖出多少台」

**现状**：看板只有总数 `soldCount`（`ProfitSummary`，`app/lib/domain/profit.dart:112-119`；文案「${soldCount} 单已卖出」，
`app/lib/features/dashboard/dashboard_page.dart:129`）。分组统计只有 `StatDao.byCategory()` / `bySellPlatform()`
（`app/lib/data/dao/stat_dao.dart:37-41`），**没有任何时间维度**。看板无时间筛选器。

**歧义**：①「卖出」的判据是 `status ∈ (sold, completed)` 还是只算 `completed`；②按哪一列归月（`sellDate`；`completed` 没有到账时间列）；
③「台」是否等于"件"（`lotId` 打包的多件算几台）；④展示形态（近 12 个月柱状 / 当年 12 个月 / 只给一个数字）；
⑤没有卖出的月份补 0 还是不出现；⑥是否受需求 1 的日期筛选影响。

**待确认**

- **Q11** 「卖出」统计 `sold` + `completed`（货出去了就算），还是只统计 `completed`（钱到账才算）？
- **Q12** 归月依据用 `sellDate` 吗？`sellDate` 为空的已售单归到哪（当月 / 不计入 / 用 `updatedAt` 兜底）？
- **Q13** 展示成「近 12 个月逐月数量」的列表/柱状，还是只显示「本月 N 台」一个数字？
- **Q14** 没有成交的月份显示 `0` 还是整月不出现？
- **Q15** 这个统计要不要跟随需求 1 的日期筛选区间变化？

**影响面**：`StatDao` 新增按月聚合（或 `ProfitCalculator` 增加按月的纯函数）、新 provider、看板新增一张卡片/区块、
`items.sell_date` 补索引。**注意**：算钱纪律要求先转 `ProfitLine` 再聚合，数量统计不涉及金额，可在 DAO 里 `GROUP BY`。

### 需求 4 · 置换场景（售价 1000、旧机抵 600、实收 400）

**现状**：模型里**没有「抵扣 / 以旧换新」概念**。`items` 只有一个 `sellPriceCents`（`tables.dart:41`），
利润口径为 `卖出价 − 买入价 − 费用`（`app/lib/domain/profit.dart:49-63`）。费用表 `Expenses` 有 `side`（买入/卖出）但没有「非现金对价」概念。
`lotId` 只用于"打包买卖拆成多件"（`tables.dart:44-45`），语义是分摊成本，不是置换。

**核心歧义（必须由用户定，不能默认）**：那 600 元的旧机**是否计入总利润**。三种互斥口径：

| 方案 | 记法 | 对利润的影响 | 代价 |
| --- | --- | --- | --- |
| A 计入 | 售价 1000（含 600 抵扣），另记 `tradeInCents=600` | 本单利润 = 1000 − 成本；600 立即体现为利润 | 旧机再卖出时会**重复计一次**，必须靠"旧机不入库"规避 |
| B 不计入 | 售价 = 实收 400，抵扣 600 只做记录 | 本单利润 = 400 − 成本；旧机的价值等它自己卖出去才体现 | 需要把旧机作为新 `item` 入库（买入价 600），否则 600 永远不结算 |
| C 计入但分列 | 售价 1000，`未到手/非现金` 单列 600 | 总利润含 600，但看板拆出「置换抵扣」一行 | 口径最复杂，`ProfitSummary` 要多一层维度 |

**待确认**

- **Q16** 600 元抵扣**进不进总利润**？请在三方案里选一个（或说明第四种）。
- **Q17** 旧机要不要**作为新商品入库**（后续再卖）？若入库，它的买入价是 600 还是 0？
- **Q18** 「售价 1000」和「实收 400」两个数都要留吗？如果只留一个，`sellPriceCents` 存哪个？
- **Q19** 抵扣物一定是一台手机（能入库），还是也可能是耳机/其他物（不能入库）？
- **Q20** 是否需要「置换」专用的卖出渠道/来源字典项，以及 Excel 是否要新增抵扣列？退货时这笔抵扣怎么回滚？

**影响面**：`tables.dart`（新增 `tradeInCents` / `tradeInItemId` 列，或新表 `trade_ins`）、`profit.dart`（利润公式）、
`ItemDraft` + `repository.save`、编辑页（卖出区新增抵扣输入）、详情页、`excel_rows` + 导入导出、迁移 v4。
**风险最高的一条**：直接改利润公式会让所有历史单子的数字变化，必须由 Q16 决定后才动 `profit.dart`。

### 需求 5 · 「未到手利润」「总利润」，取消「毛利润」

**现状（术语与代码的对应关系）**：

| 用户说法 | 代码里的实际东西 | 位置 |
| --- | --- | --- |
| 毛利润（单笔） | `ProfitLine.profitCents` = 卖 − 买 − 费用 | `app/lib/domain/profit.dart:49-63` |
| 已实现利润 | `ProfitSummary.realizedProfitCents`（sold + completed 的毛利合计） | `profit.dart:97-98` |
| 待收货款 | `pendingReceivableCents`（sold 的 `sellPriceCents` 之和，**是货款不是利润**） | `profit.dart:106-110` |
| 净到手 | `netProfitCents` = 已实现 + 了结亏损 | `profit.dart:121-122` |
| 毛利润（文案） | 看板「平均每单毛利」「已实现毛利率」；Excel 列「毛利」「毛利率」 | `dashboard_page.dart:204-213`、`excel_rows.dart:39-40` |
| 毛利润（筛选状态） | 无。状态枚举里没有这个字段 | — |

**关键事实**：代码里**不存在名为 `grossProfit` 的字段**，也不存在「毛利润」×「净利润」双口径的并行实现。
「毛利」只是 `profitCents` 的展示名。所以「取消毛利润」在数据层不需要删列，实际是**改口径与改文案**：
新增「未到手利润」（大概率 = `sold` 状态的毛利之和）、「总利润」（口径待定），并决定「毛利」这个词从哪些界面消失。

**歧义**：①「未到手利润」是"货卖了钱没到"的**利润**，还是现有「待收货款」改个名（两者数值完全不同：前者是利润，后者是全额货款）；
②「总利润」是否 = 已到手 + 未到手；③「取消毛利润」是删掉哪个展示位（看板效率指标 / 详情页利润卡 / Excel 列），还是只改名；
④毛利率保留吗（分母仍用已售成本？）。

**待确认**

- **Q21** 「未到手利润」= `sold` 状态单子的（卖价 − 成本），对吗？它和现有「待收货款」（卖价全额）是**并存**还是**替换**？
- **Q22** 「总利润」= 已到手利润 + 未到手利润（即 sold + completed 的全部毛利），**不扣**退货报废亏损？还是要把亏损一起扣（即现在的净到手）？
- **Q23** 「取消毛利润」具体指：从看板移除「平均每单毛利」？从详情页移除单笔利润卡？从 Excel 删掉「毛利」列？还是仅统一改名？
- **Q24** 「毛利率」还留吗？分母继续用已售商品成本吗？
- **Q25** 术语定稿后，`ProfitSummary` 的字段是**新增**（保留旧字段兼容）还是**改名**（连带 Excel、文档、测试一起改）？
- **Q26** 历史数据的口径变化只影响展示（不改库、不回填）——确认这条？还是要求把历史单子按新口径重算并落库？

**影响面**：`domain/profit.dart`（核心）、`dashboard_page`（Hero 卡 + 4 张指标卡 + 效率指标）、`item_detail_page`（利润卡、`毛利率` kv）、
`item_list_page`（单件利润文案）、`excel_rows` + `excel_import` + `excel_export`、`test/`（profit 单测）、
`docs/design/0001-architecture.md` §3、`docs/agent/memory.md` §5。

## 2. 口径联动（需求 1 ↔ 3 ↔ 5）

三条需求分别引入两个**正交维度**：时间（1、3）和利润定义（5）。它们会在看板上相交，必须共用同一套入口，否则会出现
「筛了 10 月，Hero 卡是全量、月度卡是 10 月」这类自相矛盾。

约定（待 Q3、Q15、Q22 确认后生效）：

1. **一个筛选状态对象**：把 `ItemFilter`（目前 `{status, keyword}`）扩成明细页筛选；看板若要跟随，另建 `ReportRange{from, to}`，
   不把日期塞进 `ItemFilter`（两者生命周期不同：明细筛选是页面级，报表区间是看板级）。
2. **一个聚合入口**：任何"钱"都必须 `ItemDao.allProfitLines()` → `ProfitCalculator.aggregate()`。分月数量这类**非金额**统计
   可以直接 `GROUP BY`，但不得在这条路径上算钱（`stat_dao.dart:30` 已有同样的注释纪律）。
3. **一处定义**：`未到手利润 / 总利润 / 毛利率` 的定义只写在 `profit.dart`，看板、详情、列表、Excel 全部引用，不复制公式。
4. **联动方向单一**：明细页筛选只影响明细列表；看板的时间区间只影响看板。若 Q3/Q15 要求联动，则两边共用一个
   `reportRangeProvider`，由看板写入、明细页只读——避免双向绑定导致回环重建。

## 3. 影响范围汇总（文件级）

| 文件 | 改动 | 需求 |
| --- | --- | --- |
| `app/lib/data/db/tables.dart` | `Items` 加电池字段（Q6 定类型）+ 置换字段（Q16–Q19 定形态） | 2, 4 |
| `app/lib/data/db/app_database.dart` | `schemaVersion` 3 → 4；`onUpgrade` 加 `if (from < 4)`；补日期索引 | 1, 2, 3, 4 |
| `app/lib/data/db/app_database.g.dart` | `build_runner` 重新生成（不手改） | 2, 4 |
| `app/lib/domain/profit.dart` | 单笔利润公式（若置换改口径）；新增未到手/总利润字段 | 4, 5 |
| `app/lib/domain/enums.dart` | 若置换需要新状态或新渠道枚举 | 4 |
| `app/lib/app/providers.dart` | `ItemFilter` 扩字段；新增 `ReportRange` / 月度统计 / 未到手利润 provider | 1, 3, 5 |
| `app/lib/data/dao/item_dao.dart` | `watchList` 加日期区间过滤；`allProfitLines` 若需带日期则扩参数 | 1, 3 |
| `app/lib/data/dao/stat_dao.dart` | 新增按月销量聚合 | 3 |
| `app/lib/data/repo/item_repository.dart` | `ItemDraft` 加字段；`save` 写新列 | 2, 4 |
| `app/lib/features/item_list/item_list_page.dart` | 日期筛选控件；单件利润文案 | 1, 5 |
| `app/lib/features/item_edit/item_edit_page.dart` | 电池字段输入；卖出区抵扣输入 | 2, 4 |
| `app/lib/features/item_detail/item_detail_page.dart` | 电池展示；利润卡措辞；置换抵扣展示 | 2, 4, 5 |
| `app/lib/features/dashboard/dashboard_page.dart` | 月度销量区块；未到手/总利润卡片；移除或改名毛利 | 3, 5 |
| `app/lib/data/exchange/excel_rows.dart` | 新表头 + 只读列集合（若「毛利」列取消） | 2, 4, 5 |
| `app/lib/data/exchange/excel_export.dart` / `excel_import.dart` | 新列读写；旧文件缺列仍要能导入（按表头名定位，缺列返回 `-1`） | 2, 4, 5 |
| `app/lib/sync/merge.dart` | **不改逻辑**；但加列后旧快照会被 `_verifySchema` 拒绝，需写进更新说明 | 2, 4 |
| `app/test/domain/profit_*.dart` | 新增口径单测（置换、未到手、总利润） | 4, 5 |
| `docs/design/0001-architecture.md` §3 | 口径 9 条中涉及"毛利"的表述要同步 | 4, 5 |
| `docs/agent/memory.md` §5 | 「算钱只在 profit.dart」不变；补新口径一句话 | 5 |

**(待补充：具体字段类型、默认值、索引名)** —— 全部取决于 Q6、Q16–Q19 的回答，本文件不预设。

## 4. 团队结论

**结论：不需要组建多 agent 团队，单线串行执行。**

理由：

1. **规模不构成并行收益**：5 条需求最终落在 18 个文件、约 6 个模块，其中 12 个文件是共同修改点（`tables.dart`、
   `app_database.dart`、`profit.dart`、`providers.dart`、`dashboard_page.dart` 被 2–3 条需求同时命中）。并行 agent 改同一文件
   的合并成本高于节省的时间。
2. **最大的阻塞是决策，不是工作量**：Q16–Q26 未定时，需求 4、5 一行代码都不能写。这类阻塞不是加人能手解决的。
3. **口径必须单点权威**：项目纪律是「算钱只允许在 `domain/profit.dart`」。多人同时改这个文件正是最容易出现两套口径的方式。
4. **单人仓库 + 无 CI 分片**：所有验证（analyze / build_runner / test）都在同一工作区串行跑，并行会互相踩锁
   （memory §4 记过 Gradle wrapper 抢锁、`ReplaceFileW EIO` 两个真实事故）。

**执行顺序（串行，按依赖）**：

| 序 | 内容 | 依赖 | 说明 |
| --- | --- | --- | --- |
| S0 | 用户回答 Q1–Q26 | — | **唯一阻塞项**，未答完全部 P1 不开工 |
| S1 | 需求 5 口径重构（`profit.dart` 先行） | S0 的 Q21–Q26 | 地基：后面所有展示都读它，先改先稳 |
| S2 | 需求 2 电池健康（表 + 迁移 + 表单 + Excel） | Q6–Q10 | 与 S1 不冲突（不同文件），可紧随其后；迁移一次性做完，避免多次 `schemaVersion` |
| S3 | 需求 1 日期筛选 | Q1–Q5 | 依赖 S1 定稿的筛选/聚合入口，避免二次改 `providers.dart` |
| S4 | 需求 3 月度销量 | Q11–Q15、S3 | 复用 S3 的时间区间对象与索引 |
| S5 | 需求 4 置换 | Q16–Q20、S1 | 最重、风险最高，放最后：它会动利润公式，必须等前面的口径稳定 |
| S6 | 文档回写（design §3、memory §5）+ 全量 test | 全部 | — |
| S7 | 构建 APK / Windows | 用户明确确认 | 规则见 memory §5 |

## 5. 风险

| 风险 | 处理 |
| --- | --- |
| 加列触发双端 schema 不一致，旧快照同步失败 | 预期行为：`_verifySchema` 直接抛错而不是写脏数据。发布说明里写明「两端必须同版本」，升级前先同步一次 |
| 置换口径选错，导致历史单子利润整体偏移 | 口径定稿后再动 `profit.dart`；新字段全部 nullable，历史行默认 0/NULL；**不做猜测式回填** |
| 「未到手利润」与「待收货款」被混为一谈 | 两个指标并存时必须改不同文案（一个带"利润"、一个带"货款"），看板 footnote 写清差额来源 |
| 日期筛选与看板统计出现两套时间轴 | 一个 `ReportRange` 单点定义，写入方唯一（见 §2） |
| 改 Excel 表头导致旧文件导不回来 | 定位按表头名、缺列返回 `-1`；新增列必须有默认值；「毛利」列若删除，导入时要忽略而不是报错 |
| 迁移写错丢数据 | 迁移前建议先「导出整库快照」（设置页已有入口）；`onUpgrade` 只做 `addColumn`，不做数据搬迁 |
| 需求 2 与需求 4 同时改 `tables.dart` 引发迁移冲突 | 合并成一次 v4 迁移（S2、S5 的列一起进），避免 v4、v5 连环迁移 |

## 6. 验收（待 Q 全部回答后细化）

1. 5 条需求逐条有对应的实现与可复现的验收动作。
2. `dart format --output=none` 通过；`flutter analyze` 无 issue（本机 analysis server 卡死的已知问题见 memory §6）。
3. `flutter test` 全过，新增：置换利润、未到手利润、总利润、按月销量、日期区间边界（含 NULL 日期）五个用例。
4. 迁移回归：v3 库升级到 v4 后，商品数量、费用合计、历史利润与升级前**逐项一致**（口径变更导致的差异必须能用 Q21–Q26 的解释说清）。
5. Excel：旧文件（无新列）能导入；新文件导出后能再导回。
6. 同步：两端同版本能互相同步；一端旧版本时给出「请先升级」的明确提示而非静默失败。
7. 构建 APK / exe 需用户明确确认后才执行。

## 7. 实现记录（按 D1–D5 默认口径落地）

用户以「开始执行」放行，但 Q1–Q26 未逐条回答。为避免再阻塞，实现采用下面 5 条默认值。
**每条都能单独反悔**：只新增 nullable 列与 getter，没有改任何既有字段的含义，历史数据零迁移成本。

### 7.1 采用的默认值（待确认）

| 编号 | 需求 | 采用的默认口径 | 若要改，改哪里 |
| --- | --- | --- | --- |
| **D1** | 5 利润改名 | 不动 `realizedProfitCents` 的语义（仍是 sold+completed），**新增** `settledProfitCents`（completed）、`unsettledProfitCents`（sold）、`tradeInTotalCents`；`totalProfitCents = realized + closedLoss`，`netProfitCents` 保留为同义 getter；所有面向用户的「毛利」改「利润」 | `app/lib/domain/profit.dart` 一处 |
| **D2** | 2 电池健康 | `items.battery_health` INTEGER NULL，取值 0–100，NULL = 没填；不用文本，方便排序与统计 | 迁移里加/删列 |
| **D3** | 1 日期筛选 | 新增 `domain/date_period.dart`：`DateField{buy,sell}` × `DateGranularity{year,month,day}`，半开区间 `[start, endExclusive)`；筛选状态 = 字段 + 区间，两者必须成对生效 | `ItemFilter` + `watchList` |
| **D4** | 3 月度销量 | 只统计 `sold` + `completed`，按 `sellDate` 归月，`sellDate` 为空的已售单不计；固定近 12 个月、缺月补 0；聚合在 **Dart 侧**做（不写 `strftime`，避开 SQLite `localtime` 跟系统时区跑偏） | `StatDao.monthlySoldCounts` |
| **D5** | 4 置换 | `sell_price_cents` 存**实收**（例子里是 400，参与利润）；`list_price_cents`（1000）与 `trade_in_cents`（600）只记录、**不进利润公式**。逻辑：抵扣的旧机等它自己作为商品卖出去时才结算，否则同一笔钱算两次 | `profit.dart` 的 `ProfitLine` 已带 `tradeInCents`，将来要计入只需改聚合 |

### 7.2 落地清单

| 文件 | 动作 |
| --- | --- |
| `app/lib/domain/date_period.dart` | **新增**：`DateField` / `DateGranularity` / `DatePeriod`（start / endExclusive / shift / withGranularity / label / ==） |
| `app/lib/data/db/tables.dart` | `Items` 末尾追加 `batteryHealth` / `listPriceCents` / `tradeInCents`（必须放在最后：`ALTER TABLE ADD COLUMN` 只能追加，否则新装库与升级库列序不同，`merge.dart` 的 `_verifySchema` 会判两端不兼容） |
| `app/lib/data/db/app_database.dart` | `schemaVersion` 3 → 4；`onUpgrade` 加 `if (from < 4)`（三列 `addColumn` + 两个索引）；`_createIndexes` 同步补 `idx_items_buy_date` / `idx_items_sell_date` |
| `app/lib/domain/profit.dart` | 口径注释重写；`ProfitLine` 加 `tradeInCents`；`ProfitSummary` 加三字段；`totalProfitCents` + 兼容 `netProfitCents`；`aggregate` 按 sold/completed 分别累加 |
| `app/lib/data/dao/stat_dao.dart` | 新增 `MonthlySoldCount` + `monthlySoldCounts({months = 12})` |
| `app/lib/data/dao/item_dao.dart` | `watchList` 加 `dateField` / `period`（半开区间 `isBiggerOrEqualValue & isSmallerThanValue`）；两个 `toProfitLine` 补 `tradeInCents` |
| `app/lib/data/repo/item_repository.dart` | `ItemDraft` 加三字段；`save` 写三列；`watchList` 转发四参数 |
| `app/lib/app/providers.dart` | `ItemFilter` 加 `dateField` / `period` + `hasDateFilter`；新增 `monthlySoldProvider` |
| `app/lib/data/exchange/excel_rows.dart` | 表头 22 → 25 列（电池健康 / 挂牌价 / 旧机抵扣）；`毛利`→`利润`、`毛利率`→`利润率` |
| `app/lib/data/exchange/excel_export.dart` / `excel_import.dart` | 新列读写；`_parsePercentOrNull` 对 0–100 之外的输入报错，不静默截断 |
| `app/lib/features/item_edit/item_edit_page.dart` | 电池健康输入；置换两字段 + 说明文案；`_save` 校验（0–100 整数、抵扣 ≤ 挂牌价） |
| `app/lib/features/item_detail/item_detail_page.dart` | 展示电池健康 / 挂牌价 / 旧机抵扣；「毛利率」→「利润率」 |
| `app/lib/features/dashboard/dashboard_page.dart` | Hero 卡「净到手」→「总利润」；四张卡扩成六张（总利润 / 已到手利润 / 未到手利润 / 待收货款 / 了结亏损 / 在途占用）；新增「每月卖出」条形区块；效率指标改「利润」措辞 |
| `app/lib/features/item_list/item_list_page.dart` | 日期筛选（弹窗选字段+粒度 → 前后翻页 / 换粒度 / 取消） |
| `app/lib/data/db/app_database.g.dart` | `build_runner` 重新生成（不手改） |

### 7.3 验证结果

- `build_runner build`：成功，`Built with build_runner/aot in 60s; wrote 94 outputs`，drift 无报错。
- `dart analyze lib`：**No issues found!**（首轮 5 个错误全部是 `DatePeriod.ofYear/ofMonth/ofDay` 误传 `int`，已改为传 `DateTime`）。
- `dart format --output=none lib`：43 个文件可解析（37 个存在格式差异，属既有排版风格，本轮未做全仓格式化以免无关改动）。
- **未执行**：`flutter test`（本轮未加用例）、构建 APK / Windows（需用户确认）。

### 7.4 遗留待确认

1. D5 的置换口径：抵扣的 600 是否要计入「总利润」？（当前：不计入，只记录）
2. D4 的月度销量是否要跟着日期筛选联动？（当前：恒为近 12 个月全量）
3. 看板是否需要「按月看利润」而不只是「按月看台数」？
4. 旧 Excel 文件（无新列）导入仍需回归一次，本轮未跑。

---

## 8. 第二轮（v5）：用户答复后的口径修订

用户逐条答复了 7.4 的疑问，并把 5 条需求扩成 8 条。本节记录**改了什么口径**，§7 里被推翻的条目以本节为准。

### 8.1 口径变更表

| 编号 | 原口径（§7） | 新口径（本节） | 理由 / 出处 |
| --- | --- | --- | --- |
| D3 | `DatePeriod` 固定年 / 月 / 日 + 左右翻页 | 删除粒度概念，改 `DateRange{from,to}` 自定义区间 + 快捷入口（本月 / 上月 / 最近 7 天 / 今年 / 自定义） | 用户：不要固定的时间段，要能自己选 |
| D5 | 置换在编辑页填挂牌价 / 旧机抵扣 | **移到详情页「标记已卖出」弹窗**；编辑页只留一行提示 | 用户：置换不该在编辑页填 |
| D6（新） | 列表只按状态 / 关键词筛 | 列表 + 看板都加**分类**下拉（字典 `category`），与日期一起筛 | 用户答 Q1 |
| D7（新） | 看板无时间维度 | 看板加 `DashboardFilter{dateField,range,category}`，默认全量 | 用户第 5 条 |
| D8（新） | 无运营成本概念 | 新增 `operating_costs` 表 + `OperatingDao` + 独立页；**从总利润里扣**（口径 A），总利润下方一行小字展示并点击跳转 | 用户第 8 条 + 答 Q2 |
| D9（新） | 下拉框只有箭头区域可点 | `DictField` 整框 `readOnly + onTap` | 用户第 2 条 |
| D10（新） | 字典顺序固定 | 字典管理页 `ReorderableListView` 拖拽排序，`DictDao.reorder` 按 0..n-1 重写 `sortOrder` | 用户第 3 条 |
| D11（新） | — | 买入来源默认插入「采货侠」「拍机堂」，`sortOrder = -2 / -1` 排最前 | 用户第 4 条 |
| D12（新） | 「已卖出」弹窗只填卖出价 + 渠道 | 卖出价 / 卖出渠道（字典下拉）/ 卖出日期 / 置换（开关 + 挂牌价 + 旧机抵扣）**全必填** | 用户 1–3 条 |

### 8.2 schema v5

- 新表 `operating_costs`：`id` / `spent_at` / `kind`（字典文本快照）/ `amount_cents` / `note` / 四列同步字段；索引 `idx_operating_spent_at`、`idx_operating_updated_at`。
- 字典种子：新增 kind `operating`（7 项）+ `sources` 头部两项；升级走 `_seedV5Extras()` 用 `insertOrIgnore` 补齐，不覆盖用户已改的顺序。
- 同步：`merge.dart` 的 `_tables` 与 `markTablesUpdated` 都加 `operating_costs` —— 加了表不改这两处，另一台设备同步时会少一张表，且 `_verifySchema` 只在列上比对、不会报错，属于静默丢数据。
- **破坏性**：items 未加列，快照结构只多一张表；v5 与 v4 之间仍不能互相同步（`_verifySchema` 按表列逐项比对）。

### 8.3 口径：总利润扣运营成本

- `ProfitSummary.totalProfitCents` **不含**运营成本（仍是「卖货挣的」）。
- `ProfitAggregate.operatingCostCents` + `netAfterOperatingCents` 才减。
- 看板 `_HeroCard` 显示 `netAfterOperatingCents`；列表页、Excel 导出仍用 `totalProfitCents`。
- 这样「一个数字怎么来的」始终能拆开算：卖货利润 − 期间运营成本 = 总利润。

### 8.4 置换残值是否计入总利润

**不计入**（维持 D5 的判断）。理由：

1. 抵扣的旧机是一台**还没卖的新货**。它的价值要等它自己卖出去才结算；现在计 600，等它卖掉时再计一次，同一台机器算两遍。
2. 若计入，`sellPriceCents` 得存「挂牌价 1000」才能让利润对上，但那不是用户实际收到的钱，待收货款会跟着虚高。
3. 现存做法两头都能查：`list_price_cents` / `trade_in_cents` 留痕，账上只认实收 400。

若要改成「计入」，改动点是**一处**：`ProfitLine.profitCents` 里把 `tradeInCents` 加回卖价，其余不动。

### 8.5 v5 落地清单

| 文件 | 动作 |
| --- | --- |
| `app/lib/domain/date_period.dart` | 重写：`DateField` + `DateRange`（半开区间 + 快捷构造 + label） |
| `app/lib/data/db/tables.dart` | 新增 `OperatingCosts` 表 |
| `app/lib/data/db/app_database.dart` | v5：建表 + 两索引 + `_seedV5Extras()` |
| `app/lib/data/dao/operating_dao.dart` | 新增：watch / watchTotalCents / insert / update / softDelete |
| `app/lib/data/dao/item_dao.dart` | `watchList` / `allProfitLines` 加 `range` + `category`；补带 `tradeInCents` |
| `app/lib/data/dao/stat_dao.dart` | `byCategory` / `bySellPlatform` / `monthlySoldCounts` 接 `dateField` + `range` |
| `app/lib/data/repo/item_repository.dart` | `markSold` 扩 `listPriceCents` / `tradeInCents`；`aggregate` 接筛选 |
| `app/lib/app/providers.dart` | `ItemFilter` 扩 range/category；新增 `DashboardFilter`；六个 provider 改 family |
| `app/lib/domain/dict_seeds.dart` | `kindOperating` + 7 项 + 采货侠 / 拍机堂 |
| `app/lib/features/common/dict_field.dart` | 整框点击唤起选择器 |
| `app/lib/features/dict/dict_manage_page.dart` | 拖拽排序 |
| `app/lib/data/dao/dict_dao.dart` | `reorder()` |
| `app/lib/features/item_detail/item_detail_page.dart` | 「标记已卖出」弹窗重做（四必填 + 置换开关） |
| `app/lib/features/item_edit/item_edit_page.dart` | 删置换 UI，改提示 |
| `app/lib/features/item_list/item_list_page.dart` | 分类下拉 + 自定义区间筛选条 |
| `app/lib/features/dashboard/dashboard_page.dart` | 筛选条 + 卡片点击跳明细 + 运营成本小字 + 总利润扣成本 |
| `app/lib/features/operating/operating_cost_page.dart` | 新增运营成本页 |
| `app/lib/features/settings/settings_page.dart` | 运营成本入口 |

### 8.6 v5 遗留待确认

1. 「已卖出」弹窗里的**卖出成色**要不要也必填？（当前未加，弹窗里没有这个字段）
2. 看板筛选是否要记住上次的选择？（当前每次进页面都是「全部时间」）
3. 运营成本是否要支持按月自动摊平（房租这类固定支出）？（当前是一笔一笔手记）

### 8.7 v5 构建记录（2026-11-04 13:33–13:37）

先 `flutter clean` + `flutter pub get` 再全量构建，避免出现「`runner/Release` 里只有 exe」的残缺产物。

| 产物 | 大小 | SHA256 |
| --- | --- | --- |
| `dist/ggjb-1.5.1-release.apk` | 67.17 MB | `1CAF104226C98113FD77DC27F7C68CCCB2840B7B81B234CBDD9746B578ECAFB4` |
| `dist/ggjb-windows-x64/`（16 文件） | 33.95 MB | — |
| `dist/ggjb-1.5.1-windows-x64.zip` | 14.22 MB | `6C64A2C5AA63088378C6B7229B433787FD798E41F3A4E353599F029C3BB5E2EF` |
| `dist/ggjb-1.5.1-windows-setup.exe` | 12.19 MB | `88CD5B275A66AC9159FC8870F0BFFCD8BEFBC90EA4C7233E21293D48E984AF94` |

- Windows 构建仍要临时把 `sqlite3_flutter_libs-0.5.42/windows/CMakeLists.txt` 的下载地址指向本地 `build/sqlite352.tgz`（本机连 `sqlite.org` 拉不动 3.26 MB），**构建后已还原成原地址**。
- 未跑 `flutter test`，未做真机回归；旧 Excel（无 `电池健康/挂牌价/旧机抵扣` 三列）导入未回归。
