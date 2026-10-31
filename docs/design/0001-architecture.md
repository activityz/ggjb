# ggjb 技术架构与数据模型（决策记录 0001）

> 状态：已定稿（基于用户确认的目标平台与同步需求）
> 确认输入：目标端 = Windows 电脑 + Android 手机；同步 = 局域网 + 手动导出导入都要；图片 = 需要归档。

---

## 0. 决策摘要

| 决策项 | 结论 |
|---|---|
| 开发框架 | **Flutter 3.x**（Dart），一套代码出 Windows + Android |
| 本地存储 | **SQLite**，通过 **Drift** ORM 访问；单文件数据库 |
| 状态管理 | Riverpod（provider 化，便于测试） |
| 局域网同步 | 内置 **shelf** HTTP 服务 + HTTP 客户端，记录级增量同步 |
| 手动导入导出 | `VACUUM INTO` 生成整库快照 `.db` + JSON 交换格式双轨 |
| 图片存储 | **BLOB 存库内**（原图压缩 + 缩略图分列），不用外部路径 |
| 金额类型 | **整数「分」**（`*_cents INTEGER`），禁用浮点 |
| 冲突解决 | `(updated_at, device_id)` 构成全序，取大者胜；软删除墓碑参与同步 |

---

## 1. 技术选型最终结论

### 1.1 为什么是 Flutter，而不是 Tauri 2

平台收窄到 Windows + Android 后，Tauri 2 确实进入了可行区（不再需要 iOS 的 Mac 签名链）。但依然选 Flutter，理由按权重排序：

1. **Drift 的成熟度是决定性因素**。这个应用的核心复杂度不在 UI，而在「关系型数据 + 迁移 + 实时聚合查询」。Drift 提供编译期校验的 SQL、自动生成的类型安全 DAO、流式 `watch()` 查询、可版本化的 schema 迁移。Tauri 侧的 `tauri-plugin-sql` 只做到「执行 SQL 字符串」，业务层要自己序列化、自己管迁移，工作量与出错面都更大。
2. **Android 构建链**。`flutter build apk` 一条命令；Tauri 2 上 Android 需要 Android SDK + NDK + Rust 交叉编译目标 + Gradle 胶水，配置成本和出问题时的排查成本明显更高。
3. **取舍**：接受 Flutter 包体更大（几十 MB vs 几 MB）。个人自用，这条权重近乎为零。

Tauri 2 仅在一种情况下翻盘：开发者只熟 TypeScript、完全不想碰 Dart。本项目不适用。

### 1.2 为什么图片进 BLOB 而不是存路径

这是本架构里**对同步影响最大的一个决定**。

| 方案 | Windows 路径 | Android 路径 | 同步代价 |
|---|---|---|---|
| 存文件路径 | `D:\ggjb\images\a.jpg` | `/data/data/.../images/a.jpg` | 两端路径语义完全不同，必须做「路径映射表」，同步时要单独传文件目录并在对端重写路径；漏一个字节就是永久坏图 |
| **存 BLOB** | 无路径概念 | 无路径概念 | 同步 = 同步数据库本身，图片天然跟着走，不会失联 |

选择 BLOB 的代价：数据库文件变大。控制手段：

- 入库前把原图长边压到 **1920px**、JPEG 质量 **85**，单张控制在 **≤500KB**
- 同时生成 **长边 300px** 的缩略图存 `thumb` 列，列表页只查 `thumb`，不触碰 `bytes`
- 1000 件商品 × 3 张图 ≈ 1.5GB。个人自用可接受；同步时图片走独立分页接口，不阻塞主数据流

---

## 2. 数据模型

### 2.1 设计约束

- **主键用 UUID v4 文本**，不用自增整数。两端各自能离线创建记录而不会主键冲突。
- **所有表都带 `created_at / updated_at / deleted_at / device_id`**。前三个用 epoch 毫秒（`INTEGER`），`deleted_at` 非空即软删除墓碑——物理删除的记录在同步时会被对端"复活"，这是必须避开的坑。
- **金额统一用「分」**。`19.9 元` 存 `1990`。浮点累加会在总利润上漂移出分位误差。

### 2.2 建表 DDL

```sql
PRAGMA foreign_keys = ON;

-- 商品：一个交易单元（单件）
CREATE TABLE item (
  id                TEXT    PRIMARY KEY,
  title             TEXT    NOT NULL,
  category          TEXT,
  brand             TEXT,
  model             TEXT,
  storage           TEXT,   -- 内存/存储规格，如 8+256、12+512
  color             TEXT,
  condition_bought  TEXT,
  condition_sold    TEXT,
  status            TEXT    NOT NULL DEFAULT 'in_stock',
                            -- in_stock | listed | sold | completed | returned | scrapped
  source_platform   TEXT,   -- 买入渠道：xianyu / zhuanzhuan / offline / other
  buy_date          INTEGER,
  buy_price_cents   INTEGER NOT NULL DEFAULT 0,
  sell_date         INTEGER,
  sell_price_cents  INTEGER,             -- NULL 表示未售出
  sell_platform     TEXT,
  lot_id            TEXT,                -- 打包买入/卖出时的分组标识
  note              TEXT,
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL,
  deleted_at        INTEGER,
  device_id         TEXT    NOT NULL
);
CREATE INDEX idx_item_status     ON item(status);
CREATE INDEX idx_item_updated_at ON item(updated_at);

-- 费用：一件商品可挂多笔
CREATE TABLE expense (
  id           TEXT    PRIMARY KEY,
  item_id      TEXT    NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  kind         TEXT    NOT NULL,  -- shipping | buy_fee | sell_fee | repair | packaging | other
  side         TEXT    NOT NULL,  -- buy | sell —— 决定算在成本侧还是变现侧
  amount_cents INTEGER NOT NULL,
  incurred_at  INTEGER NOT NULL,
  note         TEXT,
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL,
  deleted_at   INTEGER,
  device_id    TEXT    NOT NULL
);
CREATE INDEX idx_expense_item ON expense(item_id);

-- 图片：BLOB 内联
CREATE TABLE attachment (
  id         TEXT    PRIMARY KEY,
  item_id    TEXT    NOT NULL REFERENCES item(id) ON DELETE CASCADE,
  role       TEXT    NOT NULL,  -- buy_shot | sell_shot | chat_screenshot | serial | other
  mime       TEXT    NOT NULL,
  bytes      BLOB    NOT NULL,
  thumb      BLOB    NOT NULL,
  width      INTEGER,
  height     INTEGER,
  size_bytes INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  device_id  TEXT    NOT NULL
);
CREATE INDEX idx_attachment_item ON attachment(item_id);

-- 同步游标：每台对端一条
CREATE TABLE sync_state (
  peer_id       TEXT PRIMARY KEY,  -- 对端 device_id
  last_pull_at  INTEGER,           -- 上次从对端拉到的最大 updated_at
  last_push_at  INTEGER,           -- 上次推给对端的最大 updated_at
  peer_name     TEXT,
  paired_at     INTEGER
);

-- 本机身份（单行表）
CREATE TABLE local_device (
  id         TEXT PRIMARY KEY,     -- UUID，首次启动生成
  name       TEXT,
  created_at INTEGER NOT NULL
);

-- 字典：8 类选项池，统一管理
CREATE TABLE dict_entry (
  id         TEXT    PRIMARY KEY,  -- 内置项用确定性 id：seed|kind|label
  kind       TEXT    NOT NULL,     -- brand|model|storage|color|category|source|platform|condition
  label      TEXT    NOT NULL,
  parent_id  TEXT,                 -- 机型挂品牌；其余为空
  sort_order INTEGER NOT NULL DEFAULT 0,
  built_in   INTEGER NOT NULL DEFAULT 0,  -- 1=内置种子，仅作标记，不禁止删除
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  device_id  TEXT    NOT NULL
);
CREATE INDEX idx_dict_kind      ON dict_entry(kind);
CREATE INDEX idx_dict_parent    ON dict_entry(parent_id);
CREATE INDEX idx_dict_updated   ON dict_entry(updated_at);
```

**字典只影响「以后选什么」，不回写已有记录**：`item.brand` 等列存的是选中时的文本快照，
字典里改名或删除都不会改动历史单子。这样同步时也不会出现「一端改了字典、另一端的历史数据被改写」。

#### 2.2.1 字典与商品的边界

| 存哪 | 存什么 | 为什么 |
|---|---|---|
| `dict_entry` | 可选项池（品牌/机型/内存/颜色/分类/来源/渠道/成色） | 一处维护、两端同步、可增可删 |
| `item.*` 文本列 | 选中瞬间的文本 | 商品记录必须能独立成立，不依赖字典当时长什么样 |

### 2.3 利润视图

```sql
CREATE VIEW v_item_profit AS
SELECT
  i.id,
  i.title,
  i.status,
  i.buy_price_cents,
  COALESCE(e.expense_cents, 0)                        AS expense_cents,
  i.sell_price_cents,
  CASE
    WHEN i.sell_price_cents IS NULL THEN NULL
    ELSE i.sell_price_cents
         - i.buy_price_cents
         - COALESCE(e.expense_cents, 0)
  END                                                 AS profit_cents
FROM item i
LEFT JOIN (
  SELECT item_id, SUM(amount_cents) AS expense_cents
  FROM expense
  WHERE deleted_at IS NULL
  GROUP BY item_id
) e ON e.item_id = i.id
WHERE i.deleted_at IS NULL;
```

看板聚合：

```sql
SELECT
  COUNT(CASE WHEN status IN ('sold','completed') THEN 1 END)        AS sold_count,
  COUNT(CASE WHEN status = 'sold' THEN 1 END)                       AS receivable_count,
  COALESCE(SUM(CASE WHEN status IN ('sold','completed')
                    THEN profit_cents END), 0)                      AS realized_profit_cents,
  COALESCE(SUM(CASE WHEN status = 'sold'
                    THEN sell_price_cents END), 0)                  AS pending_receivable_cents,
  COALESCE(SUM(CASE WHEN status IN ('in_stock','listed')
                    THEN buy_price_cents + expense_cents END), 0)   AS capital_locked_cents
FROM v_item_profit;
```

---

## 3. 利润口径（必须先定死，否则代码一定是错的）

1. **单笔毛利** = `卖出价 − 买入价 − 该商品全部未删除费用（买入侧 + 卖出侧）`
2. **已实现总利润** = 所有 `status ∈ (sold, completed)` 商品的毛利之和。这是用户说的"总共赚了多少"。
   钱到没到手不影响赚多少，只影响「待收款」这项提醒。
3. **待收货款** = 所有 `status = 'sold'` 商品的 `sell_price_cents` 之和。这是买家/平台还欠的钱，
   **是欠款不是利润**，不并入净到手——对应的利润已经在第 2 条里算过一次了，再并进去就是重复计算。
4. **状态流转**：`在库 in_stock → 已上架 listed → 已卖出 sold → 已到账 completed`。
   `sold` = 货走了、钱在路上；`completed` = 钱真到账。回退路径只允许逐级：
   `completed → sold → in_stock`，不能从 `completed` 直接退货或回库，先退回 `sold` 再说。
5. **在途资金占用** = `status ∈ (in_stock, listed)` 的 `买入价 + 已发生费用` 之和。**不并入总利润**，单独展示——把在途成本算进利润是自欺欺人。
6. **退货**：`status = 'returned'`，`sell_price_cents` 置 `NULL`，已发生的卖出侧费用（运费）照实扣除，计入亏损。
7. **报废/自用**：`status = 'scrapped'`，视为亏损 = `买入价 + 费用`。
8. **打包买入/卖出**：拆成 N 个 `item`，共享一个 `lot_id`；买入价按约定比例分摊写入各自 `buy_price_cents`，不要靠事后计算。
9. **分期/尾款**：一期不实现。当前允许改 `sell_price_cents`，靠 `updated_at` 同步出去。

---

## 4. 同步设计

### 4.1 局域网同步

**拓扑**：任意一端起服务（shelf），另一端作为客户端连入。Windows 作 Host 更常见（手机连电脑热点或同一 WiFi）。

**握手**：
1. Host 启动后在界面显示 `IP:8787` + **6 位一次性配对码**
2. 客户端输入配对码 → `POST /v1/pair` → Host 校验后返回 `peer_token`
3. 之后所有请求带 `Authorization: Bearer <peer_token>`。避免同一 WiFi 下被别人扫到就读走账本。

**实际实现的协议：整库快照交换**（比原设计的记录级增量更简单，已按此落地）

```
GET  /v1/info      → { device_id, device_name, schema_version, pairing_required }
POST /v1/pair      → { peer_token, device_id, device_name }        // body: { code }
GET  /v1/snapshot  → 本机 VACUUM INTO 出来的整库 .db（octet-stream）
POST /v1/snapshot  → 接收对方 .db，合并进本机，返回各项计数
```

一次「同步」= 先 `GET /v1/snapshot` 拉对方快照合并进本地，再 `POST /v1/snapshot` 把本地快照推给对方合并。
两边合并规则都是 `(updated_at, device_id)` 较新者胜，所以**顺序无关、重复执行也安全**，中途断掉不会坏数据。

**为什么放弃记录级增量**：
- 少维护一套易错的增删改协议，两端只依赖同一个 `MergeService`；
- 图片是 BLOB，增量协议必须再造一条附件通道 + 断点续传 + 元数据/字节一致性校验，四五个新坑；
- 个人库规模（千级记录 + 几百张图）快照只有几十 MB，同一 WiFi 下传一次几秒到十几秒，完全够用。

**代价**：库变大后每次同步都要传全库。到那时再加「仅同步文本」开关（跳过 `attachments` 的 BLOB 列），协议本身不用动。

**合并引擎**（`app/lib/sync/merge.dart`，导出/导入与局域网同步共用同一套）：
`ATTACH DATABASE <对方快照> AS incoming` → 每张表先 `DELETE` 本地被对方更新的行 → 再 `INSERT OR IGNORE` 补入对方全部行。
**合并期间必须 `PRAGMA foreign_keys = OFF` 且在事务外设置**，否则删 `items` 那一行会级联删掉本地较新的 `expenses`。

**冲突解决（确定性，不弹窗）**：

```
if (incoming.updated_at, incoming.device_id) > (local.updated_at, local.device_id)
    → 覆盖本地
else
    → 丢弃对方
```

元组比较 + `device_id` 兜底，保证两端算出同一结果，不会震荡。

**Android 侧必须处理**：
- `AndroidManifest.xml` 加 `INTERNET` / `ACCESS_NETWORK_STATE` / `ACCESS_WIFI_STATE` / `WAKE_LOCK` / `FOREGROUND_SERVICE` 权限
- 明文 HTTP：`application` 节点加 `android:usesCleartextTraffic="true"`（Android 9+ 默认禁明文）
- 作 Host 时启动前台服务，否则锁屏后 socket 被系统杀掉（**当前版本尚未实现前台服务**，长时间停在同步页才可靠）
- 保活：同步窗口期内持有 `PARTIAL_WAKE_LOCK`

**Windows 侧**：首次监听会触发防火墙弹窗，必须允许"专用网络"。Windows 与手机不在同一网段、或路由器开了 AP 隔离时都连不上，先排查这两项。

### 4.2 手动导出 / 导入

| 动作 | 实现 |
|---|---|
| 导出整库 | `VACUUM INTO '<目标路径>/ggjb_20261030.db'`——生成无碎片、无 WAL 残留的干净快照，比直接复制 db 文件安全 |
| 导出交换包 | zip：`manifest.json`（schema_version + device_id + 导出时间）+ `data.json`（三张表的全量记录）+ `blobs/`（图片）+ `schema.sql` |
| 导入（覆盖） | 校验 `schema_version` 兼容后，直接替换数据库文件，重启数据层 |
| 导入（合并） | **复用 4.1 的 merge 引擎**，两端记录走同一套 `(updated_at, device_id)` 比较。禁止为导入另写一套合并逻辑 |

`schema_version` 不匹配时：低版本 → 走迁移；高版本 → 拒绝导入并提示升级，不要尝试降级解析。

---

## 5. 工程结构

```
ggjb/
├─ app/                              # Flutter 应用
│  ├─ lib/
│  │  ├─ data/
│  │  │  ├─ db/
│  │  │  │  ├─ tables.dart           # Drift 表定义
│  │  │  │  ├─ database.dart         # AppDatabase + 迁移
│  │  │  │  └─ database.g.dart       # 生成
│  │  │  ├─ dao/
│  │  │  │  ├─ item_dao.dart
│  │  │  │  ├─ expense_dao.dart
│  │  │  │  ├─ attachment_dao.dart
│  │  │  │  └─ dashboard_dao.dart
│  │  │  └─ repo/                    # 事务边界在这一层
│  │  ├─ domain/
│  │  │  ├─ money.dart               # 分 <-> 元 转换，四舍五入规则唯一出口
│  │  │  ├─ profit.dart              # 利润口径的唯一实现
│  │  │  └─ image_pipeline.dart      # 压缩 + 缩略图
│  │  ├─ sync/
│  │  │  ├─ merge.dart               # (updated_at, device_id) 全序比较
│  │  │  ├─ host_server.dart         # shelf，仅 Windows 常用
│  │  │  ├─ client.dart
│  │  │  └─ exporter.dart            # VACUUM INTO / zip 交换包
│  │  ├─ features/
│  │  │  ├─ item_list/
│  │  │  ├─ item_edit/
│  │  │  ├─ item_detail/
│  │  │  ├─ dashboard/
│  │  │  └─ settings/
│  │  └─ main.dart
│  ├─ android/
│  └─ windows/
├─ docs/
│  ├─ design/0001-architecture.md    # 本文件
│  └─ knowledge/
└─ README.md
```

**分层纪律**：利润计算只允许出现在 `domain/profit.dart`；UI 层任何地方不得自己拼 SQL 算钱。

---

## 6. 落地清单（按依赖顺序）

| # | 事项 | 状态 |
|---|---|---|
| 1 | 建 Flutter 工程，接 Drift，落 2.2 的 schema，跑通首次迁移 | ✅ 完成（`schemaVersion 1`，6 个索引，`PRAGMA foreign_keys=ON`） |
| 2 | `domain/money.dart` + `domain/profit.dart` + 单元测试（含退货、报废、打包分摊三种边界） | ✅ 完成（39 个测试全过，退货/报废/零成本/空集合/merge 均覆盖） |
| 3 | 商品 CRUD + 费用 CRUD + 图片入库流水线（压缩/缩略图） | ✅ 完成（`ItemRepository.save` 事务内全量替换费用；`ImagePipeline` 走 Isolate，先 bakeOrientation） |
| 4 | 看板：已实现总利润 / 在途资金 / 按品类、按平台聚合 | ✅ 完成：总利润、在途、平均毛利、毛利率、按分类与按卖出渠道排行（各取前 6 名）均已实现；聚合口径统一由 `StatDao` 转 `ProfitCalculator`，不另算一套 |
| 5 | 导出（VACUUM INTO + zip 交换包） | ⚠️ 部分完成：整库快照导出已完成；**zip 交换包未做**（快照已含图片，暂不需要） |
| 6 | 局域网同步：客户端 + 宿主机 + 配对码 | ✅ 完成（`host_server.dart` / `client.dart` / `merge.dart`，协议改成整库快照交换，理由见 4.1） |
| 7 | Android 打包（明文 HTTP、权限）；Windows 打包（防火墙说明） | ✅ 两端都已出包。Android：`dist/ggjb-1.0.0-release.apk`（61 MB，SHA256 `C867B8EE…CF3EDF0`），构建门槛 Gradle 8.14 / AGP 8.11.1 / Kotlin 2.2.20 / NDK 27.0.12077973。Windows：`dist/ggjb-1.0.0-windows-x64.zip`（13.5 MB，解压 32 MB / 16 文件，SHA256 `95A7BF62…C9E6B9E7`），VS Community 2026 18.11.3 + Windows 10 SDK 10.0.26100.0，首次构建 588.8s。**注意 Windows 产物是文件夹，分发必须整目录打包** |
| 8 | 全量导入的合并模式复跑 6 的 merge 引擎做回归 | ✅ 设计上已共用同一个 `MergeService`；**尚未做端到端实跑回归** |

### 相对设计已落地时的偏离

| 设计 | 实际 | 原因 |
|---|---|---|
| 记录级增量同步 + 独立附件通道 | 整库快照交换 | 少一套易错协议；图片是 BLOB，增量还得再造断点续传与一致性校验；当前规模快照只有几十 MB |
| 端口 8765 | 8787 | 顺手选的，无特殊含义 |
| 图片按需分页拉 | 不分页，随快照走 | 同上 |
| Android 作 Host 用前台服务保活 | 未实现 | 需要 platform channel + 原生 Service，当前建议电脑当主机 |

---

## 7. 已知风险

| 风险 | 缓解 |
|---|---|
| 两端系统时钟不准导致 `updated_at` 判序错误 | 首次配对时比对时间差，超过 60 秒则提示用户校正系统时间。**当前未实现时钟比对**，配对前先确认两台设备都开了自动对时 |
| 图片使 db 膨胀，局域网同步慢 | 整库快照交换的代价就是每次传全库。库里图片到几百 MB 时再加「仅同步文本」开关（跳过 BLOB 列），协议不用改 |
| SQLite 并发写（Host 服务端 + UI 写入）| 全库单连接 + Drift 的 `transaction` 串行化；合并整体包在一个事务里 |
| Android 后台被系统杀死导致同步中断 | **未实现前台服务**。当前建议电脑当主机；快照交换是原子的，中途断掉只是这次没同步成功，不会写坏数据 |
| 合并时 `PRAGMA foreign_keys` 忘记关闭导致级联删除本地较新数据 | `MergeService` 里在事务外显式关闭、`finally` 恢复；`_verifySchema()` 逐列比对列名与顺序，不一致直接抛错而不是带病合并 |
