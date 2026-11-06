import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../app/providers.dart';
import '../../sync/auto_sync.dart';
import '../../sync/sync_controller.dart';
import '../../ui/particles.dart';
import '../dashboard/dashboard_page.dart';
import '../item_list/item_list_page.dart';
import '../scan/scan_entry_button.dart';
import '../settings/settings_page.dart';

/// 主骨架：窄屏走底部导航，宽屏（Windows）走左侧 NavigationRail。
///
/// 顶栏放在这里而不是各页里，因为同步是全局的事 —— 不管用户当前在哪一页
/// 改完东西，都该能立刻点「同步」并看到结果，而不是先切回看板。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  bool _burst = false;
  bool _attachStarted = false;

  /// 同一次同步结果只炸一次粒子（controller 每次状态变化都会 notify）。
  AutoSyncResult? _lastBurstFor;

  late final SyncController _sync = ref.read(syncControllerProvider);

  static const _titles = <String>['看板', '明细', '设置'];

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncChanged);

    // 首帧之后才接线：监听表更新、已配对则自动开监听端口、启动同步一次。
    // 放 microtask 里不占首帧。
    Future<void>.microtask(_attach);
  }

  Future<void> _attach() async {
    if (_attachStarted) return;
    _attachStarted = true;

    await _sync.attach();
    if (!mounted) return;

    // 只有「版本不一致 / 令牌失效」才弹提示 —— 没配对、不在同一局域网
    // 都属于正常情况，每次都弹就变成噪音了。
    final result = _sync.lastResult;
    if (result != null && result.shouldNotify) {
      _toast(result.describe());
    }
  }

  void _onSyncChanged() {
    final result = _sync.lastResult;
    if (result == null || !result.ok || _sync.syncing) return;
    if (identical(result, _lastBurstFor)) return;
    _lastBurstFor = result;
    if (!mounted) return;
    setState(() => _burst = true);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _burst = false);
    });
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _syncNow() async {
    final result = await _sync.syncNow();
    if (!mounted || result == null) return;
    if (result.ok) {
      _toast(result.describe());
    } else if (result.status != AutoSyncStatus.noPeer || result.message != null) {
      // 手动点按钮就必须有反馈，哪怕是「连不上」。
      _toast(result.describe());
    }
  }

  void _refreshAll() {
    ref.invalidate(profitSummaryProvider);
    ref.invalidate(categoryStatsProvider);
    ref.invalidate(platformStatsProvider);
    ref.invalidate(itemListProvider);
    ref.invalidate(peersProvider);
    _toast('已重新读取');
  }

  PreferredSizeWidget _buildAppBar(AppPalette p) {
    return AppBar(
      title: Text(_titles[_index]),
      actions: <Widget>[
        const ScanEntryButton(),
        ListenableBuilder(
          listenable: _sync,
          builder: (context, _) {
            final syncing = _sync.syncing;
            return IconButton(
              tooltip: syncing ? '正在同步…' : '立即同步（${_sync.lastSyncLabel}）',
              onPressed: syncing ? null : _syncNow,
              icon: syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
            );
          },
        ),
        IconButton(
          tooltip: '重新读取',
          onPressed: _refreshAll,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  static const _pages = <Widget>[
    DashboardPage(),
    ItemListPage(),
    SettingsPage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: '看板',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: '明细',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: '设置',
    ),
  ];

  static const _railDestinations = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: Text('看板'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('明细'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('设置'),
    ),
  ];

  Widget _body() {
    final pages = IndexedStack(index: _index, children: _pages);
    // 粒子挂在 body 最外层而不是某一页里：同步是全局动作，
    // 在明细页改完价也能看到「同步上了」的那一下。
    return Stack(
      children: <Widget>[
        Positioned.fill(child: pages),
        if (_burst)
          const Positioned.fill(child: IgnorePointer(child: ParticleBurst())),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final indicator = p.accent.withValues(alpha: p.glass ? 0.18 : 0.14);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;

        if (!wide) {
          final bar = NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: p.cardFill,
            surfaceTintColor: Colors.transparent,
            indicatorColor: indicator,
            destinations: _destinations,
          );
          return Scaffold(
            appBar: _buildAppBar(p),
            body: _body(),
            // 底栏做成玻璃：页面内容从它下面透出来，滚动时才有「层」的感觉。
            // 亮色下不模糊 —— 白底模糊后只是变灰，反而糊掉内容。
            bottomNavigationBar: p.glass
                ? ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: bar,
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.cardFill,
                      border: Border(top: BorderSide(color: p.divider)),
                    ),
                    child: bar,
                  ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(p),
          body: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: p.cardFill,
                indicatorColor: indicator,
                destinations: _railDestinations,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _body()),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncChanged);
    super.dispose();
  }
}
