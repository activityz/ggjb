# 任务

> 纪律：按 TDD 排序，每个 seam 先红后绿、一次一个切片。seam 表见 design.md §「TDD seam 表」。

## 1. 骨架

- [x] 1.1 新增 `app/lib/features/item_detail/image_saver.dart`：`SaveBytes` 函数类型、`SaveOutcome`（`saved` / `cancelled` / `failed`）、`ImageSaver`（构造注入 `SaveBytes`，生产默认走 `FilePicker.platform.saveFile(..., bytes:, fileName:)`）
- [x] 1.2 `ImageSaver.save()` 内部实现文件名规则：`ggjb-<前 10 字>-<yyyyMMdd-HHmmss>.<ext>`，剔除 `/\:*?"<>|` 与控制字符，空名回退「图片」，扩展名按 mime
- [x] 1.3 `app/lib/app/providers.dart` 增加 `imageSaverProvider`（默认实现），供页面与测试覆盖

## 2. 测试先行（红灯）

- [x] 2.1 S1 `app/test/features/item_detail/image_saver_test.dart`：合法标题 → 文件名前缀/时间戳/扩展名正确，且传给底层的字节等于原图字节；返回 `saved`
- [x] 2.2 S1 续：标题含 `A/B:C*?` → 文件名无非法字符；标题为空 → 用「图片」
- [x] 2.3 S1 续：mime 为 `image/jpeg` → `.jpg`；`image/png` 与未知 → `.png`
- [x] 2.4 S2：假 `SaveBytes` 返回 `null` → `cancelled`，且没有写盘动作
- [x] 2.5 S3：假 `SaveBytes` 抛异常 → `failed`，消息不含堆栈原文
- [x] 2.6 S4 `app/test/features/item_detail/image_save_entry_test.dart`：真库 + 真指针点击，大图里点「保存」→ 注入的保存器被调用一次；原图字节为零长度时没有「保存」按钮

## 3. 实现

- [x] 3.1 `_viewImage` 的大图弹窗右上角加「保存」按钮（与「关闭」并列），点击后调用 `ImageSaver` 并按 `SaveOutcome` 给提示
- [x] 3.2 原图字节为空时不显示「保存」按钮（大图位置保留「无预览」）
- [x] 3.3 提示文案：`saved` → 「已保存」（桌面附路径）、`cancelled` → 不提示、`failed` → 「保存失败」

## 4. 验证

- [x] 4.1 `flutter test` → `+453: All tests passed!`（基线 446 + 新增 7）
- [x] 4.2 `flutter analyze` → `No issues found!`
- [x] 4.3 `openspec validate attachment-image-save --strict` 通过
- [ ] 4.4 手工核对（待用户）：Windows 上点保存能弹另存为并把图存到所选位置；手机上弹系统文件保存面板，存完能在文件管理里看到

## 5. 收尾

- [x] 5.1 版本号升到 `1.11.0+14`（`app/pubspec.yaml` 与 `installer/ggjb.iss` 两处）
- [x] 5.2 `README.md` 版本历史补一条
- [ ] 5.3 出包（等用户开口）：`ggjb-1.11.0-release.apk` / `ggjb-1.11.0-windows-setup.exe` / `ggjb-1.11.0-windows-x64.zip`
