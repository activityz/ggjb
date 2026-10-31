import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/dict_seeds.dart';

/// 字典管理：8 类字典的统一维护入口。
///
/// 这里改的是「选项池」，不会回写已有商品 —— 商品表存的是选中时的文本快照，
/// 所以把「Apple」改成「苹果」之后，旧单子还是「Apple」。这是有意的。
class DictManagePage extends ConsumerWidget {
  const DictManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: DictSeeds.kinds.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('字典管理'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final k in DictSeeds.kinds) Tab(text: k.label),
            ],
          ),
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: context.palette.pageGradient),
          child: TabBarView(
            children: [
              for (final k in DictSeeds.kinds)
                _KindTab(kind: k.kind, label: k.label),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindTab extends ConsumerStatefulWidget {
  const _KindTab({required this.kind, required this.label});

  final String kind;
  final String label;

  @override
  ConsumerState<_KindTab> createState() => _KindTabState();
}

class _KindTabState extends ConsumerState<_KindTab> {
  final _search = TextEditingController();
  String _keyword = '';

  /// 保留 `kind` / `label` 短名，下面几个动作方法不必逐处改成 `widget.xxx`。
  String get kind => widget.kind;
  String get label => widget.label;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allDictProvider);
    final all = async.value ?? const <DictEntry>[];
    final idToLabel = {for (final e in all) e.id: e.label};
    final allOfKind = all.where((e) => e.kind == kind).toList();
    // 字典项是中文为主，统一转小写做包含匹配 —— 品牌里 Apple / Google 这种
    // 英文名，用户手输小写也该能搜到。
    final items = _keyword.isEmpty
        ? allOfKind
        : allOfKind
            .where((e) => e.label.toLowerCase().contains(_keyword))
            .toList();
    final brands = all.where((e) => e.kind == DictSeeds.kindBrand).toList();
    final isModel = kind == DictSeeds.kindModel;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                _keyword.isEmpty
                    ? '$label · ${items.length} 项'
                    : '$label · 匹配 ${items.length} / ${allOfKind.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _add(context, ref, brands),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新增'),
              ),
            ],
          ),
        ),
        if (isModel)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '机型挂在品牌下。编辑商品时先选品牌，再列表里就只剩这个品牌的机型。',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: '搜索$label…',
              suffixIcon: _keyword.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: '清除',
                      onPressed: () {
                        _search.clear();
                        setState(() => _keyword = '');
                      },
                    ),
            ),
            onChanged: (v) =>
                setState(() => _keyword = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    _keyword.isEmpty ? '这一类还没有任何项' : '没有匹配「$_keyword」的项',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final e = items[i];
                    final parent = e.parentId == null
                        ? null
                        : (idToLabel[e.parentId!] ?? '（品牌已删除）');
                    return ListTile(
                      dense: true,
                      leading: e.builtIn == 1
                          ? const SizedBox(width: 4)
                          : Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      title: Text(e.label),
                      subtitle: parent == null ? null : Text('属于 $parent'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'rename') {
                            _rename(context, ref, e);
                          } else if (v == 'delete') {
                            _delete(context, ref, e);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'rename', child: Text('改名')),
                          PopupMenuItem(value: 'delete', child: Text('删除')),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    List<DictEntry> brands,
  ) async {
    final isModel = kind == DictSeeds.kindModel;
    final controller = TextEditingController();
    String? brandId =
        isModel && brands.isNotEmpty ? brands.first.id : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('新增$label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(labelText: label),
              ),
              if (isModel) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: brandId,
                  decoration: const InputDecoration(labelText: '归属品牌'),
                  items: [
                    for (final b in brands)
                      DropdownMenuItem(value: b.id, child: Text(b.label)),
                  ],
                  onChanged: (v) => setDialogState(() => brandId = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || text.isEmpty) return;
    if (!context.mounted) return;
    try {
      await ref.read(dictDaoProvider).insert(
            kind: kind,
            label: text,
            parentId: isModel ? brandId : null,
            deviceId: ref.read(deviceIdProvider),
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('新增失败：$e')));
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    DictEntry entry,
  ) async {
    final controller = TextEditingController(text: entry.label);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('改名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || text.isEmpty || text == entry.label) return;
    if (!context.mounted) return;
    try {
      await ref
          .read(dictDaoProvider)
          .rename(entry.id, text, now: DateTime.now());
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('改名失败：$e')));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    DictEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这一项？'),
        content: Text(
          '「${entry.label}」会从选单里消失，已录入的商品不受影响。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await ref
        .read(dictDaoProvider)
        .softDelete(entry.id, now: DateTime.now());
  }
}
