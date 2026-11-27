# Spec Delta

## ADDED Requirements

### Requirement: 保修卡卡面含店铺 logo

保修卡卡面 SHALL 在卡头左侧显示店铺 logo（随包内置的图片资源），与「保修卡 / 店内保修凭证」和售出日期同处卡头；logo MUST 等比缩放、不得拉伸变形；卡面整体尺寸 MUST 仍为 1080×1620（逻辑 360×540、3 倍截图）。

#### Scenario: 生成的图片里有 logo

- **WHEN** 用户生成保修卡
- **THEN** 导出的 PNG 卡头区域能检测到 logo 的深色像素
- **AND** 图片尺寸仍为 1080×1620

#### Scenario: 布局不被 logo 挤坏

- **WHEN** 保修卡渲染完成
- **THEN** 卡面没有溢出（无 overflow 异常）
- **AND** 商家保修期起止、二维码与三条条款仍然完整可见
