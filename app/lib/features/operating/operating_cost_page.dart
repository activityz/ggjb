import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/date_period.dart';
import '../../domain/dict_seeds.dart';
import '../../domain/money.dart';
import '../common/dict_field.dart';

/// 运营成本：房租、水电、快递、推广这些「不是某一单花的」钱。
///
/// 单独一张表、单独一页，而不是塞进 expenses：费用永远挂在某个商品上，
/// 运营成本没有那件商品。混在一起以后每个报表都要问一句「这条有没有 itemId」。
class OperatingCostPage extends ConsumerWidget {
  const OperatingCostPage({super.key, required this.filter});

  /// 从看板点进来时带上来的口径。这里只读不筛，免得两个页面的数字对不上。
  final DashboardFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final async = ref.watch(operatingCostsProvider(filter));
    final total = ref.watch(operatingTotalProvider(filter)).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('运营成本'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                Money(total).toYuanString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('读取失败：$err')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 44,
                      color: palette.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      filter.isAll ? '还没记过运营成本' : '这段时间没有运营成本',
                      style: TextStyle(color: palette.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '房租、水电、包装耗材这些按月花的钱记在这里；'
                      '运费、手续费属于某一单的，记在那一单上。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final row = rows[i];
              return Material(
                color: palette.cardFill,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openEditor(context, ref, row),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    row.kind,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateRange.formatDate(row.spentAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if ((row.note ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  row.note!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Money(row.amountCents).toYuanString(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                        IconButton(
                          tooltip: '删除',
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('删掉这条？'),
                                content: Text(
                                  '${row.kind} ${Money(row.amountCents).toYuanString()}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('算了'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('删掉'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            await ref
                                .read(operatingDaoProvider)
                                .softDelete(row.id);
                            // 软删之后三处要一起失效：列表、合计、看板汇总。
                            // 少了这一步，删完列表和合计都不动，得退出页面
                            // 再进来才看得到 —— 用户会以为没删掉。
                            ref.invalidate(operatingCostsProvider);
                            ref.invalidate(operatingTotalProvider);
                            ref.invalidate(profitSummaryProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    OperatingCost? row,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CostEditorDialog(existing: row),
    );
    if (saved == true) {
      ref.invalidate(operatingCostsProvider);
      ref.invalidate(operatingTotalProvider);
      ref.invalidate(profitSummaryProvider);
    }
  }
}

class _CostEditorDialog extends ConsumerStatefulWidget {
  const _CostEditorDialog({required this.existing});

  final OperatingCost? existing;

  @override
  ConsumerState<_CostEditorDialog> createState() => _CostEditorDialogState();
}

class _CostEditorDialogState extends ConsumerState<_CostEditorDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : Money(widget.existing!.amountCents).toPlainString(),
  );
  late final TextEditingController _kind = TextEditingController(
    text: widget.existing?.kind ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late DateTime _spentAt = widget.existing?.spentAt ?? DateTime.now();
  String? _amountError;
  String? _kindError;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _kind.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '记一笔运营成本' : '改一下'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DictField(
              controller: _kind,
              label: '花在哪 *',
              kind: DictSeeds.kindOperating,
              hint: '点这里选，字典里能自己加',
            ),
            if (_kindError != null) ...[
              const SizedBox(height: 4),
              Text(
                _kindError!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '金额（元）*',
                hintText: '例：1200',
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: _spentAt,
                  helpText: '这笔钱哪天花的',
                );
                if (picked != null) setState(() => _spentAt = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '日期 *'),
                child: Row(
                  children: [
                    Expanded(child: Text(DateRange.formatDate(_spentAt))),
                    const Icon(Icons.calendar_today_outlined, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '不填也行',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final amount = Money.tryParseYuan(_amount.text);
                  final kind = _kind.text.trim();
                  setState(() {
                    _amountError = _amount.text.trim().isEmpty
                        ? '必须填金额'
                        : (amount == null ? '格式不对，填数字' : null);
                    _kindError = kind.isEmpty ? '必须选一个类别' : null;
                  });
                  if (_amountError != null || _kindError != null) return;
                  setState(() => _saving = true);
                  final dao = ref.read(operatingDaoProvider);
                  final deviceId = ref.read(deviceIdProvider);
                  final note = _note.text.trim();
                  if (widget.existing == null) {
                    await dao.insert(
                      spentAt: _spentAt,
                      kind: kind,
                      amountCents: amount!.cents,
                      deviceId: deviceId,
                      note: note.isEmpty ? null : note,
                    );
                  } else {
                    await dao.update(
                      id: widget.existing!.id,
                      spentAt: _spentAt,
                      kind: kind,
                      amountCents: amount!.cents,
                      note: note.isEmpty ? null : note,
                    );
                  }
                  if (!mounted) return;
                  Navigator.pop(this.context, true);
                },
          child: const Text('存下'),
        ),
      ],
    );
  }
}
