# 任务

> 纪律：按 TDD 排序，先红后绿。seam 表见 design.md §「TDD seam 表」。

## 1. 测试先行（红灯）

- [x] 1.1 S1：`detail_field_parity_test.dart` 把「内存规格」断言改成「规格」，并新增「详情页找不到『内存规格』」；新增编辑页用例或扩展现有编辑页测试，断言标签为「规格」
- [x] 1.2 S2：详情页能找到 `SelectionArea`；页面上没有 `Icons.copy` 图标与「复制」文字的按钮
- [x] 1.3 S3：真库造一张图 —— 点开大图、点「删除」、确认后图片区少一张；另一条用例：点「删除」后取消，图还在且大图仍打开

## 2. 实现

- [x] 2.1 改名三处：编辑页标签、详情页属性行、`DictSeeds` storage 组标签
- [x] 2.2 `_body` 返回的 `ListView` 外层包 `SelectionArea`
- [x] 2.3 大图弹窗右上角加「删除」：确认后关弹窗再删，取消则保持打开；顺带把「保存 / 关闭」顺序排好

## 3. 验证

- [x] 3.1 `flutter test` → `+464: All tests passed!`（基线 460 + 新增 4）
- [x] 3.2 `flutter analyze` → `No issues found!`
- [x] 3.3 `openspec validate detail-copy-rename-image-delete --strict` 通过
- [ ] 3.4 手工核对（待用户）：详情页能长按选中复制、没有复制按钮；大图里能删图；字段名显示「规格」

## 4. 收尾

- [x] 4.1 版本号升到 `1.11.2+16`（`app/pubspec.yaml` 与 `installer/ggjb.iss` 两处）
- [x] 4.2 `README.md` 版本历史补一条
- [ ] 4.3 出包（等用户开口）
