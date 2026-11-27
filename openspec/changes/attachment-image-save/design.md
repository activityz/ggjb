# 设计：商品图片保存到本地

## 依据

用户在选项卡里选定：**弹系统「另存为」由用户自己选位置**。另外两种（固定目录 / 手机相册直存）已否，理由见文末。

## 关键决策

### D1 用 `file_picker` 的 `saveFile(bytes:, fileName:)`，不新增依赖

项目已有 `file_picker 11.0.3`（导入 Excel 就在用）。包里对 `saveFile` 的说明原文：

> For mobile, this function will save a file with the given `fileName` and `bytes` and return the path where the file was saved.
> For desktop platforms, this function opens a dialog to let the user choose a location for the file and returns the selected path. **If the bytes are provided, then the bytes are written to a file at the chosen path.**

Android 侧实现也核过：`FilePickerDelegate.saveFile(uri)` → `FileUtils.writeBytesData(...)`，走 SAF 的 `ACTION_CREATE_DOCUMENT`，**不需要存储权限**。Windows 侧支持 `lockParentWindow`（模态挂在应用窗口上）。

结论：一次调用在两端都完成「挑位置 + 写盘」，不用自己 `File.write`，也不用加权限、加依赖。

### D2 抽 `ImageSaver`，把「选位置 + 写盘」注入进去

`FilePicker.saveFile` 是静态方法，widget 测试里无法拦。所以定义：

```dart
typedef SaveBytes = Future<String?> Function({
  required String fileName,
  required Uint8List bytes,
});
```

`ImageSaver` 持有这个函数（生产环境默认包一层 `FilePicker.saveFile`，测试注入假实现），暴露一个方法返回 `SaveOutcome`：

- `SaveOutcome.saved(path)` —— 成功，带最终路径
- `SaveOutcome.cancelled()` —— 用户取消（`saveFile` 返回 null）
- `SaveOutcome.failed(message)` —— 抛异常（目标不可写、路径被占用等）

页面只根据 outcome 决定提示什么，不自己 try/catch。

### D3 保存的是原图字节

`itemRepository.fullImage(id)` 返回 `bytes` 列。**不用 `thumb`** —— 存下来的是给买家看/自己归档的图，缩略图（长边 256）没有意义。

### D4 文件名

`ggjb-<商品名前 10 字>-<yyyyMMdd-HHmmss>.<ext>`

- 商品名先剔除 `/\:*?"<>|` 与控制字符，再压掉连续空白、去首尾空格，截前 10 个字符；结果为空则用「图片」
- 时间戳取本地时间，精确到秒（同一张图连点两次也不会互相覆盖）
- 扩展名：`image/jpeg`、`image/jpg` → `jpg`；其余（含 `image/png`、未知）→ `png`

### D5 入口只放在大图弹窗

大图右上角并列「保存」「关闭」两个按钮。

**不放到图片格子的长按上**：那个手势现在是「删除图片」，改成长按菜单会把删除从一步变两步，属于额外的行为变更。想保存就点开大图——和手机上操作图片的习惯一致。

### D6 版本

`1.11.0+14`（新功能，进 minor），`pubspec.yaml` 与 `installer/ggjb.iss` 两处同步。

## 被否掉的方案

| 方案 | 否掉的原因 |
| --- | --- |
| 复用现有「导出 PNG」的分享面板 | 那是「分享」不是「保存」，手机上还要用户自己再存一次；用户明确要的是保存到本地 |
| 固定写进 `data/exports/` 再提示路径 | 手机上这个目录用户基本看不到，等于存了也没法用 |
| 手机直存相册 | 要处理 MediaStore 与 Android 13+ 的 `READ_MEDIA_IMAGES`，权限收益比不过「另存为」的通用性 |
| 长按格子弹菜单（保存 / 删除） | 把删除从一步变两步；本次不改既有手势语义 |
| 自己 `File.write` + 目录选择器 | `saveFile(bytes:)` 已经把两件事都做了，多写一套只为绕开依赖不值得 |

## TDD seam 表

| # | 边界 | 抓住什么 | 漏掉什么 |
| --- | --- | --- | --- |
| S1 | `ImageSaver.save()`（注入假 `SaveBytes`） | 预填文件名规则（`ggjb-` 前缀、10 字截断、非法字符剔除、空名回退「图片」、扩展名跟 mime/时间戳）；传给底层的是**原图字节**；成功时返回 `saved` 且带路径 | 真实系统对话框长什么样 |
| S2 | 同上，假实现返回 `null` | 取消 → `cancelled`，不写文件、不报错 | 用户在真对话框里点取消时的平台差异 |
| S3 | 同上，假实现抛异常 | 失败 → `failed` 且消息可读、不泄漏堆栈 | 真实只读目录的错误码 |
| S4 | 详情页 widget（真库 + 真指针点击） | 大图里有「保存」按钮，点它确实调用了注入的保存器；原图字节为空时按钮不出现 | 真实 Windows 另存为弹窗、真实 Android SAF 面板（只能真机/桌面点验） |

S4 必须用 `tester.tap` 走真实指针事件 —— 本项目踩过「卡上挂了回调但点不动」的坑（`GlassCard` 手势竞技场），直接调回调的测试对这类故障是瞎的。
