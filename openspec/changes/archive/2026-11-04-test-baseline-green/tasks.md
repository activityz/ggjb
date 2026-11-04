## 1. 测试基线对齐（无生产代码改动）

- [x] 1.1 `app/test/domain/dict_seeds_test.dart:7` kinds 数 8 → 9（新增 `operating`）
- [x] 1.2 `app/test/domain/dict_seeds_test.dart:34` 常量数 9 → 8（断言方向与 1.1 相反，改前先读该断言实际的比较对象）
- [x] 1.3 `app/test/domain/dict_seeds_test.dart:41` 扁平字典类数 6 → 7
- [x] 1.4 `app/test/data/excel_schema_test.dart:8` 商品表列数 22 → 25
- [x] 1.5 跑 `flutter test`，确认从 `+68 -4` 变为 `+72 -0`（条数以实际为准，失败数必须为 0）

## 2. Seam 确认（写测试前完成，见 design.md「测试 seam」）

- [x] 2.1 确认 `itemListProvider` 断言用的内存 drift 库构造方式（`NativeDatabase.memory()` + 迁移）
- [x] 2.2 确认 `DashboardPage` / `ItemListPage` 的 widget 测试能否不桩掉主题与路由；不能就降级 seam 并记录理由

## 3. 先写测试（本批是 characterization，不是 TDD 驱动）

> 用户裁决「甲」：#6 的生产代码在本次之前已实现，本批测试取不到真实红灯。
> 因此承认其为 **characterization test** —— 目标是锁定既有行为、防止后续回归，
> 不承担驱动新实现的职责。执行口径：
> - 断言依据是 `specs/dashboard-drilldown/spec.md` 的 scenario，不是读实现反推。
> - 断言若失败 → 现有实现与 spec 不符，先报告，不在本 change 里顺手改生产代码。
> - 汇报必须注明「无真实红，本批为 characterization」。

- [x] 3.1 `itemListProvider` 传 `statuses: {sold, completed}`，断言结果只含这两个状态、不含 inStock/listed
- [x] 3.2 `ItemListPage` 以两个状态打开，断言组合标签「在库 + 已上架」存在且单状态标签不高亮
- [x] 3.3 `ItemListPage` 点掉组合标签，断言回到「全部」且列表条数等于全集
- [x] 3.4 `DashboardPage` 点「已卖出」胶囊，断言跳转后列表承接 `{sold, completed}`
- [x] 3.5 `DashboardPage` 筛选弹窗内断言不存在「分类」下拉

## 4. 绿：最小实现

- [x] 4.1 若 3.x 有断言失败，先报告缺陷再决定是否修；全部通过则本组不产生代码改动，在 tasks 记录「无代码变更，测试即锁定行为」
- [x] 4.2 复核无「按实现同算法重算期望值」的 tautological 断言（期望值取自 profit.dart 口径表或手工数出的字面量）

## 5. 验证

- [x] 5.1 `D:/develop/flutter/fvm/versions/3.47.1/bin/flutter.bat test` → 0 失败
- [x] 5.2 `D:/develop/flutter/fvm/versions/3.47.1/bin/flutter.bat analyze` → No issues found
- [x] 5.3 `openspec validate test-baseline-green` → 通过

## 6. 收尾

- [x] 6.1 汇报贴 `flutter test` 前后输出摘要，并注明「无真实红，本批为 characterization」
- [x] 6.2 `openspec archive test-baseline-green`（需用户确认后执行）
