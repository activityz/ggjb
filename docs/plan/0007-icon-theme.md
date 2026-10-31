# 0007 · 应用图标 + 主题设置（亮色默认）

## 执行进度

| 项 | 状态 |
| --- | --- |
| 图标生成脚本 `tools/gen_icon.py` | ✅ 1024 主图 + 透明前景 + 多尺寸 ico + Android 五档 mipmap（含 round） |
| Windows 图标接入 | ✅ 覆盖 `windows/runner/resources/app_icon.ico`，`Runner.rc:55` 引用不变 |
| Android 图标接入 | ✅ mipmap 五档 + `android:roundIcon` |
| `AppPalette` 调色板与双主题 | ✅ `lib/app/palette.dart`，19 个语义字段 |
| `theme.dart` 重写（亮/深真正分支） | ✅ |
| `GlassCard` 亮色实心分支 / 粒子关闭 / shimmer / rolling_number | ✅ |
| 全页面颜色替换为 `context.palette` | ✅ 残留 0 处 |
| 设置页「主题」三选 + 持久化 | ✅ `local_devices.themeMode`，默认 light |
| 回归 | ✅ analyze 0 issue / test 72 项全过 |
| 重新构建双端 | ⏸ 需用户明确确认 |

## 目标

1. 设计并接入应用图标：圆角方形，主色渐变底，手机 + 循环箭头。
2. 支持亮色 / 暗色 / 跟随系统三种主题，**默认亮色**。
3. 亮色下放弃玻璃拟态，改成「实心白卡 + 柔和阴影」，粒子关闭；暗色保留现有玻璃 + 粒子。
4. 主题选择持久化，重启后生效。

## 非目标

- 不换主色（仍是 `#2C6E8F → #5EEAD4` 那一系），只调亮度与材质。
- 不做自定义主题色（让用户自己挑颜色），收益低、要重校全部对比度。
- 不做动态取色（Material You），Windows 端没有这个概念，两端会不一致。
- 不改 `GlassCard` 的调用签名 —— 只改它内部的材质分支，5 个页面不用碰。

## 为什么必须动 theme.dart

现状 `buildAppTheme(Brightness)` **忽略传入的 brightness**，永远返回深色，注释写着「浅色模式也走深色」。同时 5 个页面里直接引用了 78 处硬编码色常量：

| 常量 | 引用处 | 亮色下必须变 |
| --- | --- | --- |
| `kPageGradient` / `kPageTop` / `kPageBottom` | 6 处页面底 | 深灰黑 → 浅灰白 |
| `kTextPrimary` | 12 处正文 | 浅色文字 → 深色文字 |
| `kTextSecondary` | 18 处次级文字 | 亮灰 → 中灰 |
| `kGlassFill` | 10 处卡底 / 骨架屏 / 导航栏 | 6% 白 → 纯白 |
| `kGlassBorderStart` / `kGlassBorderEnd` | 12 处描边 | 白 12% → 黑 8% |
| `kGlassHighlight` | 1 处顶部高光 | 去掉 |
| `0x14FFFFFF` 等字面量 | 8 处分隔线 / 进度条底 | 硬化成 palette 字段 |

这些常量**无法在运行时切换**，必须改成从 `ThemeExtension` 取。

---

## P0 · 应用图标

### 设计规格

| 项 | 值 |
| --- | --- |
| 画布 | 1024 × 1024 PNG，圆角由各平台自己裁（Android 自适应图标、Windows ico） |
| 底色 | 对角渐变 `#2C6E8F`（左上）→ `#5EEAD4`（右下），与 `kAccent` 同源 |
| 主体 | 白色手机轮廓（粗描边、无填充、圆角 96），手机屏内一个 `¥` 的负形 |
| 副元素 | 手机外围一圈顺时针循环箭头（两段弧 + 两个箭头尖），表示「收进来 ↔ 卖出去」 |
| 留白 | 主体占画布 62%，四周留 19%，保证圆形裁切（Android 圆形图标）不切边 |
| 小尺寸适配 | 48px 下只有「手机轮廓 + 循环箭头」能看清，`¥` 允许糊成一团 —— 所以不把 `¥` 当主要识别元素 |

### 落地方式

1. 用项目自带的 Python + Pillow 直接生成源图 `assets/icon/app_icon.png`（1024²），不依赖外部设计稿。
2. 生成 `assets/icon/app_icon_foreground.png`（Android 自适应图标前景，主体缩到 66%，透明底）。
3. 生成 `windows/runner/resources/app_icon.ico`（多尺寸：16/24/32/48/64/128/256），**这是 Windows 任务栏与 exe 的真实图标来源**。
4. 加 `flutter_launcher_icons` 到 dev_dependencies，配置 `android: true` / `ios: false` / `windows: {generate: false}`（Windows 走手写 ico，该包对 Windows 支持不稳定），执行一次生成全部 Android mipmap 密度。
5. `AndroidManifest.xml` 的 `android:icon` 保持引用 `@mipmap/ic_launcher`，另加 `android:roundIcon="@mipmap/ic_launcher_round"`。

### 风险

- `flutter_launcher_icons` 会覆盖 `android/app/src/main/res/mipmap-*` 下全部图标，**不删机器人默认图标之外的文件**（`ic_launcher_background.xml` 等自适应图标资源该包不动，需手工确认）。
- ico 必须是真多尺寸，单尺寸 256 会在任务栏小图标下糊。

---

## P1 · 主题体系（核心改动）

### 1. 新建 `app/lib/app/palette.dart`

```dart
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color pageTop, pageBottom;        // 页面底渐变两端
  final Color cardFill;                   // 卡片底
  final Color cardBorderStart, cardBorderEnd;
  final Color highlight;                  // 卡片顶部高光（亮色下为透明）
  final Color inputFill;                  // 输入框底
  final Color divider;
  final Color textPrimary, textSecondary;
  final bool glass;                       // 是否走玻璃拟态
  final bool particles;                   // 是否铺粒子

  static const AppPalette dark = AppPalette(...);   // 现有值原样搬过来
  static const AppPalette light = AppPalette(...);  // 新增
}

extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
```

亮色取值：

| 字段 | 亮色值 | 理由 |
| --- | --- | --- |
| `pageTop` / `pageBottom` | `#F7F9FB` → `#EDF1F5` | 带一点冷调，纯白会显得廉价 |
| `cardFill` | `#FFFFFF` | 实心白 |
| `cardBorderStart` / `cardBorderEnd` | `#00000014` → `#00000008` | 一层极淡描边代替玻璃边 |
| `highlight` | `Colors.transparent` | 亮色下高光是噪声 |
| `inputFill` | `#F1F4F7` | 比卡底深一档，输入框才有边界 |
| `divider` | `#00000014` | |
| `textPrimary` | `#11161C` | 不用纯黑，纯黑在白底上发硬 |
| `textSecondary` | `#5B6672` | |
| `glass` | `false` | |
| `particles` | `false` | |

### 2. `theme.dart` 改造

- `buildAppTheme(Brightness)` 真正按 brightness 分支，不再忽略参数。
- 暗色：`ColorScheme.dark(...)` + 现有全部值，`extensions: [AppPalette.dark]`。
- 亮色：`ColorScheme.light(...)`，primary 用 `#2C6E8F`（比 `kAccent` 深，浅底上青绿字对比不够），`surface: 白`，`extensions: [AppPalette.light]`。
- 删掉 `kPageGradient` 常量，改成 `LinearGradient pageGradient(AppPalette p)`。
- **`kTextPrimary` / `kTextSecondary` / `kGlassFill` 等常量全部删除**，编译器会强迫每个引用点改掉，不会漏。

### 3. `GlassCard` 材质分支（不改调用签名）

```dart
final p = context.palette;
if (!p.glass) {
  // 亮色：实心白卡 + 柔和阴影，没有模糊、没有光斑
  return DecoratedBox(
    decoration: BoxDecoration(
      color: p.cardFill,
      borderRadius: BorderRadius.circular(widget.radius),
      border: Border.all(color: p.cardBorderStart),
      boxShadow: const [
        BoxShadow(color: Color(0x0A000000), blurRadius: 18, offset: Offset(0, 4)),
      ],
    ),
    child: ...,
  );
}
// 暗色：现有玻璃实现原样保留
```

同理 `GlassPanel`。

### 4. 粒子

`AmbientParticles.build` 首行 `if (!context.palette.particles) return const SizedBox.shrink();`。
`ParticleBurst` **保留**（标记已到账那一下在两个主题下都该有，亮色下粒子色改成主色）。

---

## P2 · 主题设置与持久化

### 存储

`app/lib/data/db/tables.dart` 的 `LocalDevices` 增一列：

```dart
/// 'light' | 'dark' | 'system'，缺省 light
TextColumn get themeMode => text().withDefault(const Constant('light'))();
```

放 `local_devices` 而不放 `sync_states`：主题是**设备本地偏好**，不该跟着同步跑。

`schemaVersion` 2 → 3（与 0005 计划的同步字段合并成**同一次迁移**，避免迁两次）。

### UI

`settings_page.dart` 的「这台设备」卡加一个 `ListTile`：

- 标题「主题」，副标题显示「亮色 / 暗色 / 跟随系统」
- 点击弹三选（`RadioListTile` + 三张预览小卡：白卡 / 黑卡 / 半白半黑）
- 选完写库 → `themeModeProvider` 变化 → `MaterialApp.themeMode` 重建

### 接线

`providers.dart` 加：

```dart
final themeModeProvider = StreamProvider<ThemeMode>((ref) =>
  ref.watch(databaseProvider).select(db.localDevices).watchSingle()
    .map((row) => switch (row.themeMode) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    }));
```

`main.dart` 的 `GgjbApp` 改 `ConsumerWidget`，`themeMode: ref.watch(themeModeProvider).value ?? ThemeMode.light`。

---

## P3 · 逐页面替换色常量

改到编译通过为止（删常量后编译器会逐个指出）。已知落点：

| 文件 | 处数 | 说明 |
| --- | --- | --- |
| `app/lib/features/dashboard/dashboard_page.dart` | 6 | 页面底渐变、`_MetricCard` 文字色、`_GroupRow` 进度条底 |
| `app/lib/features/item_list/item_list_page.dart` | 8 | 页面底、下拉刷新背景色、`_ItemTile` 文字、`_Thumb` 占位色 |
| `app/lib/features/item_detail/item_detail_page.dart` | 3 | 页面底、次级文字、备注文字 |
| `app/lib/features/item_edit/item_edit_page.dart` | 1 | 页面底 |
| `app/lib/features/settings/settings_page.dart` | 1 | 页面底 |
| `app/lib/features/dict/dict_manage_page.dart` | 1 | 页面底 |
| `app/lib/features/home/home_shell.dart` | 2 | 导航栏底（亮色下不该是半透明白） |
| `app/lib/ui/glass_card.dart` | 6 | 材质分支 |
| `app/lib/ui/shimmer.dart` | 5 | 骨架屏块色 |
| `app/lib/ui/rolling_number.dart` | 1 | 默认文字色 |

**注意**：`const TextStyle(color: kTextPrimary)` 改成 `TextStyle(color: context.palette.textPrimary)` 后必须去掉 `const`，否则编译失败。这类改动有 12 处。

---

## 依赖关系

```
P0 图标（独立，可先做完先验）
  ↓
P1 palette + theme 分支（删常量，编译器驱动）
  ↓
P3 逐页面替换（P1 删常量后必须一起做完才能编译）
  ↓
P2 主题设置 UI + 持久化（依赖 P1 的 palette 存在，schema 与 0005 合并迁移）
```

P2 的 schema 改动要与 `0005-rename-sync.md` 的 `sync_states` 四列**合并成一次 `from < 3` 迁移**，不能各迁一次。

## 风险

| 风险 | 处理 |
| --- | --- |
| 删常量后大面积编译错误 | 这是**故意的** —— 留着常量就会漏改，亮色下出现黑底白字。逐个改到 `flutter analyze` 清零 |
| 亮色下金额发光（`GradientText` glow）会变成脏影 | `GradientText` 加 `glow` 参数已经是 0 默认，亮色下调用处传 `glow: 0`；`moneyGradient` 在亮色下改用深一档的色阶 |
| `ColorScheme.light` 的 primary 用 `kAccent`（青绿）对比度不足 | 亮色 primary 改用 `#2C6E8F`，青绿只作为 profit 语义色 |
| `flutter_launcher_icons` 覆盖 res 目录 | 生成后 `git status` 核对，只应改动 mipmap-* 下的 png |
| ico 生成质量 | 用 Pillow 的 `save(format='ICO', sizes=[...])` 一次写多尺寸，16px 单独做像素级简化（箭头从两段弧简化成两道斜线） |

## 验收

1. `flutter analyze` 无 issue，`flutter test` 全过。
2. 首次启动是**亮色**：浅灰渐变底、白卡、无粒子、无玻璃模糊。
3. 设置页切「暗色」→ 立刻变深色玻璃 + 粒子；切「跟随系统」→ 跟随 Windows / Android 系统设置。
4. 杀掉进程重启，主题保持上次选择。
5. Android 桌面图标、Windows 任务栏图标、Windows 标题栏图标都是新图标（不是 Flutter 默认的蓝色）。
6. 亮色下看板、列表、详情、编辑、设置、字典管理 6 个页面无「深色残留」（不该出现深色文字在深底上、或白色卡片配白色文字）。
7. 构建 APK / exe **需用户明确确认后才执行**（m01379）。
