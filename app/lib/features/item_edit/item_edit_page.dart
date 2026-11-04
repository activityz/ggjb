import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../data/repo/item_repository.dart';
import '../../domain/dict_seeds.dart';
import '../../domain/enums.dart';
import '../../domain/money.dart';
import '../common/dict_field.dart';

/// 新建 / 编辑商品。
///
/// 传 [itemId] 为 null 表示新建。
class ItemEditPage extends ConsumerStatefulWidget {
  const ItemEditPage({super.key, this.itemId});

  final String? itemId;

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  final _title = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _storage = TextEditingController();
  final _color = TextEditingController();
  final _category = TextEditingController();
  final _sourcePlatform = TextEditingController();
  final _buyPrice = TextEditingController();
  final _sellPrice = TextEditingController();
  final _sellPlatform = TextEditingController();
  final _conditionBought = TextEditingController();
  final _conditionSold = TextEditingController();
  final _note = TextEditingController();

  /// 电池健康百分比（0–100）。
  final _batteryHealth = TextEditingController();

  /// 置换场景：挂牌价与旧机抵扣。利润仍然只看 `_sellPrice`（实收）。
  final _listPrice = TextEditingController();
  final _tradeIn = TextEditingController();

  final _expenses = <_ExpenseEditRow>[];

  ItemStatus _status = ItemStatus.inStock;
  DateTime? _buyDate;
  DateTime? _sellDate;
  bool _loading = true;
  bool _saving = false;

  /// 上一次的品牌文本。用来判断「品牌真的变了」才清机型，
  /// 否则每次输入都会把机型清掉。
  String _lastBrand = '';

  @override
  void initState() {
    super.initState();
    _brand.addListener(_onBrandChanged);
    if (widget.itemId != null) {
      _loadExisting(widget.itemId!);
    } else {
      _loading = false;
      _buyDate = DateTime.now();
    }
  }

  Future<void> _loadExisting(String id) async {
    final detail = await ref.read(itemRepositoryProvider).load(id);
    if (!mounted) return;
    if (detail != null) {
      final item = detail.item;
      _title.text = item.title;
      _brand.text = item.brand ?? '';
      _model.text = item.model ?? '';
      _storage.text = item.storage ?? '';
      _color.text = item.color ?? '';
      _category.text = item.category ?? '';
      _sourcePlatform.text = item.sourcePlatform ?? '';
      _buyPrice.text = Money(item.buyPriceCents).toPlainString();
      _sellPrice.text =
          item.sellPriceCents == null ? '' : Money(item.sellPriceCents!).toPlainString();
      _sellPlatform.text = item.sellPlatform ?? '';
      _conditionBought.text = item.conditionBought ?? '';
      _conditionSold.text = item.conditionSold ?? '';
      _note.text = item.note ?? '';
      _batteryHealth.text =
          item.batteryHealth == null ? '' : item.batteryHealth.toString();
      _listPrice.text = item.listPriceCents == null
          ? ''
          : Money(item.listPriceCents!).toPlainString();
      _tradeIn.text =
          item.tradeInCents == null ? '' : Money(item.tradeInCents!).toPlainString();
      _status = item.status;
      _buyDate = item.buyDate;
      _sellDate = item.sellDate;

      _expenses
        ..clear()
        ..addAll(
          detail.expenses.map(
            (e) => _ExpenseEditRow(
              id: e.id,
              kind: e.kind,
              side: e.side,
              amount: TextEditingController(
                text: Money(e.amountCents).toPlainString(),
              ),
              note: e.note ?? '',
            ),
          ),
        );
    }
    setState(() => _loading = false);
  }

  /// 品牌换成另一家时，原来选的机型一定不属于新品牌，清掉更省事。
  /// 手输品牌每敲一个字都会触发，所以要和 [_lastBrand] 比对，否则一输就清空。
  void _onBrandChanged() {
    final brand = _brand.text.trim();
    if (brand == _lastBrand) return;
    _lastBrand = brand;
    if (_model.text.isNotEmpty) {
      _model.clear();
    }
    if (mounted) setState(() {});
  }

  String _brandText() => _brand.text.trim();

  @override
  void dispose() {
    for (final c in [
      _title,
      _brand,      _model,
      _storage,
      _color,
      _category,
      _sourcePlatform,
      _buyPrice,
      _sellPrice,
      _sellPlatform,
      _conditionBought,
      _conditionSold,
      _note,
      _batteryHealth,
      _listPrice,
      _tradeIn,
    ]) {
      c.dispose();
    }
    for (final e in _expenses) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.itemId == null ? '记一笔' : '编辑')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 显式枚举，不用 `!= inStock` 这类偷懒写法——加新状态时会漏。
    // isRealized 覆盖 sold 与 completed：两者都要能填卖出价/日期/渠道。
    final isSellSide = _status.isRealized ||
        _status == ItemStatus.returned ||
        _status == ItemStatus.scrapped;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? '记一笔' : '编辑'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('保存'),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.palette.pageGradient),
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('买进来'),
          _field(
            controller: _title,
            label: '名称 *',
            hint: '例：iPhone 13 128G 蓝色',
          ),
          Row(
            children: [
              Expanded(
                child: DictField(
                  controller: _brand,
                  label: '品牌',
                  kind: DictSeeds.kindBrand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DictField(
                  controller: _model,
                  label: '型号',
                  kind: DictSeeds.kindModel,
                  parentKind: DictSeeds.kindBrand,
                  parentLabel: _brandText().isEmpty ? null : _brandText(),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DictField(
                  controller: _storage,
                  label: '内存规格',
                  kind: DictSeeds.kindStorage,
                  hint: '8+256',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DictField(
                  controller: _color,
                  label: '颜色',
                  kind: DictSeeds.kindColor,
                ),
              ),
            ],
          ),
          DictField(
            controller: _category,
            label: '分类',
            kind: DictSeeds.kindCategory,
            hint: '手机 / 耳机 / 显卡…',
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _buyPrice,
                  label: '买入价（元）*',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _dateField('买入日期', _buyDate, _pickBuyDate)),
            ],
          ),
          DictField(
            controller: _sourcePlatform,
            label: '买入来源',
            kind: DictSeeds.kindSource,
            hint: '闲鱼 / 转转 / 朋友…',
          ),
          DictField(
            controller: _conditionBought,
            label: '买入时成色',
            kind: DictSeeds.kindCondition,
            hint: '95新 / 有划痕…',
          ),
          _field(
            controller: _batteryHealth,
            label: '电池健康（%）',
            hint: '例：88，不填就空着',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 8),
          _section('卖出情况'),
          DropdownButtonFormField<ItemStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: '状态'),
            items: ItemStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
          ),
          if (isSellSide) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _status.isRealized
                      ? _field(
                          controller: _sellPrice,
                          label: '卖出价（元）',
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        )
                      : const _Hint(
                          '退货 / 报废不填卖出价，亏损按「买入价 + 费用」自动计',
                        ),
                ),
                if (_status == ItemStatus.sold) const SizedBox(width: 12),
                if (_status == ItemStatus.sold)
                  Expanded(child: _dateField('卖出日期', _sellDate, _pickSellDate)),
              ],
            ),
            if (_status.isRealized)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '置换（挂牌价、旧机抵扣）在详情页「标记已卖出」里填，'
                  '这里只管商品本身的资料。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_status == ItemStatus.sold) ...[
              const SizedBox(height: 12),
              DictField(
                controller: _sellPlatform,
                label: '卖出渠道',
                kind: DictSeeds.kindPlatform,
                hint: '闲鱼 / 转转…',
              ),
              DictField(
                controller: _conditionSold,
                label: '卖出时成色',
                kind: DictSeeds.kindCondition,
              ),
            ],
          ],

          const SizedBox(height: 8),
          _sectionWithAction('费用', '加一条', _addExpense),
          if (_expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '运费、手续费、维修、包装费都记这里，会从利润里扣。',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (var i = 0; i < _expenses.length; i++) _expenseRow(i),

          const SizedBox(height: 8),
          _section('备注'),
          _field(controller: _note, label: '备注', maxLines: 3),
          const SizedBox(height: 32),
        ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );

  Widget _sectionWithAction(String title, String action, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add, size: 16),
              label: Text(action),
            ),
          ],
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: keyboardType ==
                const TextInputType.numberWithOptions(decimal: true)
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
            : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    final text = value == null
        ? '未填'
        : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _expenseRow(int index) {
    final row = _expenses[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<ExpenseKind>(
              initialValue: row.kind,
              decoration: const InputDecoration(labelText: '种类'),
              isDense: true,
              items: ExpenseKind.values
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => row.kind = v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<ExpenseSide>(
              initialValue: row.side,
              decoration: const InputDecoration(labelText: '侧'),
              isDense: true,
              items: ExpenseSide.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => row.side = v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(labelText: '金额'),
            ),
          ),
          IconButton(
            tooltip: '删除这条费用',
            onPressed: () => setState(() {
              _expenses.removeAt(index).dispose();
            }),
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    setState(() {
      _expenses.add(
        _ExpenseEditRow(
          kind: ExpenseKind.shipping,
          side: _status == ItemStatus.sold ? ExpenseSide.sell : ExpenseSide.buy,
          amount: TextEditingController(),
          note: '',
        ),
      );
    });
  }

  Future<void> _pickBuyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _buyDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _buyDate = picked);
  }

  Future<void> _pickSellDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sellDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _sellDate = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _toast('名称不能为空');
      return;
    }

    final buy = Money.tryParseYuan(_buyPrice.text);
    if (buy == null) {
      _toast('买入价填一个数字');
      return;
    }

    // 价格一律必填：只要状态已经跨过「卖出」这条线，就必须知道卖了多少钱，
    // 否则利润永远算不出来（会静默按 0 计，等于记了一笔假账）。
    final needsSellPrice = _status.isRealized;
    final sellText = _sellPrice.text.trim();
    if (needsSellPrice && sellText.isEmpty) {
      _toast('「${_status.label}」必须填卖出价');
      return;
    }
    final sell = sellText.isEmpty ? null : Money.tryParseYuan(sellText);
    if (sellText.isNotEmpty && sell == null) {
      _toast('卖出价格式不对');
      return;
    }

    // 电池健康：空 = 不填；不是 0–100 的整数就拦下来，不静默截断。
    final batteryText = _batteryHealth.text.trim();
    int? battery;
    if (batteryText.isNotEmpty) {
      battery = int.tryParse(batteryText);
      if (battery == null || battery < 0 || battery > 100) {
        _toast('电池健康填 0–100 的整数');
        return;
      }
    }

    // 置换（挂牌价 / 旧机抵扣）只在详情页「标记已卖出」弹窗里改。
    // 这里仍然把库里原值读出来原样写回去 —— save() 是整行覆盖，
    // 不带上就等于「只改了一下标题，置换记录被抹掉」。
    final listText = _listPrice.text.trim();
    final tradeText = _tradeIn.text.trim();
    final listPrice = listText.isEmpty ? null : Money.tryParseYuan(listText);
    final tradeIn = tradeText.isEmpty ? null : Money.tryParseYuan(tradeText);

    final expenseDrafts = <ExpenseDraft>[];
    for (var i = 0; i < _expenses.length; i++) {
      final row = _expenses[i];
      final text = row.amount.text.trim();
      if (text.isEmpty) {
        // 以前这里是 continue 静默跳过，结果用户以为记了一笔费用、
        // 实际库里没有，对账时才发现。宁可拦下来让他删掉这行。
        _toast('第 ${i + 1} 条费用没填金额，填上或删掉这行');
        return;
      }
      final amount = Money.tryParseYuan(text);
      if (amount == null) {
        _toast('第 ${i + 1} 条费用金额格式不对');
        return;
      }
      expenseDrafts.add(
        ExpenseDraft(
          id: row.id,
          kind: row.kind,
          side: row.side,
          amountCents: amount.cents,
          note: row.note,
        ),
      );
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.save(
        ItemDraft(
          id: widget.itemId,
          title: title,
          category: _emptyToNull(_category.text),
          brand: _emptyToNull(_brand.text),
          model: _emptyToNull(_model.text),
          storage: _emptyToNull(_storage.text),
          color: _emptyToNull(_color.text),
          conditionBought: _emptyToNull(_conditionBought.text),
          conditionSold: _emptyToNull(_conditionSold.text),
          status: _status,
          sourcePlatform: _emptyToNull(_sourcePlatform.text),
          buyDate: _buyDate,
          buyPriceCents: buy.cents,
          sellDate: needsSellPrice ? (_sellDate ?? DateTime.now()) : null,
          sellPriceCents: needsSellPrice ? (sell?.cents) : null,
          sellPlatform: _emptyToNull(_sellPlatform.text),
          note: _emptyToNull(_note.text),
          batteryHealth: battery,
          listPriceCents: listPrice?.cents,
          tradeInCents: tradeIn?.cents,
        ),
        expenseDrafts,
      );
      if (!mounted) return;
      ref.invalidate(profitSummaryProvider);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('保存失败：$e');
    }
  }

  static String? _emptyToNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ExpenseEditRow {
  _ExpenseEditRow({
    this.id,
    required this.kind,
    required this.side,
    required this.amount,
    required this.note,
  });

  final String? id;
  ExpenseKind kind;
  ExpenseSide side;
  final TextEditingController amount;
  final String note;

  void dispose() => amount.dispose();
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
