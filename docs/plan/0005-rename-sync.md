# 0005 · 改名「搞个机吧」+ 自动同步 + 冲突报错

## 执行进度

| 项 | 状态 |
| --- | --- |
| P0 改名六处 | ✅ AndroidManifest / main.cpp / Runner.rc×2 / main.dart / settings footer 全部改完 |
| P1 冲突检测（P1 只做了字段与落库，冲突列举与逐笔选择） | ⏸ 未做 —— 当前 merge 仍是「时间新者胜」，不报冲突 |
| P2 token 持久化 + AutoSyncService + 首页同步按钮 + 设置页开关 | ✅ |
| P2 启动自动同步（home_shell initState） | ✅ 静默，仅版本/令牌问题才提示 |
| P2 增量自动同步（`SyncController`） | ✅ 写入即同步（tableUpdates + 1.2s 防抖）、25s 兜底轮询、两端都监听 8787 |
| P2 同步按钮改为全局 | ✅ 移到 `home_shell` 的 AppBar；三个页面各自的 `appBar` 已删 |
| P2 连接记录 | ✅ 设置页「同步」卡列出已配对设备（名字 / host:port / 上次同步时间 / 解绑） |
| P3 版本校验 | ✅ `SyncClient.sync()` 开头比对 `schema_version` |
| 回归 | ✅ `flutter analyze` 0 issue / `flutter test` 72 项全过 |
| 重新构建双端 | ⏸ 需用户明确确认 |

## 目标

1. 应用显示名改为「搞个机吧」——Android 桌面、Windows 标题栏、应用内标题。
2. 启动时自动尝试同步一次（已配对的对端在线就同步，不在线静默跳过）。
3. 同步时「数据不一致」要明确报错，分两类处理：
   - **结构不一致**（两端 schema 版本不同）→ 直接中止，给可读的中文提示。
   - **记录冲突**（同一笔记两边在「上次同步之后」都改过）→ 先把不冲突的合完，再列出冲突逐笔让你选保留哪边。

## 非目标

- **不改 exe 文件名、不改包名 `me.local.ggjb`、不改 Dart 包名 `ggjb`**。改 CMake target 名会把 `windows/` 下多处构建脚本一起带崩，风险远大于收益；用户看不到 exe 文件名。
- 不做定时轮询（耗电，且个人使用场景没有强一致需求）。
- 不做 UDP 广播自动发现（要额外实现发现协议，收益是省一次手输 IP）。
- 不改变「非冲突记录按 `(updated_at, device_id)` 取大者胜」这一现有规则。

## 现状与问题定位

`app/lib/sync/merge.dart:58` 的合并表是 `['items','expenses','attachments','dict_entries']`，`_verifySchema()` 逐表比对列名与列数，对不上抛 `表 xxx 的列数不一致（本地 N，对方 M）`。

`dist/ggjb-1.0.0-release.apk` 构建于字典化之前（无 `dict_entries` 表、`items` 少 `storage`/`color` 两列），今天新出的 exe 有；**两端跨版本同步必然报「列数不一致」**。这条提示本身是对的，但缺三样：

1. 没有提前在 `/v1/info` 阶段拦下来，非要等合并时才炸；
2. 提示没说清楚「本机 v几 / 对方 v几」；
3. 真冲突（两边都改过同一条）目前是静默取时间戳大的，用户无从得知数据被覆盖。

---

## P0 · 改名（无依赖，先做）

| 文件 | 行 | 现在 | 改成 |
| --- | --- | --- | --- |
| `app/android/app/src/main/AndroidManifest.xml` | 10 | `android:label="二手账本"` | `android:label="搞个机吧"` |
| `app/windows/runner/main.cpp` | 30 | `window.Create(L"ggjb", origin, size)` | `window.Create(L"\u641e\u4e2a\u673a\u5427", origin, size)` |
| `app/windows/runner/Runner.rc` | 93 | `VALUE "FileDescription", "ggjb"` | `VALUE "FileDescription", "搞个机吧"` |
| `app/windows/runner/Runner.rc` | 98 | `VALUE "ProductName", "ggjb"` | `VALUE "ProductName", "搞个机吧"` |
| `app/lib/main.dart` | 34 | `title: '二手账本'` | `title: '搞个机吧'` |
| `app/lib/features/settings/settings_page.dart` | 420 | `'二手账本 · 数据只存在本机'` | `'搞个机吧 · 数据只存在本机'` |

`main.cpp` 用 `\u` 转义而不是直接写中文：MSVC 对源文件编码敏感，取决于有无 BOM 与 `/utf-8` 选项，转义是唯一不受编码影响安全的写法。`Runner.rc` 首行已 `#pragma code_page(65001)`，可直接写 UTF-8 中文。

`InternalName` / `OriginalFilename` 保持 `ggjb`（与真实文件名一致，不能撒谎）。

## P1 · 同步冲突检测（核心改动）

### 1. 加同步水位字段

`app/lib/data/db/tables.dart` 的 `SyncStates` 增加四列：

```dart
TextColumn get peerToken => text().nullable()();
TextColumn get peerHost => text().nullable()();
IntColumn get peerPort => integer().nullable()();
DateTimeColumn get lastSyncAt => dateTime().nullable()();
```

`app/lib/data/db/app_database.dart`：`schemaVersion` 2 → 3，`onUpgrade` 加 `if (from < 3)` 分支 `addColumn` 四列。

`lastSyncAt` 是「上次成功同步完成的时刻」，冲突判据全靠它。`peerToken` 是 P2 自动同步的凭证。

### 2. 合并引擎支持冲突上报

`app/lib/sync/merge.dart`：

```dart
class MergeConflict {
  final String table;      // 'items' | 'expenses' | 'attachments' | 'dict_entries'
  final String id;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;
  final String localLabel;  // items 用 title，其他用 id 前 8 位
  final String remoteLabel;
}

class MergeOutcome {
  final MergeReport report;
  final List<MergeConflict> conflicts;
  final String snapshotPath;   // 保留，供用户选边后重跑
}
```

`mergeFromFile(path, {DateTime? since})`：

- 先 `_collectConflicts(since)`，把真冲突行挑出来，**本轮不删也不插**，其余行照原逻辑合并。
- 冲突判据（写在代码注释里）：

```
row.id 两边都有
AND l.updated_at > since      // 本机在同步之后动过
AND r.updated_at > since      // 对方在同步之后也动过
AND l.updated_at != r.updated_at   // 两边改成了不同结果
```

`since == null`（首次同步 / 手动导入备份）时退回现有行为：时间新者胜，不报冲突。手动导入的场景下用户本来就期望「合进来」，弹一堆冲突没意义。

### 3. 用户选边后应用

```dart
Future<MergeReport> applyResolution(
  String snapshotPath, {
  required Map<String, bool> keepRemote,   // id -> true 表示用对方的
});
```

重新 `ATTACH` 那个快照文件，对 `keepRemote[id] == true` 的行执行 `DELETE FROM t WHERE id=?` + `INSERT OR REPLACE`，`false` 的直接跳过（本地本来就没动）。快照文件由调用方持有，`mergeFromFile` 不再自动删。

### 4. UI

`app/lib/features/settings/settings_page.dart` 的 `_connectDialog` / `_import` 改成接收 `MergeOutcome`：

- `conflicts.isEmpty` → 现有 toast。
- 否则弹 `_ConflictDialog`：`ListView` 列出「商品「iPhone 13」· 本机 14:32 / 对方 14:35」，每行两个按钮「用本机的」「用对方的」，默认全选「用对方的」（时间较新的一方）。
- 底部「应用」→ `applyResolution` → 再 invalidate 三个 provider。

`app/lib/sync/client.dart` 的 `pullAndMerge` 返回值从 `MergeReport` 改成 `MergeOutcome`；`pushTo` 返回的仍是对方上报的 `MergeReport`（对方的冲突由对方 UI 处理，不该阻塞我这边）。

## P2 · 启动自动同步

### 1. token 持久化（前提）

现在 `SyncHost._tokens` 是内存集合，`stop()` 就清空，重启应用后旧 token 全失效——**不持久化就没法自动同步**。

- `host_server.dart`：`start()` 时从 `sync_states` 把该 peer 的 `peerToken` 载入 `_tokens`；`/v1/pair` 成功时把新 token 写回 `sync_states`（按 `device_id` 找行，没有就插）。
- `client.dart`：`pair()` 成功后把 `{peerId, peerName, peerHost, peerPort, peerToken}` 写进 `sync_states`。

### 2. 自动同步

新建 `app/lib/sync/auto_sync.dart`：

```dart
class AutoSyncService {
  /// 启动时调一次。永远不抛异常、不弹窗，失败只记 debugPrint。
  Future<AutoSyncOutcome> tryOnce();
}
```

流程：

1. 读 `sync_states` 第一行；无 `peerHost` 或 `peerToken` → 直接返回 `skipped`。
2. `ping(host, port)`，超时 **3 秒**（不是 30 秒，启动时不能卡住界面）。
3. 比对 `schema_version`，不一致 → 返回 `versionMismatch`（**这个要弹提示**，属于 P3 的「明确报错」）。
4. `sync()`；冲突不为空 → 返回 `hasConflicts(outcome)`，由 UI 弹冲突框。
5. 成功 → 更新 `lastSyncAt`。

`app/lib/features/home/home_shell.dart` 的 `initState` 里 `Future.microtask(() => ref.read(autoSyncProvider).tryOnce())`，结果只在 `versionMismatch` 或 `hasConflicts` 时通过 `ScaffoldMessenger` 提示，其余静默。

### 3. 首页同步按钮（m02703）

`app/lib/features/dashboard/dashboard_page.dart` 的 AppBar 右侧加一个图标按钮：

```dart
IconButton(
  icon: _syncing
      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
      : const Icon(Icons.sync),
  tooltip: _lastSyncAt == null ? '立即同步' : '立即同步（上次 ${_ago(_lastSyncAt!)}）',
  onPressed: _syncing ? null : _syncNow,
)
```

`_syncNow()` 与启动时的自动同步**共用 `AutoSyncService.tryOnce()`**，但行为不同：

| 场景 | 自动（启动时） | 手动（点按钮） |
| --- | --- | --- |
| 没有保存过对端 | 静默跳过 | 打开「连接另一台设备」弹窗（复用 settings 的 `_connectDialog` 逻辑） |
| 连不上 / 超时 | 静默 | toast「连不上 X，检查是否同一网络」 |
| 版本不一致 | 弹提示 | 弹提示 |
| 有冲突 | 弹冲突列表 | 弹冲突列表 |
| 成功 | 静默，写 `lastSyncAt` | toast「已同步：合入 N 条 / 推送 M 条」+ **触发一次 `ParticleBurst`** |

**手动同步也要 3 秒超时**，超过就按「连不上」处理 —— 按钮转圈超过 3 秒用户会以为卡死。

`_lastSyncAt` 从 `sync_states` 读，`_ago` 输出「3 分钟前 / 2 小时前 / 昨天」。

### 4. 设置页增加开关

`sync_states` 再加一列 `autoSync`（int，默认 1）——或者放 `local_devices`。放在 `sync_states` 里按 peer 粒度控制更合理。设置页「同步」卡片加一个 `SwitchListTile`「启动时自动同步」。

## P3 · 版本不一致的明确报错

`app/lib/sync/client.dart` 的 `sync()` 开头加：

```dart
final info = await ping(host, port);
final remoteSchema = (info['schema_version'] as num?)?.toInt() ?? -1;
if (remoteSchema != _db.schemaVersion) {
  throw SyncException(
    '两端版本不一致：本机 v${_db.schemaVersion}，对方 v$remoteSchema。\n'
    '请把两台设备都升级到同一个安装包后再同步。',
  );
}
```

`merge.dart` 的 `_verifySchema()` 报错文案也补上「本机缺表 / 对方缺表」的区分，方便判断该升哪一端。

---

## 依赖关系

```
P0 改名（独立，可先做完先验）
  ↓
P1 冲突检测（改 tables + merge + client + settings）
  ↓
P2 自动同步（依赖 P1 的 sync_states 新列与 token 持久化）
  ↓
P3 版本校验（依赖 P2 的 ping 前置调用位置）
```

P3 逻辑上最简单，但它要挂在 `sync()` 入口，而 `sync()` 在 P1 会被改签名，所以放最后一起改。

## 风险

| 风险 | 处理 |
| --- | --- |
| schemaVersion 2→3，老库要迁移 | `onUpgrade` 已用 `m.addColumn`，drift 会自动处理；迁移前建议用户导出一次备份 |
| token 落库后，同网段拿到 token 的人可读写全库 | 现有协议本就无加密，README 已声明；本次不扩大攻击面（token 只多了一个持久化位置） |
| 冲突判据依赖两端时钟 | `updated_at` 都是各自系统时钟。时钟偏差大时判据会失真——与现有「时间新者胜」同源问题，本次不引入新风险；设置页提示「两机时间应一致」 |
| `mergeFromFile` 不再删快照，残留临时文件 | 调用方在 `applyResolution` 后必须删；用 `finally` 保证 |
| 自动同步在启动时卡顿 | ping 硬超时 3 秒，且 `Future.microtask` 不阻塞首帧 |

## 验收

1. `flutter analyze` 无 issue，`flutter test` 全过。
2. Android 桌面图标名、Windows 标题栏、应用内标题都显示「搞个机吧」。
3. 两端**同版本**能正常同步，不弹冲突。
4. 两端**不同版本**同步 → 立刻弹「两端版本不一致：本机 v3，对方 v2」，不进入合并流程。
5. 手动制造冲突（两端各改同一条商品后再同步）→ 弹冲突列表，选「用对方的」后对方数据覆盖本地。
6. 关掉对端开机自启、只留一端 → 启动时自动同步静默失败，不弹窗、不卡界面。
7. 点首页同步按钮 → 按钮转圈，成功 toast「已同步」并炸一次粒子；连不上 toast 报错；超 3 秒不再等。
8. 构建 APK / exe 需用户明确确认后才执行。
