import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/theme.dart';
import 'data/db/app_database.dart';
import 'data/service/device_service.dart';
import 'domain/app_paths.dart';
import 'features/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 数据库跟着程序走：放在 exe 同级的 data\ 里，而不是用户的「文档」目录。
  // 这样整个程序文件夹拷到另一台机器、或者拷进 U 盘，数据就一起走了。
  //
  // 但 1.5.0 之前库在「应用支持目录」里，所以先尝试搬一次 —— 不搬的话，
  // 老用户装上安装包会看到空白，以为数据全丢了。
  await AppPaths.migrateLegacyIfNeeded();

  final db = AppDatabase(
    driftDatabase(
      name: 'ggjb',
      native: DriftNativeOptions(
        databasePath: () => AppPaths.databasePath(),
      ),
    ),
  );
  final device = await DeviceService(db).ensure();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        deviceIdProvider.overrideWithValue(device.id),
        deviceNameProvider.overrideWithValue(device.name),
      ],
      child: const GgjbApp(),
    ),
  );
}

class GgjbApp extends ConsumerWidget {
  const GgjbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 先读库再开屏：拿不到就用亮色兜底。这里不用 loading 骨架，
    // 因为 local_devices 只有一行、读它比一帧还快，闪一下骨架更难受。
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.light;

    return MaterialApp(
      title: '搞个机吧',
      debugShowCheckedModeBanner: false,
      // 日期选择器、对话框按钮、复制粘贴菜单的语言都归本地化代理管。
      // 只挂 zh_CN 一种：这是自用工具，不需要跟随系统语言切换 ——
      // 真跟着系统走，Windows 上如果装的是英文系统，日期弹窗又会变回英文。
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN')],
      locale: const Locale('zh', 'CN'),
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: mode,
      home: const HomeShell(),
    );
  }
}
