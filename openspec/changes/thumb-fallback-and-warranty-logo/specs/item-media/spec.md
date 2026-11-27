# Spec Delta

## ADDED Requirements

### Requirement: 附件缩略图缺失时回退原图

附件视图 SHALL 优先使用缩略图字节；当缩略图缺失（列为 NULL 或空）时，MUST 回退读取原图字节并按缩略图尺寸渲染，在**不改动数据**的前提下把图片显示出来。

#### Scenario: 只有原图、没有缩略图

- **WHEN** 某附件的 `thumb` 为 NULL 而 `bytes` 有内容（如保修卡图片）
- **AND** 用户打开该商品的详情页「图片」模块
- **THEN** 该图按缩略图尺寸正常显示
- **AND** 画面上不出现加载指示器

#### Scenario: 缩略图存在时走缩略图

- **WHEN** 附件同时有 `thumb` 与 `bytes`
- **THEN** 视图使用 `thumb` 渲染
- **AND** 不为这张图读取原图

### Requirement: 附件完全无图时显示「无预览」而不是转圈

当缩略图缺失且原图也为空（`attachments.bytes` 是 NOT NULL 列，故「无原图」在库里表达为零长度 blob）时，附件视图 MUST 显示「无预览」静态占位，MUST NOT 显示旋转的加载指示器。

#### Scenario: 缩略图与原图都为空

- **WHEN** 某附件的 `thumb` 为 NULL 且 `bytes` 为空
- **THEN** 该位置显示「无预览」
- **AND** 不出现加载指示器

### Requirement: 保修卡图片保存时写入缩略图

生成保修卡并入库时，系统 SHALL 同时生成并写入缩略图，使其与其它附件一致；缩略图 MUST 由保修卡 PNG 缩放得到，长边不超过 256 像素。

#### Scenario: 保存后缩略图非空

- **WHEN** 用户为已卖出商品生成保修卡
- **THEN** 该附件行的 `thumb` 不为 NULL
- **AND** 解码后长边不超过 256 像素
