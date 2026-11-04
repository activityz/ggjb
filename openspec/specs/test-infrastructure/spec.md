# test-infrastructure Specification

## Purpose
TBD - created by archiving change test-coverage-app-wide. Update Purpose after archive.

## Requirements

### Requirement: 测试必须用项目锁定的 SDK 执行

测试与静态分析 SHALL 只通过 fvm 3.47.1 的绝对路径调用，MUST NOT 依赖 PATH 上的 `flutter`。理由：PATH 上装的是 3.35.4，与 `pubspec.yaml:29` 的 `intl: ^0.20.3` 解算冲突（3.35.4 的 `flutter_localizations` 锁定 intl 0.20.2），跑起来会先死在 `version solving failed`，而不是给出测试结果。

#### Scenario: 用 PATH 上的 flutter 跑测试

- **WHEN** 执行 `flutter test`
- **THEN** pub 解算在 `intl` 上失败并中止，不产生任何测试结果
- **AND** 必须改用 `D:/develop/flutter/fvm/versions/3.47.1/bin/flutter.bat test`

#### Scenario: 用锁定 SDK 跑测试

- **WHEN** 执行 `D:/develop/flutter/fvm/versions/3.47.1/bin/flutter.bat test`
- **THEN** 测试正常收集并执行，不出现解算错误

### Requirement: 全量测试必须零失败零跳过

`app/test/` 下的全部用例 SHALL 在锁定 SDK 上一遍通过，MUST NOT 留 skip。发现的行为缺陷 MUST 在同一轮内修掉（见 `fix-baseline-defects`），不能以 skip 长期挂账——skip 会让 TDD 的红灯机制失效。

#### Scenario: 运行全量测试

- **WHEN** 在 `app/` 下执行 `flutter test`
- **THEN** 输出 `All tests passed!`
- **AND** 汇总行不含 `~`（跳过）标记，通过数等于收集数

#### Scenario: 某个用例暴露了产品缺陷

- **WHEN** 新写的用例在正确实现上应为绿、当前实现上为红
- **THEN** 该缺陷 MUST 修在生产代码里，用例转绿后才允许收尾
- **AND** MUST NOT 用 `skip: '待裁决'` 把红灯留在主干

### Requirement: 静态分析必须干净

`flutter analyze` SHALL 输出 `No issues found!`。测试文件同样计入——未使用的 helper、多余的 import、`!` 滥用都算 issue。

#### Scenario: 提交前跑分析

- **WHEN** 在 `app/` 下执行 `flutter analyze`
- **THEN** 退出码为 0 且输出 `No issues found!`
