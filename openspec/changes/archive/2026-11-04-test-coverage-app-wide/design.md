# 设计：全项目测试铺开的方式

## 上下文

44 个非生成 `.dart` 文件里只有 5 个测试文件。本 change 记录「怎么在不动生产代码的前提下，把这套东西测起来」，以及被测试环境逼出来的写法约定。

## 决策

### D1 只测 public 面，不 mock 内部协作者

DAO 直接打 `AppDatabase(NativeDatabase.memory())`；仓库层打 `ItemRepository` 的公开方法；同步层起真 `shelf` 服务与真 HTTP，不用 mock 替身。理由：mock 会把「实现改了但行为没变」也判红，反过来把「行为变了」判绿（mock 跟着改）。唯一被 fake 的外部依赖是 `path_provider`（`PathProviderPlatform.instance`），因为它在测试进程里没有平台实现。

### D2 widget 测试的三件套固定写法

theme 必须 `buildAppTheme(Brightness.light).copyWith(splashFactory: NoSplash.splashFactory)`；`ProviderScope` 必须 override `databaseProvider` + `deviceIdProvider` + `deviceNameProvider`（后两个默认实现直接 throw）；drift 的流走真实异步，settle 用 6 轮 `runAsync(20ms)` + `pump(120ms)`，收尾 `pumpWidget(SizedBox.shrink())` + `pump(1ms)` 收 markAsClosed 定时器。

这些都是被测代码的既有约束，不是测试将就实现——写进 `theme_test.dart` / 各页面测试的注释里。

### D3 断言值来自独立事实，不按实现重算

金额断言用常量（1200 元 → 120000 分），时间区间用独立构造的 `DateTime` 边界，同步计数用「远端几行、本机几行」这类可数的东西。不调用被测的同名算法反向生成期望值，否则测试永远绿。

### D4 页面测试只测「用户能看到的差异」，不测像素

断言按钮文案集合、组合标签的存在与否、库里状态字段，不做 golden。理由：项目在用 v5 迭代视觉，golden 会天天红。

### D5 `dict_manage_page` 只留冒烟

任何 `setState` 都会重建 `ReorderableListView`，在本机 flutter test 下触发 framework 断言（`RawGestureDetector` / `_dependents.isEmpty`）。放弃交互用例，写路径由 `dict_dao_test`（insert/rename/reorder/softDelete）覆盖。这是测试环境限制，已在文件里注明。

## 风险

- 真 HTTP 用例会占本地端口：统一 `port: 0` 让系统分配，`addTearDown` 关服务。
- 内存库每个用例重建：单文件 20 条量级耗时 < 2s，全量 27s，可接受。
- `flutter test` 在 PATH 的 3.35.4 上跑不了（intl 解算失败），全部命令锁 fvm 3.47.1。
