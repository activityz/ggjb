# 设计：费用 id 往返

## 决策

### D1 表头叫「费用id」，放第一列

和「商品id」同一套命名（`<对象>id`，全小写 id）。放第一列是为了让人的眼睛
先看到身份列；导入是按表头名取列（`_headerIndex`），所以列序对解析没有影响，
老文件也不会因为顺序变化而读错。

### D2 缺列 = 没有 id，不是错误

`_headerIndex` 对缺失列填 -1，`_cell` 遇到 -1 返回空串。因此只要常量登记进
`expenseHeaders`，旧文件天然得到 `rawId = ''` → `draft.id = null` → 走插新行。
这条路径不需要额外分支，也不需要版本号。

### D3 不新写覆盖逻辑，复用 `ItemRepository.save`

`save` 里费用循环已经是「有 id 且本地存在 → 复活 + 覆盖；否则插新行」。
这次只要让 `parse` 把 id 填进 `ExpenseDraft`，写入端一行不用改。
重复造一套覆盖逻辑会让两条路径的口径漂移。

### D4 重复 id 在 parse 阶段拦下

表和表之间会出现「同一笔费用挂到两个商品」的编辑事故。放在 parse 阶段拦，
用户能在预览里看到行号，而不是写库写到一半炸主键。用 `Set<String> seen`
在 `_parseExpenses` 里记录，命中即 `errors.add` 并 `continue`。

### D5 导出仍然只导未删的行

`excel_export.dart` 的费用查询已有 `deletedAt.isNull()`，保持不变：
墓碑不进表，用户拿到的是「当前账本」，不是历史。

## 影响面

| 文件 | 改动 |
| --- | --- |
| `app/lib/data/exchange/excel_rows.dart` | 新增 `expenseId = '费用id'`，插到 `expenseHeaders` 首位 |
| `app/lib/data/exchange/excel_export.dart` | 费用行首格写 `expense.id` |
| `app/lib/data/exchange/excel_import.dart` | 读 id 列、查重、传给 `ExpenseDraft` |

## 测试策略

- 导出：表头首项是「费用id」、值等于库里 id。
- 导入：带 id 命中已存在行 → 行数不变、id 不变；命中软删行 → 复活。
- 兼容：去掉「费用id」列的表 → 无错误、按新行写入。
- 查重：两行同 id → `preview.ok == false`，信息含行号。

## 风险

1. **手改表把 id 抄错**：会插出一条新费用，同时在原商品那边把旧费用打成墓碑
   （全量替换语义）。这是用户主动改身份列的后果，不额外兜。
2. **跨商品搬 id**：`save` 会把该费用的 `itemId` 改成表里的商品，原商品少一条。
   属于用户明确表达「这笔归那边的账」，按字面执行。
3. **旧文件 + 新文件混导**：旧文件导入仍会产生一次墓碑，这是没有 id 就无从
   匹配的必然结果，不做启发式匹配（按金额+日期猜会错得更离谱）。
