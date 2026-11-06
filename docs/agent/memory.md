# 项目记忆（ggjb / 二手账本）

> 只记「下次一定还会用到」的东西。一次性操作细节、进度流水不放这里。
> 架构层面的完整决策见 [0001-architecture.md](../design/0001-architecture.md)。

## 1. 定位

个人自用的二手交易记账程序。Windows + Android 双端，**数据完全本地**（SQLite），
不上云、不注册账号。核心问题：这件赚了多少、总共赚了多少。

## 2. 版本锁（改了要先想清楚）

- Flutter **3.47.1**（`D:\develop\flutter\fvm\versions\3.47.1`），Dart 3.13。
  机器 PATH 上的 3.35.4 太旧，`pub get` 解算不过 —— 必须用绝对路径调 3.47.1 的 flutter/dart。
- flutter_riverpod **3.x**（不是 2.x）：`AsyncValue` 没有 `valueOrNull`，用 `.value`。
- drift 2.31 + drift_dev 2.31；`file_picker` 11.0.3 的 `pickFiles` 是**静态方法**，没有 `.platform`。
- Gradle wrapper 用 **8.14**（Flutter 3.47 要求 ≥ 8.14.0）；**AGP 必须是 8.11.1 或更高**
  （Flutter 3.47 的最低要求是 AGP 8.11.1，模板生成的 8.9.1 会直接失败）；
  **Kotlin（KGP）必须是 2.2.20 或更高**（模板生成的 2.1.0 同样会直接失败）。
  这三条都在 `app/android/settings.gradle.kts` + `gradle/wrapper/gradle-wrapper.properties` 里。
  `distributionUrl` 指向 `gradle-8.14-all.zip`。
  本机已有完整发行包：`dists\gradle-8.14-all\8mguqc37c200i71ledpgw8n5m\`（`gradle-8.14/` + 224MB zip + `.ok`），
  但 wrapper 按 URL 的 MD5 算出的是 `c2qonpi39x1mddn7hk5gh9iqj`，两者不通用 —— 处理办法见第 4 节。
- `GRADLE_USER_HOME` = `D:\develop\AndroidSdk\.gradle`（**不是** `~/.gradle`，查缓存别找错地方）。

### Android 依赖版本硬门槛（权威来源）

写在 `D:\develop\flutter\fvm\versions\3.47.1\packages\flutter_tools\gradle\src\main\kotlin\DependencyVersionChecker.kt:94-117`，
不要靠猜：

| 依赖 | error（低于就 BUILD FAILED） | warn（只警告） |
| --- | --- | --- |
| Gradle | < 8.14.0 | < 9.1.0 |
| AGP | < 8.11.1 | < 9.0.1 |
| Kotlin (KGP) | < 2.2.20 | < 2.3.20 |
| Java | < 17 | — |
| minSdk | < 23 | < 24 |

低于 error 会直接中断，`--android-skip-build-dependency-validation` 可跳过校验（不推荐，等于跳过保护）。
本机现状：Gradle 8.14 / AGP 8.11.1 / Kotlin 2.2.20 / JDK 21 —— error 级全部通过，只剩 warn 级提示。

## 3. 环境约束
- **NDK 固定为 `27.0.12077973`**（写在 `app/android/app/build.gradle.kts`）。Flutter 3.47 默认要
  `28.2.13676358`，本机只装了 27，而 Gradle 的自动安装在新版 `android` CLI 下已经失效
  （`Package ndk not found` / `Package 28.2.13676358 not found`）。本项目没有 native 源码，
  NDK 不参与编译，固定成已装版本即可。
- **Visual Studio 已装**：Community 2026 18.11.3，路径 `D:\app\Microsoft Visual Studio\18\Community`，
  Windows 10 SDK 10.0.26100.0。`flutter build windows --release` 可正常出包（首次 588.8 秒），
  产物在 `app/build/windows/x64/runner/Release/`（16 个文件 / 32 MB），
  发布用 `dist/ggjb-1.0.0-windows-x64.zip`（13.5 MB）。**Windows 产物是文件夹不是单文件**，
  分发时必须整目录打包，只给 exe 会闪退。
- **PATH 上的 `flutter` / `dart` 是 3.35.4，不是当前 SDK 3.47.1**。所有脚本必须写死
  `D:\develop\flutter\fvm\versions\3.47.1\bin\flutter.bat`，否则手敲 `flutter build` 会跑到旧版本。
- 直连 `google()` / `mavenCentral()` 会长时间卡住，`app/android/settings.gradle.kts` 与
  `app/android/build.gradle.kts` 里已加阿里云镜像（用 `maven { url = uri(...) }` 写法，Kotlin DSL）。
- Flutter 走 `https://storage.flutter-io.cn` 镜像；github.com 连接超时。

## 4. 踩过的坑（重复踩第二次就是浪费）

- **g.dart 是 part 文件，继承 owner library 的 import**：`app_database.dart` 必须显式
  `import '../../domain/enums.dart';`，否则生成代码里所有 TypeConverter 都报 undefined。
- drift 的 `TypedResult.read()` 读带 TypeConverter 的列会报类型不匹配，必须
  `row.readWithConverter(_db.attachments.role)`。
- 合并外部快照期间必须 `PRAGMA foreign_keys = OFF`，**且在事务外设置**，否则 `DELETE FROM items`
  会级联删掉本地较新的 expenses。
- `flutter create` 用旧 Flutter 生成的工程模板 Gradle 版本偏低，换 Flutter 版本后要手动抬 wrapper。
- PowerShell 里 `flutter ... | Out-String | Out-File` 是**命令结束才落盘**，构建期间的日志看不到进度，
  不要据此判断「没在跑」。
- **Gradle wrapper 发行包会被并发构建抢锁**：报错原文 `Timeout of 120000 reached waiting for exclusive
  access to file: ...\gradle-8.14-all.zip`。根因是多个 `flutter build` 同时跑（曾同时存在 11 个 java 进程）。
  处理顺序：①`Stop-Process -Name java,dart,dartaotruntime -Force` 清干净，**保证只有一次构建在跑**；
  ②若本地已有解压好的发行包而 hash 目录对不上，用
  `cmd /c mklink /J "<hash目录>\gradle-8.14" "<已有目录>\gradle-8.14"` 做目录联接，再在 hash 目录里建空的
  `gradle-8.14-all.zip.ok`，wrapper 就认为已就绪、不再联网下载。

## 5. 纪律

- **构建必须经用户确认**：`flutter build apk` / `flutter build windows` 这类产出安装包的命令
  **不要自动执行**，等用户明确说「构建」再跑。`build_runner` 生成代码、`analyze`、`test`
  属于本地校验，可以先跑，但要在汇报里说明跑过哪些命令。
- 算钱只允许在 `lib/domain/profit.dart`。DAO、页面、聚合都转成 `ProfitLine` 再交给
  `ProfitCalculator`，不准另写一套口径（`StatDao` 就是这么做的）。
- 金额一律整数「分」（`*_cents`），禁止浮点。
- 主键 UUID v4 文本；所有表带 `created_at/updated_at/deleted_at/device_id`，删除是软删除。

## 6. 终端操作经验

- pty 在 PowerShell 下逐字符重绘，长命令会乱码/截断。**写 .ps1 脚本 + 只发短命令**，
  脚本内把输出 `| Out-String | Out-File -Encoding utf8` 到日志，再用 read 工具读日志。
- `Out-File` 不加 `-Encoding utf8/ascii` 会写 UTF-16，被 read 当二进制。
- 脚本里 `Set-Location` 会改 cwd，下次调用前要 `cd` 回工作区根，或直接用绝对路径。
- **analyze / build 正在跑时改文件会报 `ReplaceFileW EIO (Win32 1175)`**（文件被占用）。
  等那一轮跑完再写，不要以为是权限问题。

## 7. 字典体系

- 8 类 kind：`brand` / `model` / `storage` / `color` / `category` / `source` / `platform` / `condition`，
  常量集中在 `lib/domain/dict_seeds.dart`（`DictSeeds.kindXxx`），页面里不要硬编码字符串。
- 内置项用**确定性 id**：扁平类 `seed|kind|label`，机型 `seed|model|品牌|机型`。
  这样两端首次启动各自 seeding 出来的 id 完全一致，同步时不会产生重复项。
- **字典只改选项池，不回写商品**。`item.brand` 等列存的是选中瞬间的文本快照，
  字典改名/删除都不影响历史单子 —— 同步时也不会一端改字典、另一端历史数据被改写。
- 机型靠 `parent_id` 挂品牌。但编辑页手里只有品牌**文本**（商品表存快照，没有字典 id），
  所以 `DictDao` 必须提供 `watchKindUnderLabel(kind, parentKind, parentLabel)` 按 label 反查父 id，
  新增子项时用 `idOfLabel` 把文本换成真 id。
- 编辑页切换品牌要清空已选型号，否则会出现「Apple 品牌 + 小米机型」。
  `TextEditingController` 手输每敲一个字都触发 listener，**必须用 `_lastBrand` 比对**再 clear，
  否则用户打第一个字母型号就被清掉。

## 8. 视觉体系（0004）

- **只有深色一套皮肤**。`buildAppTheme` 忽略 `Brightness` 参数，浅色模式也返回深色主题。
  理由：玻璃 + 发光这套语言只在深底成立，硬做浅色皮肤每张卡的对比度都要重校，收益为负。
- 色板常量全在 `lib/app/theme.dart`，页面里**不许写 `Color(0x...)` 字面量**：
  `kPageTop` / `kPageBottom` / `kGlassFill` / `kGlassBorderStart` / `kGlassBorderEnd` /
  `kGlassHighlight` / `kAccent` / `kProfitColor` / `kLossColor` / `kReceivableColor` /
  `kWarningColor` / `kTextPrimary` / `kTextSecondary` / `kPageGradient`。
- **所有金额文字必须带 `fontFeatures: kTabularFigures`**（等宽数字）。
  不带的后果：`RollingNumber` 滚动时每帧字宽不同，整行数字左右抖动。
- 四个 UI 积木在 `lib/ui/`：
  `GlassCard`（模糊 + 渐变描边 + 顶部高光 + 触摸光斑）、`GlassPanel`（不模糊，模糊层数已满时替身）、
  `TapScale`（0.96 弹性缩放 + 轻触震动）、`GradientText`（渐变 + 模糊垫底发光）、
  `RollingNumber`（逐位独立滚动，非数字字符静态）、
  `AmbientParticles` / `ParticleBurst`（连线粒子 / 爆发 + 外环冲击波）。
- 粒子**只在看板铺**。每页都铺等于没有重点，而且 `IndexedStack` 里非当前页仍在 build。
- `_Parallax` 取 `PrimaryScrollController.maybeOf(context)`，**必须在 `addPostFrameCallback` 里取**，
  且要有 `AnimationController(duration: Duration.zero)` 兜底 —— 页面没挂 ListView 时 controller 为 null。
- 卡片错峰入场用 `_stagger(child, index)`，延迟 `index * 60ms`。
  **只给卡片，section 标题不加**：标题也浮起来会让整页像在「加载」。
- 转场走 `FadeSlidePageTransitionsBuilder`（`theme.dart`），淡入 + 3% 上滑，不做缩放。
  深底上缩放会看到边缘发虚。
- 加载态一律用 `lib/ui/shimmer.dart` 的骨架屏（`ItemListSkeleton` / `DashboardSkeleton`），
  **不用 `CircularProgressIndicator`**。骨架形状要和真实卡片对齐，否则加载完会「跳一下」。
- 爆发粒子只在两处触发：详情页标记「已到账」（`_fireBurst`，1.5 秒后打掉 `_celebrate`）、
  列表下拉刷新（`_onRefresh`，900ms）。别到处加，加多了就成了烟花。

### 把 `body:` 改成 `Stack` 时最容易错的地方

原 `body: DecoratedBox(child: Column(children: [...]))` 换成
`body: Stack(children: [Positioned.fill(DecoratedBox(child: Column(children: [...]))), ...])`，
闭合顺序必须是：

```
],      // Column 的 children
),      // Column
),      // DecoratedBox
),      // Positioned.fill
if (x) ...,
],      // Stack 的 children
),      // Stack（这一行同时是 Scaffold 的参数分隔逗号）
);      // Scaffold
```

少一层就报 `Expected to find ']'`，多一层就报 `Expected to find ';'` + `dead_code`。
已经在这上面连错三轮，改之前先数括号。

## 9. 数据交换层（0006 Excel）

- 表头与枚举映射**只有一份**：`lib/data/exchange/excel_rows.dart` 的 `ExcelSchema`。
  导入、导出都从这里取，改一边另一边自动跟上 —— 否则导出的文件自己都导不回来。
- **定位列一律按表头名，绝不按列号**。用户会在 Excel 里插列、删列、换顺序，
  列号全错而表头名还稳；读不到的表头填 `-1`，取值时返回空串。
- **盈亏四列（费用合计 / 总投入 / 毛利 / 毛利率）是只读列**。导出时从
  `domain/profit.dart` 的 `ProfitLine` 取算好的值写死，导入时**直接忽略用户改的值**。
  一旦采纳用户手改的数，就会出现「表里写赚 500、App 里算出来赚 300」两套账。
- 校验是**全或无**：`ExcelPreview.parse` 一次性收集所有 `ExcelRowError`，
  `apply` 开头 `if (!preview.ok) throw`。宁可整批不导，也不留半批脏数据。
- 空值写 Excel 用 `null` 不用空串 —— 空串在 Excel 里算「有值」，
  导回来会被当成用户手填的空字符串。
- 金额写 `DoubleCellValue(cents / 100)`，让用户能在 Excel 里直接求和；
  毛利率写百分数数值（`rate * 100`，两位小数），不写 Excel 公式。
- 日期统一 `yyyy-MM-dd`（`ExcelSchema.datePattern`）；导入额外认 `/` 和 `.`，
  先 `replaceAll` 归一再 `DateFormat.parse`。
- **`excel` 依赖 `archive ^3.x`，与 `archive ^4.x` 不共存**，所以 `image` 被钉在 `^4.3.0`。
  别再升 `image` 到 4.4+，否则 pub 解算直接失败。`lib/` 里没有任何地方 import `archive`。
- Excel 与 `.db` 快照是两条独立的路，各有各的 busy 标志
  （`_excelExporting` / `_excelImporting`），不要共用一个 `_exporting`，
  否则导出 Excel 时「导入并合并」也被灰掉。

## 10. 主题体系与图标（0007）

- `lib/app/palette.dart` 的 `AppPalette extends ThemeExtension<AppPalette>` 是**唯一色源**。
  页面里不许写颜色字面量，统一 `context.palette.xxx`（`extension PaletteX`）。
- 亮色不是简单反色，三条硬规则：
  1. `glass: false` → `GlassCard` 走实心分支，**不做 `BackdropFilter`**（白底模糊只会糊成灰）；
  2. `particles: false` → `AmbientParticles.build` 首行 `SizedBox.shrink()`；
  3. **语义色压深一档**（profit `#0F7B4D` / loss `#C0392B`），`#34D399` 在白底对比度只有 1.9。
- `const TextStyle(color: context.palette.x)` 是非法 const，改色时必须**连外层 `const Text(...)` 一起去 const**。
- `moneyColor(int, AppPalette)` / `moneyGradient(int, AppPalette)` 第二参是 `AppPalette` 不是 `ColorScheme`；
  `moneyGradient` 只能定义在 `lib/ui/gradient_text.dart` 一处，别处再定义会 `ambiguous_import`。
- 图标由 `tools/gen_icon.py`（Pillow）生成：1024 主图 + 透明前景 + 多尺寸 `.ico` + Android 五档 mipmap。
  改设计只改脚本再重跑，不要手改 png。

## 11. 同步持久化（0005）

- `SyncStates` 是对端登记表；配对成功就 `insertOnConflictUpdate` 一条。
- **令牌双向持久化**：`client.pair()` 存对方 token，`hostServer.start()` 把库里所有 `peerToken` 载入 `_tokens`。
  少做一样，「下次自动同步」永远 401 —— 这是重启后失联最常见的原因。
- 探活超时固定 **3 秒**（`SyncClient.probeTimeout`）。自动同步必须**静默**，只有
  `versionMismatch` / `tokenExpired` 才提示；每次都弹就成噪音。
- 版本校验放 `SyncClient.sync()` 最前面，比对 `/v1/info` 的 `schema_version` 与本机 `schemaVersion`，
  别等 `_verifySchema` 报「列数不一致」让用户摸不着头脑。
- `_pickPeer()` 里不要用 drift 的 `&`：文件只 `import ... show Value` 时拿不到 `Expression<bool>` 的 `&`。
  设备最多两台，取全表在 Dart 侧 `.where()` 过滤即可。

## 12. 构建命令

- **`flutter build apk` / `flutter build windows` 必须先问用户**（m01379），不要自动跑。
- 脚本里别加 `--no-pub`：改过 `pubspec.yaml` 的 version 后，`--no-pub` 会因缓存不一致报错。
- PATH 上的 `flutter` / `dart` 是 3.35.4，脚本一律写死 `D:\develop\flutter\fvm\versions\3.47.1\bin\flutter.bat`。

## 10. 主题体系（0007）

- **两套主题，默认亮色**（用户要求）。`LocalDevices.themeMode` 存 `light`/`dark`/`system`，
  **放本地表不放 `sync_states`** —— 电脑深色、手机亮色是常态，主题不该被同步冲掉。
- 所有颜色集中在 `lib/app/palette.dart` 的 `AppPalette extends ThemeExtension<AppPalette>`。
  **页面里不许再写颜色字面量，也不许用 `theme.dart` 里残留的 `kAccent` / `kProfitColor`
  这批旧常量**（留着只为不破坏历史引用，注释已写明「不要在页面里用」）。
  取色统一 `context.palette.xxx`（`extension PaletteX on BuildContext`）。
- 亮色不是简单反色，三条硬规则：
  1. `glass: false` → `GlassCard` 走实心分支（`p.cardFill` + `p.cardBorderStart` + `p.cardShadow`），
     **不做 `BackdropFilter`**。白底模糊只会糊成灰。
  2. `particles: false` → `AmbientParticles.build` 首行直接 `SizedBox.shrink()`。
     浅底上的白点等于没有。
  3. **语义色压深一档**：profit `#0F7B4D` / loss `#C0392B` / receivable `#A16207` /
     warning `#B45309`。原来的 `#34D399` 在白底对比度只有 1.9，看不清。
     亮色 primary 也从 `#5EEAD4` 换成 `#2C6E8F`（青绿在浅底对比不够）。
- `const TextStyle(color: context.palette.x)` 是非法 const —— 改色时必须**顺手去掉外层 `const`**，
  连 `const Text(...)`、`const Positioned.fill(...)` 这种包了一层的也要去。本轮共 12 处。
- `moneyColor(int, AppPalette)` / `moneyGradient(int, AppPalette)` 签名第二参是 `AppPalette`，
  **不是 `ColorScheme`**。`moneyGradient` 只能定义在 `lib/ui/gradient_text.dart` 一处，
  `theme.dart` 里再定义一个会报 `ambiguous_import`。
- 图标由 `tools/gen_icon.py` 生成（Pillow）：1024 主图 + 透明前景 + 多尺寸 `.ico`
  （16/24/32/48/64/128/256）+ Android 五档 mipmap 与 `ic_launcher_round`（圆形裁切）。
  改设计只改脚本参数再重跑，不要手改 png。

## 11. 同步持久化（0005）

- `SyncStates` 是「对端登记表」：`peerId/peerName/peerToken/peerHost/peerPort/
  lastPullAt/lastPushAt/lastSyncAt/pairedAt/autoSync`。配对成功就 `insertOnConflictUpdate` 落一条。
- **令牌双向都要持久化**：`client.pair()` 成功后存对方给的 token；
  `hostServer.start()` 要把库里所有 `peerToken` 载入 `_tokens`。
  少做一样，「下次自动同步」就永远 401 —— 这是重启后失联的最常见原因。
- `AutoSyncService.tryOnce()` 的探活超时固定 **3 秒**（`SyncClient.probeTimeout`）。
  同一局域网里 3 秒连不上就是连不上，不能让启动流程干等。
- **自动同步必须静默**：没配对 / 不在同一网段都是正常情况，只有
  `versionMismatch` 和 `tokenExpired` 才 `shouldNotify = true` 弹提示。
  每次都弹就变成噪音，用户会直接无视所有提示。
- 版本校验放在 `SyncClient.sync()` 最前面（pull 之前），比对 `/v1/info` 的
  `schema_version` 与本机 `_db.schemaVersion`。不一致直接抛，别等 `_verifySchema` 报一句
  「列数不一致」让用户摸不着头脑。
- `_pickPeer()` 里**不要用 drift 的 `&` 复合表达式**：文件只 `import ... show Value` 时
  拿不到 `Expression<bool>` 的 `&` 运算符；完整 import 又会和业务类型撞名。
  设备最多两台，取全表在 Dart 侧 `.where()` 过滤，代价可以忽略。





## 12. 同步调度器（SyncController）

- 触发有三条，缺一条用户就会觉得「没同步」：
  1. `attach()` 里同步一次 —— 打开就追平；
  2. `db.tableUpdates(...)` 监听 `items`/`expenses`/`attachments`/`dictEntries`，
     任何写入后防抖 1.2 秒同步 —— 「改完价格另一台马上看到」全靠这条；
  3. `Timer.periodic(25s)` 兜底 —— 万一某次写入没被监听到，最多 25 秒也会补上。
- 监听表**必须排除 `syncStates`**：它记的是同步自己的时间戳，算进来等于自己
  触发自己，会无限循环。
- 同步结束设 `_quietUntil = now + 2s`，这段时间内的表更新一律忽略。否则
  A 推 B → B merge 写库 → B 推 A → A merge 写库，两台机器来回空转。
- **两端都要监听 8787**（且只在「已配对过」时才开，全新安装不占端口、不弹防火墙）。
  只让一端主动连的话，先开机那台试过一次失败就再也不试了，后开机的永远追不上。
- 同步按钮放 `home_shell` 的全局 AppBar，不放某一页 —— 同步是全局的事，
  在哪一页改完都该能立刻点，而不是先切回看板。
- 页面自己的 `Scaffold.appBar` 必须删掉，否则会出现「两个顶栏」。

## 13. Android 发布签名

- keystore：`app/android/ggjb-release.jks`（JKS，RSA 2048，validity 10000 天，alias `ggjb`）。
  密码与路径在 `app/android/key.properties`。**两者都已在 `.gitignore` 里，绝不入库、绝不外发。**
- 证书指纹（用来核对「这个包是不是我签的」）：
  `CN=ggjb, OU=personal, O=personal, L=Beijing, ST=Beijing, C=CN`
  SHA-256 `5e29936bfd646bf0585d0cd72aa0e69e21b26ddd24141a12b8e6b2c868a91e2a`
  核对命令：`apksigner verify --print-certs app-release.apk`
  （apksigner 在 `D:\develop\AndroidSdk\build-tools\<版本>\apksigner.bat`）
- `app/android/app/build.gradle.kts` 的逻辑是「有 `key.properties` 用 release，
  没有就退回 debug」—— 这样别人克隆仓库也能 `flutter run --release`。
- **这个签名一旦发出去就不能换**。换签名 = 老用户无法覆盖升级 = 必须卸载重装，
  而卸载会连 `/Android/data/me.local.ggjb/` 一起删，账全没。
  所以 `.jks` 和密码要单独备份（网盘 / 密码管理器），丢了等于丢掉所有已安装用户。
- 1.5.1 之前的包是 debug 签名（Android SDK 自带 debug.keystore）。
  **这条线之后升级到你自己的手机也要先导出备份、卸载重装**，不能直接覆盖。

## 15. 蓝牙标签打印（1.8.0）

- **没有引 pub 包，走自写的 Android MethodChannel**。`bluetooth_print` / `permission_handler`
  在 `pub.flutter-io.cn` 镜像里都不存在；切到 `https://pub.dev` 解算后，`pubspec.lock` 会有
  **247 处 url 变成 pub.dev、61 处版本条目变动**。为了一个传输层把整个项目依赖源迁走不划算。
- 通道名 `ggjb/printer`，实现在 `app/android/app/src/main/kotlin/me/local/ggjb/MainActivity.kt`：
  `scan`（扫 10 秒 + 已配对设备）/ `connect` / `disconnect` / `isConnected` / `write`。
- 三条实现细节别改错：① 蓝牙操作全在单线程 executor 上跑，结果 `runOnUiThread` 回给 Flutter；
  ② `connect` 前必须 `cancelDiscovery()`，否则系统直接拒绝建链；③ 同一时刻只留一个 socket。
- TSPL 布局（40×30mm、203dpi、320×240 dots）：`SIZE 40 mm, 30 mm` / `GAP 2 mm, 0 mm` /
  `QRCODE 73,8,L,6,A,0,M2,S7,"<id>"`（cell 6 dots → 29 模块 174 dots ≈ 21.75mm）/
  `TEXT 8,190,"TSS24.BF2"` 标题 / `TEXT 8,214,"TSS16.BF2"` 明文 / `PRINT 1,1`。
  标题按 runes 截到 16 字，按 `substring` 切会把 emoji 切半个。
- 中文标题按 UTF-8 发；若真机打出来是乱码，说明该机型字库按 GBK 解释，改 `label_commands.dart`
  的编码即可（标题只是给人核对的，二维码与明文才是关键）。
- **打印机地址不落库**：`local_devices` 加列会升 `schemaVersion`（6→7），同步前版本比对
  会拦住旧对端。打印是低频动作，重启重连一次比一次库迁移便宜。
- 指令集按 TSPL 实现；若现场机型是 CPCL / ESC-POS，只改 `buildLabelCommands` 一个函数。

## 14. 二维码与扫码（1.7.0）

- **现场标签纸 40×30mm**（热敏打印头 50mm 宽，本次只用 40mm 宽）。
- 码值 = `items.id` 原文，**不建 code 列**：QR 装得下 36 字符 UUID，所以库结构仍是 v6，
  同步 `_verifySchema` 不受影响，不需要两端同升。Code-128 编 UUID 要 431 个模块，
  40mm 纸根本印不出来——这是改用二维码的直接原因。
- QR 尺寸：version 3（29×29 模块）+ 四边静区 4 模块 = 37 模块；按 5 点/模块（0.625mm）
  约 23.1mm，40×30mm 够用。容错 M（15%）足够；H 会升到 version 5，把 30mm 高度顶满。
- **二维码必须白底黑码**：弹窗里固定 `Colors.white`，不跟深色主题——反色后扫码器读不出来。
- `mobile_scanner` 7.5.0 的插件平台只有 android/ios/macos/web，**没有 Windows**。扫码入口
  用 `scanAvailableProvider`（`!kIsWeb && defaultTargetPlatform == android`）判定；
  widget 测试里 `debugDefaultTargetPlatformOverride` 默认就是 android，断言「桌面无入口」
  必须显式设成 `TargetPlatform.windows`，否则测出来永远是 true。
- 相机在测试里不可用：取景抽成 `scanLauncherProvider`（返回 `Future<String?>`），测试
  override 成直接返回码值；`ScanPage` 只做「扫到就 pop 原始字符串」。
- `QrImageView` 的 `data` 是私有字段，测试只能断言 `backgroundColor` / `errorCorrectionLevel`
  与明文文本；「图形里编的是不是主键」只能真机打一张扫一下。

## 16. Windows 蓝牙打印（1.9.0）

- **纯 Dart FFI，不写 C++ 插件**：C++ 插件要改 CMake 与 flutter_window.cpp，每次改动全量重编；
  而这些 API 都是普通 Win32 导出函数，`win32` 包已绑定好。
- **`ws2_32` 不在 `package:win32/win32.dart` 里**，要从 `package:win32/winsock2.dart` 单独导；
  `socket` / `connect` / `send` / `closesocket` 都在那里，导出错了会报 undefined_method。
- **类里别定义与全局 FFI 函数同名的方法**：`WindowsPrinterChannel.connect` 会把全局 `connect`
  遮蔽掉，编译期报「Future<void> 不能当 int 用」。解法是顶层包一个 `_wsConnect`。
- `BTHPROTO_RFCOMM = 0x0003` win32 没导出，自己定义；`AF_BTH` / `SOCK_STREAM` 有。
- **`WSAStartup` 与 `WSAGetLastError` win32 也没导出**，用 `DynamicLibrary.open('ws2_32.dll')`
  + `lookupFunction` 自己取（并做懒加载，否则非 Windows 环境 import 该文件就崩）。
- 连接按端口 1 → 2 → 3 → 4 回退；SOCKADDR_BTH 的 `serviceClassId` 留全零 = GUID_NULL，不用赋值。
- `library;` 指令必须在所有 import 之前，否则 analyze 报 library_directive_not_first。
- **这套逻辑本机没有打印机可验证**：错误信息里刻意带上 WSAGetLastError 的码值，
  用户拿到设备后试打一次，看码值就能判断是端口、配对还是地址问题。

- **发版要改两处版本号**：`app/pubspec.yaml` 的 `version` 与 `installer/ggjb.iss` 的 `#define AppVersion`。只改前者会打出 `ggjb-<旧版本>-windows-setup.exe`（1.9.0 发版时踩过，装包名还是 1.6.0）。
