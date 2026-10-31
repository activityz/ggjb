import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 程序自己的「家」在哪。
///
/// 需求（m03434）是「导出的文件、保存的数据都默认放到程序安装的那个文件夹」。
/// 这意味着 Windows 端不能再用 `getApplicationDocumentsDirectory()`——那是
/// 用户的「文档」目录，和程序本身没半点关系，备份时还要满硬盘去找。
///
/// 落点：
/// - **Windows**：`ggjb.exe` 同级目录 + `data\`。
///   安装包默认装到 `%LOCALAPPDATA%\Programs\ggjb`，用户对它有写权限。
///   若用户把程序手动解压到 `Program Files`，那里不可写 —— 这时不静默失败，
///   而是回落到 Documents，并由调用方把实际路径显示给用户。
/// - **Android**：应用私有外部目录（`/sdcard/Android/data/<包名>/files/`），
///   免存储权限，也能被文件管理器看到。
///
/// 数据库和导出文件放同一个目录，是为了「整个文件夹拷走就是完整备份」。
class AppPaths {
  /// 程序所在目录（Windows 是 exe 同级；Android 是私有外部目录）。
  static Directory? _home;

  /// 数据目录：数据库文件、导出的 Excel / .db 快照都在这里。
  static Future<Directory> dataDir() async {
    final home = await homeDir();
    final dir = Directory(p.join(home.path, 'data'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 导出文件目录（和数据目录同一个，方便一起拷走）。
  static Future<Directory> exportDir() async => dataDir();

  /// 程序主目录。
  static Future<Directory> homeDir() async {
    final cached = _home;
    if (cached != null) return cached;

    final dir = Platform.isWindows ? await _windowsHome() : await _mobileHome();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _home = dir;
    return dir;
  }

  /// 数据库文件完整路径。drift 直接吃这个。
  static Future<String> databasePath([String name = 'ggjb']) async {
    final dir = await dataDir();
    return p.join(dir.path, '$name.sqlite');
  }

  static Future<Directory> _windowsHome() async {
    // `Platform.resolvedExecutable` 是 exe 的真实路径（不是工作目录），
    // 用户双击哪个 exe，就落在哪个文件夹。flutter run 时它指向 build 里的
    // debug exe，所以开发期数据也在 build 目录下，不会污染 Documents。
    final exeDir = File(Platform.resolvedExecutable).parent;
    if (await _isWritable(exeDir)) return exeDir;

    // 只读位置（Program Files）：不静默失败，回落到用户文档，
    // 由设置页把真实路径显示出来。
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'ggjb'));
  }

  static Future<Directory> _mobileHome() async {
    final external = await getExternalStorageDirectory();
    if (external != null) return external;
    return getApplicationDocumentsDirectory();
  }

  /// 真正写一个探针文件来确认可写。
  ///
  /// 只看 `Directory` 的权限位不靠谱：Windows 上 ACL 和只读属性是两回事，
  /// 而 Program Files 的拒绝是访问时才发现。写一次最准。
  static Future<bool> _isWritable(Directory dir) async {
    try {
      if (!await dir.exists()) return false;
      final probe = File(p.join(dir.path, '.write_probe'));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 给设置页显示用：`C:\Users\x\AppData\Local\Programs\ggjb\data`
  static Future<String> describe() async {
    try {
      return (await dataDir()).path;
    } catch (e) {
      return '拿不到数据目录：$e';
    }
  }

  /// 把旧版本存在「应用支持目录」里的库搬到程序目录下。
  ///
  /// 1.5.0 之前用的是 `driftDatabase(name: 'ggjb')` 的默认路径
  /// （Windows 上是 `%APPDATA%\...\ggjb.sqlite`），而这一版把库改到了
  /// `exe\data\ggjb.sqlite`。**不搬的话，用户装上安装包会看到一片空白，
  /// 以为数据丢了** —— 数据其实还在旧路径上躺着。
  ///
  /// 只在「新库不存在 且 旧库存在」时搬一次；新库已存在就什么都不做，
  /// 绝不覆盖用户当前的数据。
  static Future<void> migrateLegacyIfNeeded() async {
    try {
      final targetPath = await databasePath();
      if (await File(targetPath).exists()) return;

      final support = await getApplicationSupportDirectory();
      final legacy = File(p.join(support.path, 'ggjb.sqlite'));
      if (!await legacy.exists()) return;

      final targetDir = Directory(p.dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      await legacy.copy(targetPath);

      // WAL 与 shm 必须一起搬：只拷主库会丢掉还没 checkpoint 的最近写入，
      // 用户就会觉得「最后记的几笔没了」。
      for (final suffix in const ['-wal', '-shm']) {
        final side = File('${legacy.path}$suffix');
        if (await side.exists()) {
          await side.copy('$targetPath$suffix');
        }
      }
    } catch (_) {
      // 迁移失败不该拦住启动：最多是看到空库，旧的还在原处。
    }
  }
}
