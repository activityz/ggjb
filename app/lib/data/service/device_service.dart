import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// 维护本机身份。整个库里 [LocalDevices] 只能有一行。
///
/// 这个 id 会写进每条记录的 `device_id`，是同步冲突「谁的更新更新」的
/// 决胜平局判据，所以一旦生成就永不改变。
class DeviceService {
  DeviceService(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  Future<LocalDevice> ensure() async {
    final existing = await _db.select(_db.localDevices).getSingleOrNull();
    if (existing != null) return existing;

    final now = DateTime.now();
    final device = LocalDevice(
      id: _uuid.v4(),
      name: _defaultName(),
      createdAt: now,
      themeMode: 'light',
    );
    await _db.into(_db.localDevices).insert(
          LocalDevicesCompanion.insert(
            id: device.id,
            name: device.name,
            createdAt: now,
          ),
        );
    return device;
  }

  Future<void> rename(String id, String name) async {
    await (_db.update(_db.localDevices)..where((t) => t.id.equals(id)))
        .write(LocalDevicesCompanion(name: Value(name)));
  }

  static String _defaultName() {
    if (Platform.isWindows) return 'Windows 电脑';
    if (Platform.isAndroid) return 'Android 手机';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isLinux) return 'Linux';
    return '本机';
  }
}
