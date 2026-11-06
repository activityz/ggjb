# Spec Delta

## Purpose

让应用能直接驱动 40×30mm 蓝牙热敏标签机打印记录二维码标签，不再绕道导出图片与厂商 App。

## ADDED Requirements

### Requirement: 可连接标签打印机

系统 SHALL 允许用户在 Android 上扫描附近的蓝牙设备、选择一台并建立连接，也 MUST 允许断开当前连接。连接状态 MUST 在界面上可见。未授予蓝牙权限或连接失败时 MUST 给出明确提示，MUST NOT 静默失败。

#### Scenario: 扫描并连接成功

- **WHEN** 用户打开标签打印机页并扫描附近设备，选中其中一台
- **THEN** 建立连接，界面显示已连接该设备
- **AND** 打印入口随之可用

#### Scenario: 没有蓝牙权限

- **WHEN** 用户首次进入扫描流程而系统尚未授予蓝牙权限
- **THEN** 提示需要蓝牙权限
- **AND** 扫描不启动，界面不出现空白列表

#### Scenario: 连接失败或设备已关闭

- **WHEN** 选中的设备连接超时或连接被拒绝
- **THEN** 提示连接失败及设备名
- **AND** 保持未连接状态，可重试

#### Scenario: 断开连接

- **WHEN** 用户点击断开
- **THEN** 连接关闭，界面回到未连接状态

### Requirement: 可按 40×30mm 打印记录标签

在已连接打印机的 Android 设备上，系统 SHALL 把一条记录的标签按 40×30mm 打印：内容 MUST 包含该记录的二维码、标题与明文码值。打印 MUST NOT 修改任何记录数据。

#### Scenario: 打印一张标签

- **WHEN** 用户在已连接状态下对某条记录触发打印
- **THEN** 打印机输出一张 40×30mm 标签，含二维码、标题与明文码值
- **AND** 记录数据未被修改

#### Scenario: 未连接打印机时触发打印

- **WHEN** 用户在没有连接打印机的情况下触发打印
- **THEN** 提示先连接打印机
- **AND** 不产生任何打印输出

#### Scenario: 打印过程中断

- **WHEN** 发送指令超时或打印机返回失败
- **THEN** 提示打印失败
- **AND** 应用不崩溃，可重新连接后再试

### Requirement: 打印入口的平台可用性

打印入口 MUST 只在具备蓝牙打印能力的平台出现；不具备该能力的平台 MUST NOT 展示该入口，且 MUST NOT 影响导出 PNG 的既有能力。

#### Scenario: Android 端

- **WHEN** 应用在 Android 上运行
- **THEN** 二维码弹窗中出现打印入口

#### Scenario: Windows 端

- **WHEN** 应用在 Windows 上运行
- **THEN** 二维码弹窗中不出现打印入口
- **AND** 导出 PNG 仍然可用
