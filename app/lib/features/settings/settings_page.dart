import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../ui/glass_card.dart';
import '../../data/db/app_database.dart';
import '../../data/exchange/excel_export.dart';
import '../../data/exchange/excel_import.dart';
import '../../domain/money.dart';
import '../../sync/exporter.dart';
import '../../sync/client.dart';
import '../../sync/merge.dart';
import '../../domain/app_paths.dart';
import '../dict/dict_manage_page.dart';

class DbStats {
  const DbStats({
    required this.itemCount,
    required this.imageCount,
    required this.imageBytes,
    required this.fileBytes,
    required this.dirPath,
  });

  final int itemCount;
  final int imageCount;
  final int imageBytes;
  final int fileBytes;

  /// 数据实际落在哪个文件夹 —— 数据库、导出的 Excel 和 .db 快照都在这儿。
  final String dirPath;
}

final dbStatsProvider = FutureProvider<DbStats>((ref) async {
  // 同步会改库，而合并走的是原始 SQL —— drift 的 FutureProvider 不会自己
  // 重算，所以 watch 一下同步计数器，同步完成后这些数字跟着变。
  ref.watch(syncTickProvider);
  final db = ref.watch(databaseProvider);

  Future<int> count(String sql) async {
    final row = await db.customSelect(sql).getSingle();
    final value = row.data.values.first;
    return (value as int?) ?? 0;
  }

  final itemCount = await count('SELECT COUNT(*) AS c FROM items WHERE deleted_at IS NULL');
  final imageCount = await count(
    'SELECT COUNT(*) AS c FROM attachments WHERE deleted_at IS NULL',
  );
  final imageBytes = await count(
    'SELECT COALESCE(SUM(size_bytes), 0) AS c FROM attachments WHERE deleted_at IS NULL',
  );

  var fileBytes = 0;
  try {
    final path = await db.currentFilePath();
    if (path != null) fileBytes = await File(path).length();
  } catch (_) {
    fileBytes = 0;
  }

  return DbStats(
    itemCount: itemCount,
    imageCount: imageCount,
    imageBytes: imageBytes,
    fileBytes: fileBytes,
    dirPath: await AppPaths.describe(),
  );
});


class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _exporting = false;
  bool _importing = false;

  /// Excel 与 .db 快照是两条独立的路，各用各的 busy 标志，
  /// 免得导出 Excel 时「导入并合并」也被一起灰掉。
  bool _excelExporting = false;
  bool _excelImporting = false;

  /// 配对流程专用（填地址 → ping → pair → sync），与全局同步互不干扰。
  bool _connecting = false;

  List<String> _ips = const [];

  String _addressText(int? port) {
    final p = port ?? 8787;
    if (_ips.isEmpty) return '端口 $p';
    return _ips.map((ip) => '$ip:$p').join(' / ');
  }

  Future<void> _refreshIps() async {
    final ips = <String>[];
    try {
      final interfaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final ni in interfaces) {
        for (final addr in ni.addresses) {
          if (!addr.isLoopback) ips.add(addr.address);
        }
      }
    } catch (_) {
      // 拿不到网卡列表就只显示端口，不影响同步本身。
    }
    if (!mounted) return;
    setState(() => _ips = ips);
  }

  Future<void> _connectDialog() async {
    final ipCtl = TextEditingController();
    final portCtl = TextEditingController(text: '8787');
    final codeCtl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('连接另一台设备'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipCtl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: '对方地址',
                hintText: '例：192.168.1.5',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '端口'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '配对码',
                hintText: '对方显示的 6 位数字',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('连接')),
        ],
      ),
    );
    if (ok != true) return;

    final ip = ipCtl.text.trim();
    final port = int.tryParse(portCtl.text.trim()) ?? 8787;
    final code = codeCtl.text.trim();
    ipCtl.dispose();
    portCtl.dispose();
    codeCtl.dispose();

    if (ip.isEmpty || code.isEmpty) {
      _toast('地址和配对码都要填');
      return;
    }

    setState(() => _connecting = true);
    var selfName = ref.read(deviceNameProvider);
    final selfRow = ref.read(localDeviceProvider).value;
    if (selfRow != null) selfName = selfRow.name;
    final client = SyncClient(
      db: ref.read(databaseProvider),
      deviceId: ref.read(deviceIdProvider),
      deviceName: selfName,
    );
    try {
      await client.ping(ip, port);
      final pair = await client.pair(ip, port, code);
      final outcome = await client.sync(host: ip, port: port, token: pair.token);
      if (!mounted) return;
      setState(() => _connecting = false);
      ref.invalidate(dbStatsProvider);
      ref.invalidate(profitSummaryProvider);
      ref.invalidate(peersProvider);
      // 刚配上就开门等着，这样对方下次开机也能连过来。
      await ref.read(syncControllerProvider).refreshHost();
      if (!mounted) return;
      _toast('和「${pair.deviceName}」同步完成\n${outcome.describe()}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _connecting = false);
      _toast('同步失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var deviceName = ref.watch(deviceNameProvider);
    final deviceRow = ref.watch(localDeviceProvider).value;
    if (deviceRow != null) deviceName = deviceRow.name;
    final stats = ref.watch(dbStatsProvider);
    final aggregate = ref.watch(profitSummaryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.palette.pageGradient),
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('这台设备'),
          GlassCard(
            radius: 14,
            blur: 12,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.devices_other_outlined),
                  title: const Text('设备名'),
                  subtitle: Text(deviceName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _renameDevice,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('字典管理'),
                  subtitle: const Text(
                    '品牌 / 机型 / 内存 / 颜色 / 分类 / 来源 / 渠道 / 成色',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DictManagePage(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('主题'),
                  subtitle: Text(
                    _themeName(
                      ref.watch(themeModeProvider).value ?? ThemeMode.light,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTheme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _section('数据'),
          GlassCard(
            radius: 14,
            blur: 12,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                stats.when(
                  loading: () => const ListTile(
                    title: Text('统计中…'),
                    trailing: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => ListTile(title: Text('统计失败：$e')),
                  data: (s) => Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('商品记录'),
                        trailing: Text('${s.itemCount} 件'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: const Text('图片'),
                        subtitle: Text('占 ${_size(s.imageBytes)}'),
                        trailing: Text('${s.imageCount} 张'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.storage_outlined),
                        title: const Text('数据库文件'),
                        subtitle: Text(
                          s.dirPath,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(_size(s.fileBytes)),
                        onTap: () async {
                          // 路径又长又难记，点一下就复制，能直接粘到资源管理器。
                          await Clipboard.setData(ClipboardData(text: s.dirPath));
                          if (!context.mounted) return;
                          _toast('路径已复制');
                        },
                      ),
                    ],
                  ),
                ),
                aggregate.maybeWhen(
                  data: (agg) => ListTile(
                    leading: const Icon(Icons.savings_outlined),
                    title: const Text('累计净到手'),
                    trailing: Text(
                      Money(agg.summary.netProfitCents).toYuanString(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _section('备份'),
          GlassCard(
            radius: 14,
            blur: 12,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: const Text('导出整库快照'),
                  subtitle: const Text('生成一个 .db 文件，包含全部记录和图片'),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _exporting ? null : _export,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.merge_type),
                  title: const Text('导入并合并'),
                  subtitle: const Text('选另一个设备导出的 .db，按更新时间取新的'),
                  trailing: _importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _importing ? null : _import,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.grid_on),
                  title: const Text('导出 Excel'),
                  subtitle: const Text('两个表：商品（含盈亏）+ 费用明细，可用 Excel 打开'),
                  trailing: _excelExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _excelExporting ? null : _exportExcel,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('导入 Excel'),
                  subtitle: const Text('先在表里改好，再导回来；有错一行都不写'),
                  trailing: _excelImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _excelImporting ? null : _importExcel,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _section('同步'),
          ListenableBuilder(
            listenable: ref.read(syncControllerProvider),
            builder: (context, _) {
              final sync = ref.read(syncControllerProvider);
              final peers = ref.watch(peersProvider).value ?? const <SyncState>[];
              return GlassCard(
                radius: 14,
                blur: 12,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        sync.hosting
                            ? Icons.wifi_tethering
                            : Icons.wifi_tethering_off,
                        color: sync.hosting ? scheme.primary : null,
                      ),
                      title: Text(
                        sync.hosting ? '正在等待另一台设备' : '本机作为同步主机',
                      ),
                      subtitle: Text(
                        sync.hosting
                            ? '${_addressText(sync.port)} · 配对码 ${sync.pairCode}'
                            : '配对过就会自动开着，另一台开机后能连过来',
                      ),
                      isThreeLine: sync.hosting && _ips.length > 1,
                      trailing: TextButton(
                        onPressed: () async {
                          await sync.toggleHost();
                          if (!mounted) return;
                          await _refreshIps();
                        },
                        child: Text(sync.hosting ? '停止' : '开启'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('连接另一台设备'),
                      subtitle: const Text('填对方的地址和配对码，配对后自动记住'),
                      trailing: (sync.syncing || _connecting)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: (sync.syncing || _connecting) ? null : _connectDialog,
                    ),
                    if (peers.isNotEmpty) ...[
                      const Divider(height: 1),
                      for (final peer in peers) ...[
                        ListTile(
                          leading: const Icon(Icons.devices_other),
                          title: Text(peer.peerName ?? peer.peerId),
                          subtitle: Text(
                            '${peer.peerHost ?? '?'}:${peer.peerPort ?? 8787}'
                            ' · ${_ago(peer.lastSyncAt)}',
                          ),
                          trailing: TextButton(
                            onPressed: () => _forgetPeer(peer.peerId),
                            child: const Text('解绑'),
                          ),
                        ),
                      ],
                    ],
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.autorenew),
                      title: const Text('自动同步'),
                      subtitle: const Text('改完东西就同步过去，不用手动点；连不上不打扰'),
                      value: peers.any((p) => p.autoSync == 1),
                      onChanged: _setAutoSync,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '搞个机吧 · 数据只存在本机',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
          ),
          const SizedBox(height: 32),
        ],
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  /// 主题是设备本地偏好，写 local_devices 而不是 sync_states ——
  /// 电脑上想要深色、手机上想要亮色，这是常态，不该被同步冲掉。
  Future<void> _pickTheme() async {
    final current = ref.read(themeModeProvider).value ?? ThemeMode.light;
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(switch (mode) {
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                  ThemeMode.system => Icons.brightness_auto_outlined,
                }),
                title: Text(_themeName(mode)),
                trailing: mode == current
                    ? Icon(Icons.check, color: ctx.palette.accent)
                    : null,
                onTap: () => Navigator.of(ctx).pop(mode),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final db = ref.read(databaseProvider);
    await (db.update(db.localDevices)
          ..where((t) => t.id.equals(ref.read(deviceIdProvider))))
        .write(LocalDevicesCompanion(themeMode: Value(_themeValue(picked))));
  }

  static String _themeName(ThemeMode mode) => switch (mode) {
        ThemeMode.light => '亮色',
        ThemeMode.dark => '深色',
        ThemeMode.system => '跟随系统',
      };

  static String _themeValue(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  /// 自动同步开关存在 sync_states 上（每个对端一份）。
  /// 还没配对过时没有任何行可写，直接提示去配一次。
  /// 「刚刚同步 / 3 分钟前 / 昨天」这种相对时间。
  static String _ago(DateTime? at) {
    if (at == null) return '还没同步过';
    final d = DateTime.now().difference(at);
    if (d.inSeconds < 45) return '刚刚同步';
    if (d.inMinutes < 60) return '${d.inMinutes} 分钟前';
    if (d.inHours < 24) return '${d.inHours} 小时前';
    if (d.inDays == 1) return '昨天';
    return '${d.inDays} 天前';
  }

  /// 解绑：删掉这台对端的配对记录（令牌、地址、上次时间一起没）。
  /// 对端下次连过来会被要求重新配对 —— 换手机、送人都走这条路。
  Future<void> _forgetPeer(String peerId) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.syncStates)..where((t) => t.peerId.equals(peerId))).go();
    if (!mounted) return;
    ref.invalidate(peersProvider);
    _toast('已解绑，下次需要重新配对');
  }
  Future<void> _setAutoSync(bool value) async {
    final db = ref.read(databaseProvider);
    final rows = await db.select(db.syncStates).get();
    if (rows.isEmpty) {
      _toast('还没有配对的设备，先连一次');
      return;
    }
    await db
        .update(db.syncStates)
        .write(SyncStatesCompanion(autoSync: Value(value ? 1 : 0)));
  }

  Future<void> _renameDevice() async {
    final deviceId = ref.read(deviceIdProvider);
    final current = ref.read(localDeviceProvider).value?.name ??
        ref.read(deviceNameProvider);
    final controller = TextEditingController(text: current);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设备名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例：书房的电脑'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || name == current) return;

    final db = ref.read(databaseProvider);
    await (db.update(db.localDevices)..where((t) => t.id.equals(deviceId))).write(
      LocalDevicesCompanion(name: Value(name)),
    );
    // localDeviceProvider 是 DB 流，会自动推送新名字，不需要手动 invalidate。
    ref.invalidate(dbStatsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('设备名已更新')));
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final file = await ExportService(ref.read(databaseProvider)).exportSnapshot();
      if (!mounted) return;
      setState(() => _exporting = false);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '搞个机吧备份',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('已生成：${file.path}')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    if (!mounted) return;

    if (!path.toLowerCase().endsWith('.db')) {
      _toast('请选择导出的 .db 备份文件');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('合并这个备份？'),
        content: const Text(
          '按「更新时间较新者胜」逐条合并，本地没有的记录会补进来，'
          '本地较新的记录不会被覆盖。合并前建议先导出一次当前数据。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('合并')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _importing = true);
    try {
      final report = await MergeService(ref.read(databaseProvider)).mergeFromFile(path);
      if (!mounted) return;
      setState(() => _importing = false);
      ref.invalidate(dbStatsProvider);
      ref.invalidate(profitSummaryProvider);
      _toast('合并完成：${report.describe()}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      _toast('合并失败：$e');
    }
  }

  /// 导出 Excel：两个 sheet，商品表里带盈亏四列（导出时算好，不是公式）。
  Future<void> _exportExcel() async {
    setState(() => _excelExporting = true);
    try {
      final result =
          await ExcelExportService(ref.read(databaseProvider)).exportToFile();
      if (!mounted) return;
      setState(() => _excelExporting = false);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.file.path)],
          text: '搞个机吧 · Excel 导出',
        ),
      );
      if (!mounted) return;
      _toast('${result.describe()}\n${result.file.path}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _excelExporting = false);
      _toast('导出失败：$e');
    }
  }

  /// 导入 Excel：解析 → 弹预览 → 用户确认 → 写库。
  ///
  /// 解析阶段就把所有错误收集完，有错直接摊开，不进写库流程。
  Future<void> _importExcel() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      allowMultiple: false,
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;
    if (!mounted) return;

    setState(() => _excelImporting = true);
    final db = ref.read(databaseProvider);
    final service = ExcelImportService(
      db: db,
      repository: ref.read(itemRepositoryProvider),
    );

    ExcelPreview preview;
    try {
      preview = await service.parse(bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _excelImporting = false);
      _toast('读不了这个文件：$e');
      return;
    }
    if (!mounted) return;
    setState(() => _excelImporting = false);

    if (!preview.ok) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('有 ${preview.errors.length} 处问题，一行都没写'),
          content: SingleChildScrollView(
            child: Text(
              preview.describeErrors(),
              style: const TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('好'),
            ),
          ],
        ),
      );
      return;
    }

    if (preview.itemCount == 0) {
      _toast('表里没有商品行');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入这份表？'),
        content: Text(
          '${preview.describe()}。\n\n'
          '有 id 且本地存在的按新值覆盖，id 不在本地的补进来，'
          '没有 id 的当作新记录；每件商品的费用会按表里的内容整体替换。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _excelImporting = true);
    try {
      final written = await service.apply(preview);
      if (!mounted) return;
      setState(() => _excelImporting = false);
      ref.invalidate(dbStatsProvider);
      ref.invalidate(profitSummaryProvider);
      _toast('已写入 $written 件商品、${preview.expenseCount} 条费用');
    } catch (e) {
      if (!mounted) return;
      setState(() => _excelImporting = false);
      _toast('导入失败：$e');
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}