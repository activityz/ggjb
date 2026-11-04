# sync-reliability

## ADDED Requirements

### Requirement: 参与合并的表必须参与监听

同步调度器监听的表集合 SHALL 与 `MergeService.syncedTables` 完全一致。
任何一张表只出现在一侧，都会让该表的改动只能等兜底轮询。

#### Scenario: 记一笔运营成本会触发同步

- **WHEN** 用户在运营成本页记一笔并保存
- **THEN** 调度器在 1.2 秒防抖后发起同步，而不是等到 25 秒轮询

#### Scenario: 新增一张同步表时两边同时改

- **WHEN** 未来把新表加进 `syncedTables`
- **THEN** `SyncController.watchedTables` 的用例会因为数量不等而失败，提醒补监听

### Requirement: 临时文件在成功和失败路径都必须清理

`/v1/snapshot` 的收发两端 SHALL 在 `finally` 里删除自己创建的临时库文件。

#### Scenario: 推送一个坏包

- **WHEN** 对端 POST 一个不是 SQLite 的字节串
- **THEN** 返回 500，且临时目录里不留 `ggjb_*` 文件

#### Scenario: 拉取成功

- **WHEN** 客户端拉完整库并合并
- **THEN** 本地临时文件被删除

### Requirement: 解绑必须让对端令牌失效

解绑 SHALL 先调用对端 `POST /v1/unpair`，再删本地记录；对端不在线时忽略失败。

#### Scenario: 解绑后旧令牌不能再推数据

- **WHEN** 本机解绑，随后用解绑前的 token 请求 `/v1/snapshot`
- **THEN** 对端返回 401

#### Scenario: 对端关机时解绑

- **WHEN** 对端不可达
- **THEN** 本机仍然删掉本地记录并提示已解绑

### Requirement: 失败但已合并的同步也要刷新界面

`syncNow` SHALL 在「尝试过且不是连不上/没配对」的情况下 invalidate 报表类
Provider，无论成功与否。

#### Scenario: 拉取成功但推送失败

- **WHEN** sync 先拉后推，推送那步超时
- **THEN** 拉回来的数据在界面上立刻可见，`_lastError` 记下失败原因

### Requirement: 连不上的对端要跳过

同一进程内连续失败的 peer SHALL 在下次挑选时被跳过；全部跳过时回退到原列表。

#### Scenario: 一台关机一台在线

- **WHEN** 两台对端，最近同步的那台关机
- **THEN** 第一次尝试失败并记录，第二次直接连在线的那台并成功

### Requirement: 异常输入有上限

`/v1/snapshot` SHALL 拒绝超过配置上限的请求体（413）；`/v1/pair` SHALL 对
同一来源每分钟超过配置次数的失败尝试返回 429。

#### Scenario: 超大快照

- **WHEN** 请求声明长度超过上限
- **THEN** 服务端读完请求体后返回 413，且不落临时文件

#### Scenario: 猜配对码

- **WHEN** 同一 IP 在 1 分钟内连续输错达到上限
- **THEN** 后续请求返回 429，提示等一分钟
