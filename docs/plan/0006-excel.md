# 0006 · Excel 导入导出

## 执行进度

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| P0 | 依赖落地（`excel 4.0.6`，`image` 降到 `^4.3.0` 解 archive 冲突） | ✅ 完成 |
| P0 | `excel_rows.dart`（表头 22 + 7、枚举映射、只读列集合） | ✅ 完成 |
| P0 | `excel_export.dart`（两个 sheet，盈亏取自 `ProfitLine`） | ✅ 完成 |
| P0 | `excel_import.dart`（表头名定位、全量校验、三种 id 语义） | ✅ 完成 |
| P1 | 设置页「导出 Excel」「导入 Excel」两个入口 + 错误弹窗 + 确认弹窗 | ✅ 完成 |
| P2 | 单测（`app/test/data/excel_schema_test.dart`，15 个用例） | ✅ 完成 |
| P2 | 文档（README「Excel 导入导出」段、`docs/agent/memory.md` §9） | ✅ 完成 |
| P2 | 回归 `flutter analyze` + `flutter test` | ✅ 72 项全过 |
| P2 | 重新构建 APK | ⏸ **等用户明确确认**（m01379） |

## 目标

1. 把全部记录导出成 `.xlsx`，能直接用 Excel / WPS / 手机表格打开查看和编辑。
2. 把改过的 `.xlsx` 导回来，有 id 的更新对应商品，没 id 的新增。
3. 导入前全量校验，任何一行不合格就整体不导入，并报出具体行号。

## 非目标

- **不导出图片二进制**。xlsx 里塞 JPEG 会让文件从几十 KB 膨胀到几十 MB，而且 Excel 对图片锚点支持很弱。图片仍走「导出整库快照」或局域网同步。
- 不支持 `.xls`（老格式，纯 Dart 解析库不支持）。
- 不做多表关联重建（如「客户表」「渠道表」），字典只作为下拉值导出，不建引用。
- 不替代 `.db` 快照备份 —— 快照是完整还原，Excel 是给人看、给人改的。

## 依赖

`excel` 包（纯 Dart，读写 xlsx，无原生依赖，Windows/Android 都能用）。

装法：`flutter pub add excel`。若该包版本与现有 `analyze` / `drift_dev` 的依赖冲突，退回锁定具体版本号写进 `pubspec.yaml` 再 `pub get`——**不要 `pub add dev:xxx`**，PowerShell 会把 `dev:` 当驱动器名。

## 导出结构（两个 sheet）

### Sheet 1「商品」

一行一个商品，第一行是表头。

| 列 | 字段 | 说明 |
| --- | --- | --- |
| A | `id` | **隐藏列**。导出带、导入认；用户看不见也不该改 |
| B | 名称 | `items.title`，必填 |
| C | 分类 | `category` |
| D | 品牌 | `brand` |
| E | 型号 | `model` |
| F | 内存 | `storage` |
| G | 颜色 | `color` |
| H | 状态 | 中文标签（在库/已上架/已卖出/已到账/已退货/已报废），导入时反查 `dbValue` |
| I | 买入价 | 元，两位小数（**不是分**） |
| J | 买入日期 | `yyyy-MM-dd`，空表示未填 |
| K | 买入来源 | `sourcePlatform` |
| L | 买入成色 | `conditionBought` |
| M | 卖出价 | 元；未卖出留空 |
| N | 卖出日期 | `yyyy-MM-dd` |
| O | 卖出渠道 | `sellPlatform` |
| P | 卖出成色 | `conditionSold` |
| Q | 费用合计 | 公式算好的值，元。**只读展示，导入时忽略** |
| R | 总投入 | 买入价 + 费用合计 |
| S | 毛利 | `卖出价 - 总投入`；未卖出留空 |
| T | 毛利率 | 毛利 / 总投入，百分比；总投入为 0 留空 |
| U | 备注 | `note` |
| V | 批次号 | `lotId` |

Q~T 四列是**导出时算好写死的值**，不是 Excel 公式 —— 因为导入时要忽略它们，写公式反而会让用户以为能改。

毛利率用 `ProfitLine.marginRate` 的值，**必须走 `domain/profit.dart` 的计算**，不在这里重算（纪律：利润只在 profit.dart 算）。

### Sheet 2「费用明细」

| 列 | 字段 |
| --- | --- |
| A | 商品 id（对应 Sheet1 的 A 列） |
| B | 商品名称（方便人看） |
| C | 种类 | 中文标签（运费/买入手续费/卖出手续费/维修/包装/其他） |
| D | 侧别 | 买入 / 卖出 |
| E | 金额 | 元 |
| F | 发生日期 | `yyyy-MM-dd` |
| G | 备注 |

一个商品有多条费用就多行；没有费用的商品在 Sheet2 里不出现。

## 导入流程

1. 选文件 → 校验扩展名 `.xlsx`。
2. 读两个 sheet。
3. **全量校验**，收集所有错误（不是遇到第一个就停，一次把所有问题报给用户）：

| 检查 | 报错文案 |
| --- | --- |
| Sheet1 第 1 行表头缺「名称」列 | `表头不对：找不到「名称」列，请用本应用导出的文件改` |
| 名称为空 | `第 7 行：「名称」不能为空` |
| 买入价不是数字 | `第 7 行：买入价「一百」不是数字` |
| 买入价为空 | `第 7 行：「买入价」必须填` |
| 状态不在六个标签里 | `第 7 行：状态「已付款」不认识，只能是：在库/已上架/已卖出/已到账/已退货/已报废` |
| 状态是已卖出/已到账但卖出价为空 | `第 7 行：状态是「已卖出」但没填卖出价` |
| 日期不是 `yyyy-MM-dd` | `第 7 行：买入日期「2026/1/5」格式不对，要 2026-01-05` |
| Sheet2 的商品 id 在 Sheet1 找不到 | `费用明细第 4 行：商品 id「xxx」在商品表里不存在` |
| 费用金额不是数字 | `费用明细第 4 行：金额「20块」不是数字` |

4. 任何一条错误 → 弹错误清单，**一行都不写库**。
5. 全部通过 → 再弹确认框「将新增 N 件、更新 M 件、写入 K 条费用」，确认后在一个事务里写完。

### 写入语义

- Sheet1 的 `id` 有值且本地存在 → **更新**（`updatedAt = now`，`deviceId = 本机`，`createdAt` 保留）。
- Sheet1 的 `id` 有值但本地不存在 → 当新增，但**用 Excel 里那个 id**（这样两台设备用同一个 Excel 各自导入，id 一致，后续同步不会重复）。
- Sheet1 的 `id` 为空 → 新生成 UUID。
- 费用：按商品全量替换 —— 先给该商品所有现有费用打墓碑，再插 Excel 里的行（与 `ItemRepository.save` 的现有语义一致，避免 Excel 删掉的行在库里残留）。

**这是唯一一处会「删数据」的地方**：如果在 Excel 里删掉某个商品的某条费用再导回来，那条费用会消失。确认框里要写清楚。

## 代码结构

| 文件 | 动作 |
| --- | --- |
| `app/pubspec.yaml` | 加 `excel` |
| `app/lib/data/exchange/excel_export.dart` | 新建。`class ExcelExportService { Future<File> exportAll(); }`，走 `ItemDao.allItems()` + `allExpenses()` + `allProfitLines()` |
| `app/lib/data/exchange/excel_import.dart` | 新建。`class ExcelImportService { Future<ExcelPreview> parse(File); Future<void> apply(ExcelPreview); }` |
| `app/lib/data/exchange/excel_rows.dart` | 新建。表头常量、列序、中文↔dbValue 映射，导入导出共用一份，避免两边对不上 |
| `app/lib/features/settings/settings_page.dart` | 「备份」卡片加两个 ListTile：导出 Excel / 导入 Excel |
| `README.md` | 补一段说明 |

`ExcelPreview` 里装解析结果：`items`（待写商品）、`expenses`（待写费用）、`newCount` / `updateCount` / `expenseCount`、`errors: List<String>`。

## 风险

| 风险 | 处理 |
| --- | --- |
| `excel` 包与 `drift_dev` 的 analyzer 版本冲突 | 先 dry-run 看解算结果；冲突就降 `excel` 版本，实在不行退回自己写最小 xlsx 读写（xlsx 本质是 zip+XML，`archive` 包已在依赖里） |
| 用户用手机上改 Excel，日期被改成 `2026/1/5` | 日期解析宽容一点：同时接受 `yyyy-MM-dd`、`yyyy/M/d`、Excel 日期序列号 |
| 金额浮点误差 | 解析时用字符串 → `Money.tryParseYuan`（已有 4 舍 5 入），不经过 `double` |
| 覆盖已有数据 | 确认框列出「新增 N / 更新 M / 覆盖费用 K 条」，用户点确认才写 |
| 列顺序被用户拖动 | **按表头名定位列，不按列号**。缺列就报「表头不对」，不要静默错位 |

## 验收

1. `analyze` 无 issue，`test` 全过。
2. 导出后能用 WPS / Excel 打开，中文不乱码，金额是数字不是文本（能求和）。
3. 导出 → 改两行 → 导回来，改动能落地，未改的行不受影响。
4. 故意把某行买入价改成「一百」→ 报「第 7 行：买入价「一百」不是数字」，库里一条没变。
5. 导出的 Excel 删掉某条费用再导回来，该费用从库里消失（确认框有提示）。
6. 构建 APK / exe 需用户明确确认后才执行。
