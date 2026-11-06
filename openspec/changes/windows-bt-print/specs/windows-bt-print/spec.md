# Spec Delta

## Purpose

让 Windows 桌面端也能直接驱动已配对的蓝牙标签打印机，打印 40×30mm 的记录二维码标签，不必再导出图片绕厂商工具。

## ADDED Requirements

### Requirement: 可列出并连接已配对的打印机

在 Windows 上，系统 SHALL 列出操作系统中已配对的蓝牙设备并允许用户选择其中一台建立连接，也 MUST 允许断开。未配对任何设备时 MUST 明确提示去系统设置配对，MUST NOT 显示空白列表让人以为出错。

#### Scenario: 列出已配对设备并连接

- **WHEN** Windows 上已有一台配对的蓝牙打印机，用户打开标签打印机页
- **THEN** 设备出现在列表中，名称可辨认
- **AND** 选中后建立连接，界面显示已连接

#### Scenario: 一台都没配对

- **WHEN** Windows 上没有任何已配对的蓝牙设备
- **THEN** 页面提示「先在 Windows 设置里配对打印机」
- **AND** 不显示空白列表

#### Scenario: 连接失败

- **WHEN** 打印机已关机或不在范围内，用户点连接
- **THEN** 提示连接失败与设备名
- **AND** 保持未连接状态，可重试

#### Scenario: 断开连接

- **WHEN** 用户点击断开
- **THEN** 连接关闭，界面回到未连接状态

### Requirement: Windows 端可打印 40×30mm 标签

在已连接打印机的 Windows 设备上，系统 SHALL 按 40×30mm 打印记录标签：内容 MUST 包含该记录的二维码、标题与明文码值，MUST 与 Android 端使用同一套指令格式。打印 MUST NOT 修改任何记录数据。

#### Scenario: 打印一张标签

- **WHEN** 用户在已连接状态下对某条记录触发打印
- **THEN** 打印机输出一张 40×30mm 标签，含二维码、标题与明文码值

#### Scenario: 未连接时触发打印

- **WHEN** 用户在没有连接打印机的情况下触发打印
- **THEN** 提示先连接打印机
- **AND** 不产生任何打印输出

### Requirement: 打印入口的平台可用性

打印入口 MUST 在具备蓝牙打印能力的平台（Android 与 Windows）出现，MUST NOT 在其它平台出现，且 MUST NOT 影响导出 PNG 的既有能力。

#### Scenario: Windows 端

- **WHEN** 应用在 Windows 上运行
- **THEN** 二维码弹窗中出现打印入口
- **AND** 导出 PNG 仍然可用

#### Scenario: Android 端不受影响

- **WHEN** 应用在 Android 上运行
- **THEN** 打印链路仍然走原有的原生通道，行为与本次改动前一致
