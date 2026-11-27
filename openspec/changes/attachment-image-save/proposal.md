# 提案：商品图片可保存到本地

## 为什么（Why）

详情页的图片只能看：点开是 `InteractiveViewer` 大图弹窗，除了关闭没有别的动作。用户要把商品图（买入截图、序列号铭牌、保修卡）另存到本机发给买家或自己归档时，只能靠截图。

## 改什么（What Changes）

- 图片大图弹窗右上角新增「保存」按钮：点它调起系统「另存为」，把**原图字节**写到用户选的位置。
- 新增 `ImageSaver`（可注入的保存器）+ `SaveOutcome`（`saved` / `cancelled` / `failed`），把「挑位置 + 写盘 + 结果提示」从页面里抽出来，便于单测。
- 文件名规则：`ggjb-<商品名前 10 字>-<yyyyMMdd-HHmmss>.<扩展名>`；商品名剔除路径分隔符与 Windows 保留字符，为空时用「图片」；扩展名跟附件 `mime` 走（`image/png` → `png`、`image/jpeg` → `jpg`，其它 → `png`）。
- 保存结果用一句话提示：成功给「已保存」＋路径（桌面）/ 只说「已保存」（手机路径不可读）；取消静默；失败说「保存失败」。

## Capabilities

- **New**：`item-media` —— 附件图片的保存（保存入口、原图字节、文件名规则、结果提示）

> 注：`item-media` 的基线目前还在未归档的 `thumb-fallback-and-warranty-logo` change 里，不在 `openspec/specs/`，故本 change 以 ADDED 增量给出；归档时并入同一份 spec。

## Impact

- 代码：`app/lib/features/item_detail/item_detail_page.dart`（大图弹窗加按钮）、新增 `app/lib/features/item_detail/image_saver.dart`、`app/lib/app/providers.dart`（注入保存器）
- 依赖：**不新增**。用项目已有的 `file_picker 11.0.3`：它的 `saveFile(bytes:, fileName:)` 在 Android 走系统文件保存面板（SAF `ACTION_CREATE_DOCUMENT`）、在 Windows 走原生另存为对话框，两者都由包自己把字节写盘；不需要存储权限。
- 数据库：不改表、不升 `schemaVersion`
- 同步：无协议变更

## 非目标

- 不做批量保存 / 「全部导出」（先做单张，稳了再说）
- 不做手机相册直存（要额外处理 MediaStore 与 Android 13+ 权限，收益不如另存为直接）
- 不改现有「导出 PNG」（保修卡、二维码）的分享面板行为
- **不动图片格子的长按**：它现在是「删除图片」，改成长按菜单会把删除从一步变两步
- 不做图片压缩、转格式、重命名已有附件
