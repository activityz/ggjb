## Context

需求 #6 的代码在 2026-11-04 已落地并通过 `flutter analyze`（fvm 3.47.1，No issues found），但当时没有测试。同时 `flutter test` 基线为 `+68 -4`，4 条失败源于 v5 未提交改动先落地、测试期望值未同步。本 change 只做测试对齐与回归覆盖，不回改生产代码。

## 状态口径依据

`app/lib/domain/profit.dart` 的 `aggregate` 是唯一口径来源：

- `case ItemStatus.sold` → `soldCount++`、`receivableCount++`、`pendingReceivable += sellPriceCents`
- `case ItemStatus.completed` → 只 `soldCount++`
- `inStock` / `listed` → `activeCount++`、`capitalOccupiedCents +=`

由此推出看板三胶囊的筛选集合，代码必须与之一一对应：

| 胶囊 | 汇总字段 | 筛选集合 |
| --- | --- | --- |
| 已卖出 | `soldCount` = sold + completed | `{sold, completed}` |
| 待收 | `receivableCount` = sold | `{sold}` |
| 未卖 | `activeCount` = inStock + listed | `{inStock, listed}` |

「在途占用」数字卡走 `capitalOccupiedCents`，与「未卖」同集合，故复用 `{inStock, listed}`。

## 关键决策

### D1：用 `Set<ItemStatus>? statuses` 扩展，而不是把 `status` 改成集合

`ItemFilter.status` 已被明细列表的单选 chip、搜索页等处调用。改类型会让这些调用点全部要重写并重新推理 null 语义。新增并列字段 `statuses` 保持单选路径不动，多状态只走新字段；DAO 里 `statuses` 优先、`status` 兜底。

被否掉的备选：`Set<ItemStatus>` 一个字段通吃 —— 单选用 `{x}` 表达，看似更干净，但会把「无筛选」与「空集」两义合流，`hasFilter` 判断变得不可读，且要改所有既有调用点。

### D2：`==` / `hashCode` 手写，Set 按内容比较

`ItemFilter` 是 riverpod `family` 的 key。若 `Set` 按引用比较，每次 `setState` 新建的集合都不相等，family 会永久 miss 并反复重建 drift 订阅（列表闪、查询抖）。实现为顶层函数 `_sameStatuses` / `_statusesHash`，其中 hash 用 `Object.hashAll(ItemStatus.values.where(statuses.contains))` 保证与枚举声明顺序无关、与集合内容一一对应。

### D3：胶囊用 `GestureDetector(opaque)`，不用 `InkWell`

胶囊是 11px 小字 + 紧凑内边距，`InkWell` 的水波纹与 splash 会盖住文字可读性。可点时尾部加 12px `chevron_right` 作为可点性提示。

### D4：四张数字卡一并可点

原始需求只写了三颗胶囊。但四张卡展示的是同一批汇总数字，用户看到数字就想点下去是同一个预期；一边能点一边不能点，是更差的一致性。口径见上表。

### D5：4 条期望值直接改成新值，不改生产代码

判断依据是工作区代码本身（`dict_seeds.dart` 已有 `kindOperating` 与 `operating` 列表；`excel_rows.dart` 商品表已含三列）。这些是已存在的实现，测试是滞后的那一侧。**不**借此把这个 change 扩展成「给 v5 全部未提交功能补 spec」—— 那批 spec 应由各自 change 承担，否则本 change 会变成巨型追认。

### D6：旧数据兼容不做

`毛利` → `利润` 改名后，旧导出文件重新导入时该列被忽略（`excel_import.dart` 只强制要求「名称」列存在，见 [:127](<app/lib/data/exchange/excel_import.dart#L127>)）。用户已明确现有数据均为测试数据，不需要别名映射，也不做迁移脚本。

## 测试 seam

按 `tdd` skill：只在 public 边界测试，先确认 seam 再写。

| seam | 抓什么 | 漏什么 |
| --- | --- | --- |
| `itemListProvider`（ProviderContainer + 内存 drift） | 状态集合过滤真的下推到 SQL、结果集合正确 | 不覆盖 UI 点击链路 |
| `ItemListPage` widget | 组合标签出现/清除、单选高亮 | 不覆盖看板入口 |
| `DashboardPage` widget | 三胶囊可点、下钻带对的状态集合与时间范围 | 不覆盖真实数据库查询语义 |

三处都测是刻意的：单测 DAO 过滤抓不住「看板传错集合」，widget 测不入库抓不住 SQL 层 `isInValues` 写错。

## Risks

- `DashboardPage` / `ItemListPage` 都是 `ConsumerStatefulWidget` 且依赖多个 provider，widget 测试需要 `ProviderScope(overrides:)` 注入内存库与预置数据，样板代码较多。若某文件难以在测试里构造，优先降级到 provider 层 seam，并在 tasks 里记录降级理由。
- 时间范围继承的断言依赖 `DateRange` 的语义（相对时间会被求值为具体区间），测试里应固定「本周/本月」为显式区间，避免跨零点抖动。
