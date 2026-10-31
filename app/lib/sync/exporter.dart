import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/db/app_database.dart';
import '../domain/app_paths.dart';

/// 手动导出：把整库做成一份自包含的 SQLite 快照。
///
/// 用 `VACUUM INTO` 而不是直接复制文件——WAL 模式下直接拷 .db 会漏掉
/// 还没 checkpoint 的页，导出的库可能少最后几条记录。
class ExportService {
  ExportService(this._db);

  final AppDatabase _db;

  Future<Directory> _targetDir() => AppPaths.exportDir();

  Future<File> exportSnapshot({DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final stamp = '${ts.year}'
        '${ts.month.toString().padLeft(2, '0')}'
        '${ts.day.toString().padLeft(2, '0')}_'
        '${ts.hour.toString().padLeft(2, '0')}'
        '${ts.minute.toString().padLeft(2, '0')}'
        '${ts.second.toString().padLeft(2, '0')}';

    final dir = await _targetDir();
    final path = p.join(dir.path, 'ggjb_backup_$stamp.db');

    if (await File(path).exists()) {
      await File(path).delete();
    }
    await _db.vacuumInto(path);
    return File(path);
  }
}
