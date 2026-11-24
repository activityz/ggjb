import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/db/app_database.dart';

/// 保修卡画布的逻辑尺寸。截图按 3 倍出，即 1080×1620。
const double warrantyCardWidth = 360;
const double warrantyCardHeight = 540;

/// 截图倍率。3 倍下 360×540 正好是 1080×1620，打印和转发都够清晰。
const double warrantyCardPixelRatio = 3;

/// 保修卡面（纯展示，不依赖 Riverpod，方便单测与离屏截图）。
///
/// 硬约束（见 openspec 的 design D8 与 spec）：
/// - **不含任何价格**：这是给买家的凭证，成本与成交价都不该出现在上面；
/// - 二维码码值是商品主键，与详情页那个二维码完全一致；
/// - 三条店内保修条款用店主原话，不改写、不缩写。
class WarrantyCardView extends StatelessWidget {
  const WarrantyCardView({super.key, required this.item});

  final Item item;

  /// 店内保修条款。字面照抄店主给的三条，改动前先问。
  static const List<String> terms = [
    '① 本店店内保修：非人为故障享受店铺质保，摔落、进水、人为损坏不在保修范围内。',
    '② 质保期间请勿私自拆机、刷机、维修，一经发现直接取消店内保修。',
    '③ 凭本机序列号享受店内保修，妥善保管，请勿自行更改序列号信息。',
  ];

  static const Color _ink = Color(0xFF111111);
  static const Color _muted = Color(0xFF666666);
  static const Color _line = Color(0xFFE0E0E0);
  static const Color _accent = Color(0xFF0B5FFF);

  String _date(DateTime? value) {
    if (value == null) return '—';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String get _modelLine {
    final parts = [
      item.brand,
      item.model,
      item.storage,
      item.color,
    ].where((e) => e != null && e.isNotEmpty).cast<String>();
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    // 字号不跟随系统缩放：卡面是固定画布，放大就会挤成一团。
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: warrantyCardWidth,
        height: warrantyCardHeight,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: _ink,
            fontSize: 11,
            height: 1.35,
            // 中文优先，避免测试环境与桌面端落到奇怪的兜底字体上。
            fontFamilyFallback: ['Microsoft YaHei', 'Noto Sans CJK SC'],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '保修卡',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      '店内保修凭证',
                      style: TextStyle(fontSize: 10, color: _muted),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _date(item.sellDate),
                    style: const TextStyle(fontSize: 10, color: _muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 2, color: _accent),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _kv('型号', _modelLine),
              _kv('成色', item.conditionSold ?? '—'),
              _kv('序列号', item.serial ?? '—'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FF),
                  border: Border.all(color: const Color(0xFFD6E2FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '商家保修',
                      style: TextStyle(
                        fontSize: 10,
                        color: _muted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(item.merchantWarrantyStart)} 至 '
                      '${_date(item.merchantWarrantyEnd)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: _line),
              const SizedBox(height: 8),
              const Text(
                '保修条款',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 4),
              for (final term in terms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    term,
                    style: const TextStyle(fontSize: 8.5, height: 1.4),
                  ),
                ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: QrImageView(
                      data: item.id,
                      size: 56,
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '扫码查看商品记录',
                          style: TextStyle(fontSize: 9, color: _muted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 7.5,
                            color: _muted,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11))),
      ],
    ),
  );
}
