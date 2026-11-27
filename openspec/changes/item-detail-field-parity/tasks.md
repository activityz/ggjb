# 任务

> 纪律：按 TDD 排序，先红后绿。seam 表见 design.md §「TDD seam 表」。

## 1. 测试先行（红灯）

- [x] 1.1 S1 新增 `app/test/features/item_detail/detail_field_parity_test.dart`：造一件品牌 `Apple`、型号 `iPhone 13`、内存 `128G`、颜色 `蓝色`、分类 `手机`、序列号 `F2LX1234ABCD` 的商品，打开详情页 —— 六项的字段名与值都能找到；页面上找不到 `Apple · iPhone 13 · 128G · 蓝色` 拼接行
- [x] 1.2 S2 续：分类与序列号为空的商品 —— 两行仍在、值为「—」
- [x] 1.3 S2 续：厂家保修三态（`none` / `expired` / `active`）各自的显示：无保修 → 「无保修」；已过保 → 「已过保」；在保 → 起止日期两行

## 2. 实现

- [x] 2.1 `item_detail_page.dart`：新增「商品属性」卡（复用 `_kv`），六行顺序为 品牌 → 型号 → 内存规格 → 颜色 → 分类 → 序列号，缺值「—」；位置在标题/置换徽标之后、利润卡之前
- [x] 2.2 删除标题下那行 `品牌 · 型号 · 内存规格 · 颜色` 拼接小字（连同 `_modelLine` 之外的拼接逻辑）
- [x] 2.3 厂家保修状态为 `none` 时补一行「厂家保修：无保修」；保留 `expired` 与 `active` 的现有显示

## 3. 验证

- [x] 3.1 `flutter test` → `+460: All tests passed!`
- [x] 3.2 `flutter analyze` → `No issues found!`
- [x] 3.3 `openspec validate item-detail-field-parity --strict` 通过
- [ ] 3.4 手工核对（待用户）：随便开一条记录，分类/序列号都在，品牌型号内存颜色是四行而不是一行

## 4. 收尾

- [x] 4.1 与「保修卡条款」改动合并发版：版本号 `1.11.1+15`（已按此升号）
- [x] 4.2 `README.md` 1.11.1 条目已合并写入「商品属性卡」与「无保修」说明
- [ ] 4.3 出包（等用户开口）
