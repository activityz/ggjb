# data-integrity

## ADDED Requirements

### Requirement: 导入表里的新行必须落库

`ExcelImportService.apply` SHALL 把 parse 阶段新分配 id 的行作为新记录插入。`ItemRepository.save` 在收到一个库中不存在的 id 时 SHALL 插入新行，MUST NOT 静默地 update 0 行后仍把该行计入「已写入」。

#### Scenario: 表里只有名称与买入价的新行

- **WHEN** 用户导入一份不含 id 列值的商品行，随后确认写入
- **THEN** 库中多出该商品，且提示的写入条数与库里实际新增条数一致

#### Scenario: 同一份表导入两次

- **WHEN** 同一份文件被连续导入两次
- **THEN** 第二次遇到的 id 已存在，行为是覆盖而不是再插一条重复记录

### Requirement: 缺「名称」列表头必须报列缺失

导入器 SHALL 在表头缺少「名称」列时返回一条指向列缺失的错误，MUST NOT 退化成逐行报「名称不能为空」。

#### Scenario: 表头只有 id 与买入价

- **WHEN** 导入文件表头缺「名称」列
- **THEN** 预览返回的错误里出现「缺少「名称」列」一类的列级错误

### Requirement: 同步增量统计必须区分插入与覆盖

合并报告 SHALL 把本机原本不存在的行计入 inserted，把本机已存在且被远端改写的行计入 replaced。

#### Scenario: 远端独有的一件商品

- **WHEN** 本机没有、远端有的商品被合并进本机
- **THEN** 报告的 itemsInserted 为 1、itemsReplaced 为 0

### Requirement: 无法解码的图片字节必须报可读错误

`ImagePipeline` SHALL 把解码失败（包括过短字节导致的 `RangeError`）统一转成 `ImagePipelineException`，MUST NOT 把底层异常直接抛给调用方。

#### Scenario: 0 字节与 3 字节的输入

- **WHEN** 传入 0 字节或 3 字节的「图片」
- **THEN** 抛出 `ImagePipelineException`，message 含「无法解析」

### Requirement: 删除运营成本后列表与合计立即更新

运营成本页 SHALL 在删除成功后立即让列表、合计与看板汇总反映删除结果，用户 MUST NOT 需要退出页面再进来才能看到变化。

#### Scenario: 删掉唯一一笔

- **WHEN** 用户在运营成本页删除一条记录并确认
- **THEN** 该条从列表消失、合计立即变为 0
