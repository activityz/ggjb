import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../data/dao/attachment_dao.dart';
import '../../data/db/app_database.dart';
import '../../domain/date_period.dart';
import '../../domain/merchant_warranty.dart';
import '../barcode/qr_export.dart';
import 'warranty_card_service.dart';
import 'warranty_card_view.dart';

/// 当前商品的保修卡（最新一张，没有则 null）。
///
/// 详情页与列表页共用同一个 provider key，其中一处生成后 invalidate，
/// 另一处下次打开就能看到新卡。
final warrantyCardProvider =
    FutureProvider.autoDispose.family<Attachment?, String>((ref, itemId) async {
      final db = ref.watch(databaseProvider);
      final service = WarrantyCardService(
        db: db,
        attachments: AttachmentDao(db),
        deviceId: ref.watch(deviceIdProvider),
      );
      return service.latest(itemId);
    });

/// 保修卡弹窗：生成、查看、导出、重置都在这里，详情页与列表页共用。
///
/// 生成前必过一次日期确认（可改），改完先写回记录再截图 ——
/// 保证「卡上印的」和「库里存的」永远是同一组日期。
class WarrantyCardDialog extends ConsumerStatefulWidget {
  const WarrantyCardDialog({super.key, required this.item});

  final Item item;

  @override
  ConsumerState<WarrantyCardDialog> createState() => _WarrantyCardDialogState();
}

class _WarrantyCardDialogState extends ConsumerState<WarrantyCardDialog> {
  bool _busy = false;
  bool _datesReady = false;
  late DateTime _start;
  late DateTime _end;

  void _ensureDates() {
    if (_datesReady) return;
    final today = DateTime.now();
    _start =
        widget.item.merchantWarrantyStart ??
        DateTime(today.year, today.month, today.day);
    _end = widget.item.merchantWarrantyEnd ?? addOneYear(_start);
    _datesReady = true;
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  WarrantyCardService get _service {
    final db = ref.read(databaseProvider);
    return WarrantyCardService(
      db: db,
      attachments: AttachmentDao(db),
      deviceId: ref.read(deviceIdProvider),
    );
  }

  /// 屏幕外渲染卡面再截图：`Offstage` 不绘制，放行内又会被布局裁剪。
  Future<Uint8List?> _renderPng(Item item) async {
    if (!mounted) return null;
    // logo 首帧是异步解码：不预热的话，冷启动第一张卡会截到空白（设计 D6）。
    await precacheImage(const AssetImage(shopLogoAsset), context);
    if (!mounted) return null;
    final key = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -warrantyCardWidth - 20,
        top: 0,
        child: RepaintBoundary(key: key, child: WarrantyCardView(item: item)),
      ),
    );
    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return await renderBoundaryPng(key, pixelRatio: warrantyCardPixelRatio);
    } finally {
      entry.remove();
    }
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.setMerchantWarranty(
        widget.item.id,
        start: _start,
        end: _end,
      );
      final detail = await repo.load(widget.item.id);
      if (detail == null) throw StateError('商品不存在了');

      final png = await _renderPng(detail.item);
      if (png == null) throw StateError('渲染失败');

      await _service.save(widget.item.id, png);
      ref.invalidate(warrantyCardProvider(widget.item.id));
      if (mounted) _toast('保修卡已生成');
    } catch (_) {
      if (mounted) _toast('生成失败，稍后再试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _busy = true);
    try {
      await _service.reset(widget.item.id);
      ref.invalidate(warrantyCardProvider(widget.item.id));
      if (mounted) _toast('保修卡已重置');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(Attachment card) async {
    try {
      final dir = await getTemporaryDirectory();
      final name = card.itemId.replaceAll('-', '');
      final file = File('${dir.path}/ggjb-warranty-${name.substring(0, 8)}.png');
      await file.writeAsBytes(card.bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: '搞个机吧 · 保修卡'),
      );
    } catch (_) {
      if (mounted) _toast('导出失败，稍后再试');
    }
  }

  Widget _dateRow(
    String label,
    DateTime value,
    ValueChanged<DateTime> onPicked,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _busy
            ? null
            : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => onPicked(picked));
              },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(DateRange.formatDate(value)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureDates();
    final cardAsync = ref.watch(warrantyCardProvider(widget.item.id));

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: cardAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('保修卡读取失败：$e'),
            ),
            data: (card) {
              if (!widget.item.status.isRealized) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '保修卡',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    const Text('标记已卖出之后才能生成保修卡。'),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('知道了'),
                      ),
                    ),
                  ],
                );
              }

              if (card != null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '保修卡',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(card.bytes),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => _export(card),
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: const Text('导出 PNG'),
                        ),
                        TextButton.icon(
                          onPressed: _busy ? null : _reset,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('重置保修卡'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('关闭'),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '生成保修卡',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '确认商家保修期，改完会一起写回这条记录。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dateRow('商家保修开始', _start, (v) => _start = v),
                  _dateRow('商家保修到期', _end, (v) => _end = v),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _busy ? null : _generate,
                        icon: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.receipt_long, size: 18),
                        label: const Text('生成保修卡'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
