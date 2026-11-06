# 搞个机吧（ggjb）

个人用的二手交易记账程序。记每一件的买入和卖出，算单笔毛利，也算累计赚了多少。

**数据只存在你自己的设备上**——不联网、不上云、不注册账号。两台设备之间靠局域网直连同步，中间不经过任何服务器。

一套 Flutter 代码同时出 Windows 和 Android 两个版本。

---

## 目录

- [装上去](#装上去)
- [能做什么](#能做什么)
- [利润口径](#利润口径写死不会中途改)
- [数据存在哪](#数据存在哪)
- [两台设备怎么同步](#两台设备怎么同步)
- [界面](#界面)
- [自己改、自己编](#自己改自己编)
- [已知限制](#已知限制)
- [项目结构](#项目结构)
- [版本历史](#版本历史)

---

## 装上去

### Windows

双击 `ggjb-<版本>-windows-setup.exe`。装到 `%LOCALAPPDATA%\Programs\ggjb`，**不需要管理员权限**，桌面会有快捷方式。

首次运行会弹「Windows 已保护你的电脑」，点「更多信息 → 仍要运行」。这是没买代码签名证书的必然结果，不是报错。

卸载**不会删数据**——`data\` 目录会留着，重装后接着用。

不想装也可以拿 `ggjb-<版本>-windows-x64.zip` 解压即用，但**整个文件夹要一起拷**：`data\` 和几个 `.dll` 必须和 exe 同目录，只拿 `ggjb.exe` 会启动即闪退（它只有 90 多 KB）。

### Android

传 `ggjb-<版本>-release.apk` 到手机安装，需要允许「安装未知来源应用」。

> **从 1.5.1 起换了正式签名。** 如果你装过更早的包，那个是 debug 签名，新包盖不上去。
> 升级前先进 设置 → 导出整库快照 存一份，再卸载旧的、装新的、把那份 `.db` 导入回来。
> 不备份直接卸载，`Android/data/me.local.ggjb/` 会跟着删掉。

---

## 能做什么

**记一笔**
名称、品牌、型号、内存规格、颜色、分类、买入价、买入日期、来源、成色、备注。卖出后补卖出价、卖出日期、渠道、成色。

价格一律必填（卖出类状态必须填卖出价）。费用金额也必填——填不上就删掉那行，不要留空。

**选单，不用手打**
品牌、机型、内存规格、颜色、分类、买入来源、卖出渠道、成色八类都有预置选项。机型跟着品牌走：先选品牌，型号列表里只剩这个牌子的机型。

想加自己的选项或删掉不用的，去 **设置 → 字典管理**，八个页签，可新增、改名、删除，每个页签都有搜索框。改字典不动历史记录——已经记下的单子还是当时选的那个词。

**记费用**
运费、买入手续费、卖出手续费、维修清洁、包装、其他。每笔标明在「买入侧」还是「卖出侧」，两侧都计入毛利。

**记图片**
买入图、卖出图、聊天截图、序列号/铭牌、其他。选图后自动压到长边 1920px（单张 ≤500KB），另存 300px 缩略图。

**图片存进数据库本身**（BLOB），不是存路径。这样备份和同步时图片天然跟着走，不会出现「记录还在但图没了」——Windows 是 `D:\...`、Android 是 `/data/...`，存路径必然要在对端重映射，漏一个字节就永久坏图。

**状态流转**
在库 → 已上架 → 已卖出 → 已到账；也能买家退货 / 报废，或退回在库。

`已卖出` 是货走了钱还在路上，`已到账` 是钱真到手。两者都算赚到了，区别只在看板「待收货款」那一栏。回退只能逐级走：已到账 → 已卖出 → 在库。

删除是软删除，留墓碑参与同步（否则对端会把删掉的记录又推回来）。

**看板**
- 净到手 = 已实现利润 + 了结亏损
- 已实现利润：`已卖出` 和 `已到账` 都算
- 待收货款：`已卖出` 的卖出价合计——是欠款不是利润
- 了结亏损：退货和报废造成的亏损
- 在途占用：还在手上压着的钱，不计入利润
- 平均每单毛利、已实现毛利率、已了结单数、已售成本合计
- 按分类 / 按卖出渠道排行，各取盈亏前 6 名

**备份**
- **导出整库快照**：一个 `.db`，含全部记录和图片
- **导入并合并**：选另一台设备导出的 `.db`，按「更新时间较新者胜」逐条合并，不会覆盖本地更新的记录

**Excel 导入导出**
- 导出：一个 `.xlsx`，两个表——「商品」22 列（含费用合计 / 总投入 / 毛利 / 毛利率）和「费用明细」7 列
- 导入：在表里改完再导回来。**有 id 且本地存在的按新值覆盖，id 不在本地的补进来，没有 id 的当新记录**；每件商品的费用按表里内容整体替换
- 盈亏四列是导出时算死写进去的值，不是 Excel 公式。导入时这四列被忽略，一切以 `domain/profit.dart` 现算为准，避免「表里写赚 500、App 里算出来赚 300」两套账
- 校验「全或无」：先一次收集所有问题（名称空、买入价不是数字、状态不认识、已卖出却没填卖出价、日期格式不对、费用挂的商品 id 不存在……），**只要有一处不对就一行都不写库**，弹窗里逐条列行号
- 只认 `.xlsx`，不导出图片二进制，不建跨表公式

---

**扫码找记录**
每条记录都能生成一张二维码，码值就是这条记录的 id——**改标题、改价、改状态都不会改码**，贴好的标签永远有效。在详情页右上角点二维码图标，弹窗里能导出 PNG，按 40×30mm 标签打印。

手机端顶栏有扫码按钮（电脑端没有：`mobile_scanner` 没有 Windows 实现），扫一下直接打开那条记录。扫码进去是只读的，点「编辑」才进编辑页。

**直接打印标签**
明细列表每条右侧有二维码图标，点开就是对那条记录的码。弹窗里「导出 PNG」存图片，「打印」直接连蓝牙标签机出 40×30mm 标签（二维码 + 标题 + 码值明文）。

两端都能打，走的是经典蓝牙 SPP 直连，用的是 TSPL 指令——佳博、芯烨、汉印这类 40×30 机型基本都是这套。

Windows 上要先在系统「设置 → 蓝牙和其他设备」里配对打印机（配对要输 PIN，App 代劳不了），之后在 设置 → 标签打印机 里刷新已配对设备、连接。Android 直接在应用里扫描连接。

打印机地址不保存，重启应用后要重新连一次。连接失败时提示里会带错误码（如 10060），可以拿去对照微软文档。

## 利润口径（写死，不会中途改）

| 情况 | 单笔毛利怎么算 |
|---|---|
| 已卖出 / 已到账 | 卖出价 − 买入价 − 全部未删除费用 |
| 已退货 | 0 − 买入价 − 全部未删除费用（卖出侧费用照扣） |
| 已报废 | 同退货 |
| 在库 / 已上架 | 没有毛利，只有资金占用（买入价 + 已发生费用） |

- 已实现总利润 = 「已卖出」+「已到账」的毛利之和
- 待收货款 = 「已卖出」的卖出价合计，是欠款不是利润，**不并入净到手**
- 在途占用单独显示，**不并入总利润**，否则显得比实际赚得多
- 毛利率分母只用已售商品成本，不混入在途
- 打包买卖：拆成多件共享一个批次号，价格按约定比例写进各自买入价，之后不做事后折算
- 分期、尾款：不实现

金额全程用**整数「分」**存储，不用浮点，不丢精度。算钱的代码只有 `app/lib/domain/profit.dart` 一处，UI 层不许自己拼 SQL 算钱。

---

## 数据存在哪

从 1.5.0 起，数据库和导出的文件都放在**程序自己的目录**下，不再散落在系统文档目录里。

| | 位置 |
|---|---|
| Windows | 安装目录下的 `data\`（装到 `%LOCALAPPDATA%\Programs\ggjb\data`）；绿色版就是 exe 旁边的 `data\` |
| Android | `Android/data/me.local.ggjb/files/data/` |

里面是 `ggjb.sqlite`（记录 + 图片全在这一个文件里）和导出的 `.xlsx` / `.db`。

**设置页「数据库文件」那行显示实际路径，点一下可以复制。** 想手动备份，直接把整个 `data\` 目录拷走即可。

程序启动时会先探一下程序目录能不能写（真写一个探针文件试），不可写就回落到系统文档目录，所以装在 `Program Files` 下也能跑。

---

## 两台设备怎么同步

局域网直连，**没有任何中转服务器**。

1. 两台设备连同一个 WiFi
2. 任一台开「本机作为同步主机」，界面显示 `192.168.x.x:8787` 和 6 位配对码
3. 另一台填地址 + 配对码，点连接

配对成功后**双方都会记住对方**（地址、端口、令牌），之后不用再配。设置页能看到已配对设备列表、上次同步时间，也能解绑。

**什么时候会自动同步**

- 打开应用时试一次
- 之后**任何本地改动**（新增、改价、改状态、改字典）1.2 秒防抖后自动推过去
- 每 25 秒兜底拉一次
- 首页右上角随时可以点一下手动同步

连不上时**完全静默**，不弹窗不打扰——只是这次没同步上，下次再说。只有两种情况会提示：两端版本不一致、配对令牌失效（需要重新配对）。

两端都监听 8787，谁先开机都能被对方连上。为了避免「A 推 B、B 收到又推 A」来回空转，同步完成后有 2 秒静默期。

**连不上时的排查顺序**

1. 两台设备是不是同一个 WiFi？（有些路由器 2.4G / 5G 同名但隔离）
2. 路由器是否开了 **AP 隔离**（客户端隔离）——开了就互相不通，必须关
3. Windows 防火墙是否放行了「专用网络」
4. 地址是不是变了——路由器给电脑的 IP 可能变，建议绑定固定 IP
5. 端口 8787 被占用？换一台当主机试试

---

## 界面

两套主题，默认**亮色**：白卡 + 柔和投影。深色是玻璃卡 + 发光 + 粒子。

在 **设置 → 主题** 里选亮色 / 深色 / 跟随系统，**每台设备各存各的**——电脑深色不影响手机亮色。

亮色不是把深色反个色号就完事：

- 玻璃改成实心白卡 + 投影。白底上做模糊只会糊成一团灰
- 粒子直接不创建。浅底上的白点等于没有，留着只白耗电
- 语义色压深一档（利润 `#0F7B4D`、亏损 `#C0392B`）。原来的 `#34D399` 在白底上对比度只有 1.9

深色下会动的地方：

- 看板背景 120 颗缓慢上浮的粒子，靠得近的连成细线；上下滑动时背景比内容慢半拍
- 金额逐位滚上去，数字变了会闪一下
- **标记「已到账」会炸开一次粒子**并有一圈冲击波——这是整个 App 里唯一值得庆祝的事件。手动同步成功也会炸
- 列表和看板加载时是骨架屏，不是转圈
- 下拉列表会重算并炸一下
- 所有金额用等宽数字（`tabularFigures`），滚动时字宽不跳

调色板在 `app/lib/app/palette.dart` 的 `AppPalette.dark` / `AppPalette.light`，**页面里不写颜色字面量**。粒子密度改 `app/lib/ui/particles.dart` 的 `count`。

图标是 `tools/gen_icon.py` 画的（Pillow + numpy，4× 超采样），改完参数重跑就重新生成全部尺寸，包括 Windows 的 `.ico` 和 Android 五档 mipmap。

---

## 自己改、自己编

需要 **Flutter 3.47+**（Dart 3.13+）。

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 生成 drift 的 .g.dart
flutter run -d windows     # 或 -d <android 设备 id>
flutter test               # 72 个单测
flutter analyze
```

### 一键出包

```powershell
pwsh -File tools/build-all.ps1                 # APK + Windows 目录 + zip
pwsh -File tools/build-all.ps1 -SkipAndroid    # 只出 Windows
pwsh -File tools/build-all.ps1 -SkipWindows    # 只出 Android
pwsh -File tools/build-installer.ps1           # 用 Inno Setup 打成单文件安装包
```

产物统一在 `dist/`，文件名自动带 `pubspec.yaml` 里的版本号。构建日志在 `build/_build.log`。

如果 PATH 上的 `flutter` 不是你要用的版本，设 `FLUTTER_BIN` 环境变量指过去。

### Windows 端前置

Flutter 的 Windows 桌面构建**硬依赖** Visual Studio 的 MSVC 工具链，MinGW / clang 都不认。装 Community 版（免费）即可：

```powershell
winget install --id Microsoft.VisualStudio.2022.Community --override "--passive --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"
```

只需勾一个工作负载：**「使用 C++ 的桌面开发」**，右侧必须包含 MSVC v143 生成工具、Windows SDK、C++ CMake tools。下载量约 8-10 GB。

装完终端要重开。`flutter doctor` 里出现 `[√] Visual Studio - develop Windows apps` 就通了。

首次开「同步主机」时 Windows 会弹防火墙提示，必须勾**专用网络**并允许，否则手机连不上。

### Android 端的四个版本门槛

低于任何一个都会直接 BUILD FAILED，模板生成的工程默认就不达标：

| | 最低 | 当前工程用的 |
|---|---|---|
| Gradle | 8.14.0 | 8.14（`gradle-wrapper.properties`） |
| AGP | 8.11.1 | 8.11.1（`settings.gradle.kts`） |
| Kotlin | 2.2.20 | 2.2.20（`settings.gradle.kts`） |
| NDK | 必须已安装 | `27.0.12077973`（`app/build.gradle.kts`） |

**不要无脑升到 Flutter 模板默认的 AGP 9 / Gradle 9.3** —— AGP 9 只认新 DSL，现有 `build.gradle.kts` 会整体失效。

手机空间紧张可以按 ABI 拆包，单包约 22 MB：

```bash
flutter build apk --release --split-per-abi
```

如果报 Android license 未接受：`flutter doctor --android-licenses`。

### 发布签名

`app/android/app/build.gradle.kts` 的逻辑是「有 `app/android/key.properties` 就用 release 签名，没有就退回 debug」——这样别人 clone 下来也能直接 `flutter run --release`。

正式签名材料（`key.properties` 和 `.jks`）**已被 `.gitignore` 排除，不在仓库里**。要出正式包，自己生成一份：

```bash
keytool -genkeypair -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ggjb -storepass '<你的密码>' -keypass '<你的密码>' \
  -dname "CN=ggjb, OU=personal, O=personal, L=Beijing, ST=Beijing, C=CN" \
  -keystore app/android/ggjb-release.jks
```

> **签名身份一旦发出去就不能换。** 换了老用户无法覆盖升级，而卸载会连 `/Android/data/me.local.ggjb/` 一起删，账全没。keystore 和密码请单独备份到项目之外。

核对一个包是谁签的：

```bash
apksigner verify --print-certs app-release.apk
```

---

## 已知限制

- **Android 作同步主机时没做前台服务**：熄屏后系统可能杀掉 socket。建议让电脑当主机，或同步期间别锁屏
- 同步是整库快照交换，库越大传得越久（当前规模几十 MB 内无感）
- 没有加密：同 WiFi 的设备理论上能扫到 8787 端口，靠配对令牌挡；真正敏感的场景别在公共 WiFi 上开主机
- 冲突处理是「更新时间较新者胜」自动合并，不弹窗让你逐笔选。「上次同步之后两边各自改过同一条」目前会被较新的那份覆盖
- 只有 Windows 和 Android，没做 iOS 和 macOS

---

## 项目结构

```
ggjb/
├── app/                     Flutter 工程
│   ├── lib/
│   │   ├── app/             theme.dart（主题）、palette.dart（配色）、providers.dart（Riverpod）
│   │   ├── domain/          money / profit / enums / dict_seeds / image_pipeline / app_paths
│   │   ├── data/
│   │   │   ├── db/          drift 表定义与数据库
│   │   │   ├── dao/         item / attachment / dict / stat
│   │   │   ├── repo/        item_repository（唯一的写入入口）
│   │   │   └── exchange/    Excel 导入导出（rows / export / import）
│   │   ├── sync/            host_server（shelf）、client、auto_sync、sync_controller、merge、exporter
│   │   ├── ui/              GlassCard / GradientText / RollingNumber / AmbientParticles / Shimmer
│   │   └── features/        dashboard / item_list / item_edit / item_detail / dict / settings / home
│   ├── test/                72 个单测
│   └── android/ windows/    两端 runner
├── dist/                    构建产物（不入库）
├── docs/
│   ├── design/0001-architecture.md     架构决策、数据模型、同步协议
│   ├── plan/0002~0008-*.md             每批需求的计划与执行进度
│   └── agent/memory.md, evolution-log  踩过的坑与结论沉淀
├── installer/ggjb.iss       Inno Setup 脚本
└── tools/
    ├── build-all.ps1        一键双端构建
    ├── build-installer.ps1  打 Windows 安装包
    └── gen_icon.py          生成图标全尺寸
```

**几条硬规矩**（改代码前值得先看 `docs/agent/memory.md`）：

- 算钱只在 `domain/profit.dart`，别处不许自己拼 SQL 算
- 金额用整数分，不用浮点
- 主键用 UUID v4，两端离线创建不冲突
- 所有表带 `created_at / updated_at / deleted_at / device_id`，软删除墓碑参与同步
- 页面里不写颜色字面量，一律走 `context.palette`
- 金额文字必须带 `kTabularFigures`

---

## 版本历史

| 版本 | 内容 |
|---|---|
| 1.7.0 | 每条记录生成二维码（码值=记录 id，编辑不变），详情页导出 PNG 打 40×30mm 标签；Android 顶栏扫码直达详情；库结构未动（仍 v6） |
| 1.6.0 | 商品增加保修状态/保修开始/保修到期（「在保」才填日期，详情页在保才展示两行）；Excel 同步三列；库版本 5→6（只加列，旧数据无损伤，中断可续跑） |
| 1.5.1 | 修编辑已有费用时主键冲突导致保存失败；卖出价弹窗改必填；详情页费用明细前移 |
| 1.5.0 | 价格全必填；列表长按删除；中文日期选择器；去同步时的列表动效；Windows 单文件安装包；数据与导出落到程序目录（含旧库自动迁移） |
| 1.4.0 | 修电脑端不会主动连、明细列表同步后不刷新（drift 缓存未失效）；全量排查所有 provider |
| 1.3.0 | 全局同步按钮；任何改动自动同步；已配对设备列表与解绑；首页触发静默自动同步 |
| 1.2.0 | 改名「搞个机吧」；应用图标；亮/深双主题；记住配对设备 |
| 1.1.0 | 八类字典与选择器；「已到账」状态与待收货款；深色玻璃视觉重构；Excel 导入导出 |
| 1.0.0 | 首个双端版本：记一笔、费用、图片、状态流转、看板、备份、局域网同步 |

---

**致谢**：Flutter / Drift / Riverpod / shelf / excel / image / flutter_animate，以及 Inno Setup。
