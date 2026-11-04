import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/dict_seeds.dart';

/// 字典字段：一个可手输的输入框 + 右侧下拉选单。
///
/// 为什么不用 `Autocomplete`：手机上弹出的建议列表太小，二手场景经常
/// 一边翻聊天记录一边选，全屏底部弹窗更好点。同时保留手输 ——
/// 遇到字典里没有的机型，直接打完保存，顺手还能「加进字典」。
class DictField extends ConsumerWidget {
  const DictField({
    super.key,
    required this.controller,
    required this.label,
    required this.kind,
    this.parentLabel,
    this.parentKind,
    this.hint,
    this.enabled = true,
    this.onPicked,
  });

  final TextEditingController controller;
  final String label;

  /// 字典类别，见 [DictSeeds]。
  final String kind;

  /// 父项类别（只有机型需要，传 [DictSeeds.kindBrand]）。
  final String? parentKind;

  /// 父项文本（品牌名）。为空表示不做父项过滤。
  ///
  /// 之所以传文本而不是 id：商品表存的是品牌文本快照，编辑页拿不到字典 id。
  final String? parentLabel;

  final String? hint;
  final bool enabled;

  /// 选中某项后的回调（品牌变化要清空机型，靠它联动）。
  final void Function(String value)? onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(
      dictEntriesProvider(
        (kind: kind, parentLabel: parentLabel, parentKind: parentKind),
      ),
    );
    final count = entries.value?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        // 整框点开选择器，不做行内输入：手机上一根手指的范围里，
        // 「点箭头」和「点空白处」实际是同一块肌肉记忆，只让 24px 的箭头响应
        // 就是让人觉得「点不动」。想填字典里没有的值，在选择器里直接新增。
        readOnly: true,
        onTap: enabled ? () => _pick(context, ref) : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: IconButton(
            tooltip: count == 0 ? '字典里还没有 $label' : '$label（$count 项）',
            onPressed: enabled ? () => _pick(context, ref) : null,
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DictSheet(
        kind: kind,
        parentKind: parentKind,
        parentLabel: parentLabel,
        title: label,
      ),
    );
    if (picked == null) return;
    controller.text = picked;
    onPicked?.call(picked);
  }
}

/// 字典选择弹窗。搜不到想要的就直接在底部新增。
class DictSheet extends ConsumerStatefulWidget {
  const DictSheet({
    super.key,
    required this.kind,
    required this.title,
    this.parentKind,
    this.parentLabel,
  });

  final String kind;
  final String title;
  final String? parentKind;
  final String? parentLabel;

  @override
  ConsumerState<DictSheet> createState() => _DictSheetState();
}

class _DictSheetState extends ConsumerState<DictSheet> {
  final _search = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(
      dictEntriesProvider(
        (
          kind: widget.kind,
          parentLabel: widget.parentLabel,
          parentKind: widget.parentKind,
        ),
      ),
    );
    final all = async.value ?? const [];
    final list = _keyword.isEmpty
        ? all
        : all.where((e) => e.label.contains(_keyword)).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '选${widget.title}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${all.length} 项',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: false,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                  hintText: '筛选…',
                ),
                onChanged: (v) => setState(() => _keyword = v.trim()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _keyword.isEmpty
                              ? (widget.parentLabel == null
                                  ? '这一类字典还是空的'
                                  : '这个品牌下还没有机型')
                              : '没有匹配「$_keyword」的项',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return ListTile(
                          dense: true,
                          title: Text(e.label),
                          trailing: e.builtIn == 1
                              ? null
                              : Tooltip(
                                  message: '自己加的',
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                          onTap: () => Navigator.of(context).pop(e.label),
                        );
                      },
                    ),
            ),
            if (_keyword.isNotEmpty && !list.any((e) => e.label == _keyword))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _addNew,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('把「$_keyword」加进字典'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNew() async {
    final label = _keyword;
    if (label.isEmpty) return;
    final dao = ref.read(dictDaoProvider);
    try {
      // 父项只给了文本，新增子项时要先换成真 id，否则挂不上。
      String? parentId;
      if (widget.parentLabel != null && widget.parentKind != null) {
        parentId = await dao.idOfLabel(widget.parentKind!, widget.parentLabel!);
      }
      await dao.insert(
        kind: widget.kind,
        label: label,
        parentId: parentId,
        deviceId: ref.read(deviceIdProvider),
      );
      if (!mounted) return;
      _search.clear();
      setState(() => _keyword = '');
      Navigator.of(context).pop(label);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('加进字典失败：$e')));
    }
  }
}
