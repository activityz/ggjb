## ADDED Requirements

### Requirement: 明细列表的筛选只提供日期维度

明细列表（`ItemListPage`）的筛选条 SHALL 只提供「按日期筛选」一个入口，MUST NOT 出现任何分类选择控件。看板下钻带来的状态集合与时间范围照旧生效，但筛选条本身不再有分类项。

#### Scenario: 打开明细列表

- **WHEN** 用户从任意入口进入明细列表
- **THEN** 筛选条只有日期 chip / 按钮
- **AND** 页面上不存在「全部分类」下拉，也不存在其他分类选择控件

#### Scenario: 从看板下钻带着时间段进入

- **WHEN** 看板带着 `DateField` + `DateRange` 下钻到明细列表
- **THEN** 筛选条显示日期 chip（如「卖出日期 · 本月」）
- **AND** 多状态组合标签仍照常显示、可清除

### Requirement: 分类筛选的代码路径一并移除

`category` 作为**筛选条件**的入口 SHALL 从 `ItemFilter`、`ItemDao.watchList`、`ItemRepository.watchList`、`ItemRepository.aggregate` 上移除，不留永远为 null 的死参数。

#### Scenario: 构造列表筛选条件

- **WHEN** 代码构造 `ItemFilter`
- **THEN** 没有 `category` 参数可传
- **AND** `watchList` / `aggregate` 的签名里也不再出现 `category`

### Requirement: 分类作为商品属性不受影响

移除筛选 MUST NOT 改动商品自身的分类字段与它的下游用途。

#### Scenario: 编辑商品

- **WHEN** 用户在编辑页填写分类并保存
- **THEN** `items.category` 正常落库

#### Scenario: 看统计

- **WHEN** 打开统计页的分类分布
- **THEN** 仍按 `items.category` 分组，空值归入「未分类」

#### Scenario: 导出表格

- **WHEN** 导出 xlsx
- **THEN** 商品表仍包含「分类」列
