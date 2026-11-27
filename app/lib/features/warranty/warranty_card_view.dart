import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/db/app_database.dart';

/// 保修卡画布的逻辑尺寸。截图按 3 倍出，即 1080×1620。
const double warrantyCardWidth = 360;
const double warrantyCardHeight = 540;

/// 店铺 logo（「保定天怡数码」）。从店主原图裁到内容边界、保留白底：
/// 卡面本身纯白，白底贴白底看不出框，去背反而会让抗锯齿边缘发脏。
const String shopLogoAsset = 'assets/brand/shop_logo.png';

/// 截图倍率。3 倍下 360×540 正好是 1080×1620，打印和转发都够清晰。
const double warrantyCardPixelRatio = 3;

/// 保修条款的一节：小标题 + 若干条目。
class CardTermsSection {
  const CardTermsSection({required this.heading, required this.items});

  final String heading;
  final List<String> items;
}

/// 保修卡面（纯展示，不依赖 Riverpod，方便单测与离屏截图）。
///
/// 硬约束（见 openspec 的 design D8 与 spec）：
/// - **不含任何价格**：这是给买家的凭证，成本与成交价都不该出现在上面；
/// - 二维码码值是商品主键，与详情页那个二维码完全一致；
/// - 条款用店主原文，逐字照抄，不改写、不缩写、不删条目。
class WarrantyCardView extends StatelessWidget {
  const WarrantyCardView({super.key, required this.item});

  final Item item;

  /// 保修条款：四节，店主给的原文。改字之前先问。
  ///
  /// 540 字、18 段塞进 360×540 的卡面，字号只能到 7.5（3 倍截图下 22.5 实像素）。
  /// 后续再加条款，测试里的 overflow 断言会先红，别偷偷缩字号。
  static const List<CardTermsSection> termSections = [
    CardTermsSection(
      heading: '一、保修保障范围',
      items: [
        '1. 质保期内，设备出现非人为质量问题（主板故障、无信号、不开机、黑屏、功能失灵、原装硬件故障等），本店免费维修。',
        '2. 本店所售产品均已提前检测，无暗病、无进水、无大修、无隐藏ID锁，可正常升级、正常登录账号、正常全网通使用。',
        '3. 全程售后跟进，非人为故障免维修费、免手工费。',
      ],
    ),
    CardTermsSection(
      heading: '二、不在保修范围（免责条款）',
      items: [
        '1. 人为损坏：摔裂、变形、屏幕碎裂、进水、受潮、进液、私自拆机维修。',
        '2. 私自改装、更换配件、破解系统、越狱刷机导致的设备故障。',
        '3. 正常使用磨损（外壳划痕、掉漆、电池正常损耗）不属于质量问题。',
        '4. 外力导致的配件损坏（屏幕、玻璃、边框、摄像头玻璃等）不在免费保修内。',
        '5. 因客户自行刷机、还原、更改硬件导致的故障，终止保修服务。',
      ],
    ),
    CardTermsSection(
      heading: '三、售后服务须知',
      items: [
        '1. 设备支持收货当场验货，当场发现质量问题可无条件退换。',
        '2. 质保期内出现质量问题，往返运费：质量问题卖家承担，人为问题买家承担。',
        '3. 禁止私自拆机，一经发现直接失去保修资格。',
      ],
    ),
    CardTermsSection(
      heading: '四、店铺服务承诺',
      items: [
        '本店产品发货前全部经过：功能全测、电池检测、信号检测、硬件排查，杜绝翻新机、大修机、进水机、故障机。',
        '永久提供免费咨询、验机指导、使用答疑服务！',
      ],
    ),
  ];

  /// 条款结尾的温馨提示，同属店主原文。
  static const String termsFooter =
      '温馨提示：诚信经营、质保为本！所有机器明病提前告知，不套路、不隐瞒，专注靠谱二手数码！';

  /// 条款正文字号。卡面是固定画布，这个数只能往下微调（不低于 7），
  /// 且必须有 overflow 测试兜着。
  static const double termsFontSize = 7.5;

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
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
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
              // 卡头：左边店铺 logo，右边「保修卡 / 店内保修凭证」与售出日期。
              // 「保修卡」字号从 20 降到 13 —— logo 承担视觉识别，360 宽里
              // 20px 标题和 logo 必然打架。
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    shopLogoAsset,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '保修卡',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '店内保修凭证',
                              style: TextStyle(fontSize: 8.5, color: _muted),
                            ),
                          ],
                        ),
                        Text(
                          _date(item.sellDate),
                          style: const TextStyle(fontSize: 8.5, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(height: 2, color: _accent),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              _kv('型号', _modelLine),
              _kv('序列号', item.serial ?? '—'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
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
              const SizedBox(height: 6),
              const Divider(height: 1, color: _line),
              const SizedBox(height: 4),
              // 条款：四节 + 温馨提示。小标题加粗，正文 7.2 —— 卡面就这点地方，
              // 字号再小印出来就糊了，所以空间从间距里挤。
              for (final section in termSections) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    section.heading,
                    style: const TextStyle(
                      fontSize: 8.2,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final line in section.items)
                  Padding(
                    padding: const EdgeInsets.only(top: 1.2),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: termsFontSize,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  termsFooter,
                  style: TextStyle(fontSize: termsFontSize, height: 1.3),
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
                      size: 48,
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
    padding: const EdgeInsets.only(bottom: 2),
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
