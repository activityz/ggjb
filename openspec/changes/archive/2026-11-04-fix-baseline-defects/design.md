# 设计：修掉测试暴露的 5 个缺陷

## 上下文

5 条缺陷全部由已落盘的 skip 用例固定住，改法只动局部，不新增表、不改 schema、不改 provider 结构。测试写法的共同前提见 `openspec/changes/archive/2026-11-04-test-baseline-green/design.md` 与项目 `AGENTS.md` §2。

## 决策

### D1 修复点放在 `ItemRepository.save`，而不是只在导入器里

`save` 的分支目前只看 `draft.id == null`。改成：id 非空时先 `findById`（含软删）判断存在性，存在走 update（保留 `createdAt`/`deviceId` 的 `Value.absent()` 约定），不存在走 insert。

理由：导入器不是唯一会给出「外部 id」的调用方，编辑页未来也可能带着一个已被清空的 id 进来；把「id 指向不存在的行」这一情况在仓库层收敛，比在每个调用方各判一次更少漏。软删行算「存在」，保持复活语义不变（已由 `item_repository_test.dart` 的「带 id 复活已软删费用」覆盖）。

代价：save 多一次 `SELECT`，本地 SQLite 可忽略。

### D2 `_headerIndex` 的缺失哨兵是 -1，判断改成 `< 0`

`_headerIndex` 对每个期望列 `putIfAbsent(name, () => -1)`，所以 `itemIndex[title]` 永远是 int 不是 null，`if (titleColumn == null)` 死分支。改为提前取 `final titleColumn = itemIndex[ExcelSchema.title] ?? -1;` 并判断 `titleColumn < 0`。

不改成「不 putIfAbsent」——那会让 `_cell` 的 -1 语义散落到调用点，反而更容易再次写错。

### D3 `_tableDelta` 的本地 id 快照前移到合并事务之前

`merge.dart` 现在在 `_db.transaction` 之后 `SELECT id FROM $table`，此时远端独有行已经插入，差集恒空 → 全部算 replaced。把快照挪到事务开头（`await _db.transaction(() async { final localIds = ...; ... })` 的第一句）。

D1 修好后这条更明显：插入的行原本被计成覆盖，同时 update 0 行的 bug 让新人看不到数据，两个缺陷叠在一起表现为「同步说覆盖了 1 条，但那台设备上什么都没有」。

### D4 图片解码用 try/catch 兜住所有异常，不只 null 判断

`decodeImage` 对过短输入抛 `RangeError` 而不是返回 null。改成：

```dart
img.Image? decoded;
try {
  decoded = img.decodeImage(input);
} catch (_) {
  decoded = null;
}
if (decoded == null) throw ImagePipelineException('无法解析图片数据');
```

不细分异常类型：调用方只关心「这张图能不能用」，区分 RangeError 与 null 对用户没有额外信息。

### D5 运营成本删除后 invalidate 三件

照抄同文件 `_openEditor` 已用的写法：`operatingCostsProvider`、`operatingTotalProvider`、`profitSummaryProvider`。不加本地 `setState` 移除行——drift 流会推新值，手动改内存列表会和流打架。

## 测试策略（TDD）

5 条 skip 用例就是红灯：先删 `skip:`，跑出 5 个失败，再按 D1–D5 改生产代码，逐条转绿。断言值来自本 spec 的 Scenario 与独立事实（导入一行 → 库应多一行；远端独有一行 → inserted=1），不按实现反推。

## 风险

- D1 多一次查询：可忽略。
- D2 若 `ExcelSchema.title` 常量名与 `itemHeaders` 里的表头不一致，判断会失效 —— 现有用例「最小行（名称+买入价）」会立刻红。
- D3 若远端快照本身包含重复 id，差集仍正确（Set 去重）。
- D5 若 invalidate 后页面正在编辑弹窗，弹窗数据不动（弹窗用局部 controller），符合预期。
