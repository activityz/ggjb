# 任务

## 1 监听与刷新

- [x] 1.1 `MergeService._tables` → 公开 `syncedTables`
- [x] 1.2 `SyncController.watchedTables(db)` 补 `operatingCosts`
- [x] 1.3 `attach()` 改用 `watchedTables`
- [x] 1.4 `syncNow` 失败分支也 bump + invalidate（仅 attempted）

## 2 传输

- [x] 2.1 GET `/v1/snapshot` 改流式返回，流的 `finally` 删文件
- [x] 2.2 POST `/v1/snapshot` 改 `addStream` 落盘，`finally` 删临时文件
- [x] 2.3 `pullAndMerge` 改 `Client.send` + `addStream`
- [x] 2.4 `pushTo` 改 `StreamedRequest` + `pipe`

## 3 解绑

- [x] 3.1 新增 `POST /v1/unpair`（作废令牌 + 删对端行）
- [x] 3.2 `SyncClient.unpair()`，失败静默
- [x] 3.3 `settings_page._forgetPeer` 先通知对端再删本地

## 4 多对端与限额

- [x] 4.1 `AutoSyncService(skipPeers:)` + `attemptedPeerId`
- [x] 4.2 `SyncController._failedPeers` 记录与清除
- [x] 4.3 `maxSnapshotBytes` 上限（默认 512 MB）+ 413
- [x] 4.4 `maxPairAttempts` 限速（默认 10/分钟）+ 429

## 5 验证

- [x] 5.1 `test/sync/sync_hardening_test.dart` 6 条
- [x] 5.2 `flutter test` 299 通过
- [x] 5.3 `flutter analyze` 干净
