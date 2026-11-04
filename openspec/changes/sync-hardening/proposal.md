# 同步可靠性加固

## Why

同步体检（2026-11-04）在真机上复现出三个用户能直接感知的问题：

- 记一笔运营成本，对面 25 秒内看不到。`SyncController` 监听表更新时漏了
  `operating_costs`，而合并里是有这张表的 —— 于是「本地改了」这个信号压根
  没发出来，只能等兜底轮询。
- 推送一个坏包，临时目录里留下一个整库文件。POST/GET 的 `catch` 里没有
  `finally`，失败路径的 `ggjb_incoming_*.db` 永远不删，越积越多。
- 解绑只删自己那行。对方手里那张 token 还能继续推数据进来，等于没解绑。

另外四处属于「现在不疼、数据量上来会疼」：整库四次进内存、多设备只试一台、
失败不刷新界面、配对码可以无限猜。

## What Changes

- 监听清单与合并清单对齐，并抽成 `SyncController.watchedTables` 单一口径。
- `/v1/snapshot` 收发都改流式；临时文件一律 `finally` 删。
- 新增 `POST /v1/unpair`：解绑时先让对方作废令牌，再删本地行。
- 失败但已合并过的同步也要 invalidate 报表，失败原因留在状态里。
- 连不上的对端在本次会话内跳过，别把在线的堵死。
- 推送体积上限（默认 512 MB）+ 配对码限速（同 IP 每分钟 10 次）。
- `MergeService._tables` 提升为公开常量 `syncedTables`，供测试比对。

## Capabilities

### New Capabilities

- `sync-reliability`：局域网同步在失败路径、并发对端、异常输入下的行为契约。

### Modified Capabilities

无。

## Impact

- 改动文件：`lib/sync/{merge,sync_controller,host_server,client,auto_sync}.dart`、
  `lib/features/settings/settings_page.dart`
- 新增测试：`test/sync/sync_hardening_test.dart`（6 条）
- 协议新增一个端点，旧版本对端不认识会 404 —— 解绑路径已按「失败就算了」处理
- 数据库 schema 无变化，不需要迁移
