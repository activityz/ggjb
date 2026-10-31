import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/app_database.dart';

/// 附件读写。列表页只读 [thumb]，详情页才读 [bytes]。
class AttachmentDao {
  AttachmentDao(this._db);

  final AppDatabase _db;

  /// 某件商品的所有附件**元数据**（不含大 BLOB）。
  Future<List<AttachmentMeta>> listMeta(String itemId) async {
    final query = _db.selectOnly(_db.attachments)
      ..addColumns([
        _db.attachments.id,
        _db.attachments.itemId,
        _db.attachments.role,
        _db.attachments.mime,
        _db.attachments.width,
        _db.attachments.height,
        _db.attachments.sizeBytes,
        _db.attachments.createdAt,
      ])
      ..where(
        _db.attachments.itemId.equals(itemId) &
            _db.attachments.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm(expression: _db.attachments.createdAt)]);

    final rows = await query.get();
    return rows
        .map(
          (row) => AttachmentMeta(
            id: row.read(_db.attachments.id)!,
            itemId: row.read(_db.attachments.itemId)!,
            role: row.readWithConverter(_db.attachments.role)!,
            mime: row.read(_db.attachments.mime)!,
            width: row.read(_db.attachments.width),
            height: row.read(_db.attachments.height),
            sizeBytes: row.read(_db.attachments.sizeBytes)!,
            createdAt: row.read(_db.attachments.createdAt)!,
          ),
        )
        .toList(growable: false);
  }

  /// 缩略图（详情页网格用）。
  Future<Uint8List?> thumbOf(String attachmentId) async {
    final row = await (_db.selectOnly(_db.attachments)
          ..addColumns([_db.attachments.thumb])
          ..where(_db.attachments.id.equals(attachmentId)))
        .getSingleOrNull();
    return row?.read(_db.attachments.thumb);
  }

  /// 原图。
  Future<Uint8List?> bytesOf(String attachmentId) async {
    final row = await (_db.selectOnly(_db.attachments)
          ..addColumns([_db.attachments.bytes])
          ..where(_db.attachments.id.equals(attachmentId)))
        .getSingleOrNull();
    return row?.read(_db.attachments.bytes);
  }

  Future<void> insert(AttachmentsCompanion companion) =>
      _db.into(_db.attachments).insert(companion);

  Future<void> softDelete(String id, {required DateTime now}) =>
      (_db.update(_db.attachments)..where((t) => t.id.equals(id))).write(
        AttachmentsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  /// 图片只作为元数据参与主同步，字节走独立通道按需拉。
  Future<List<AttachmentsCompanion>> allForSync({DateTime? since}) async {
    final query = _db.select(_db.attachments);
    if (since != null) {
      query.where((t) => t.updatedAt.isBiggerThanValue(since));
    }
    final rows = await query.get();
    return rows
        .map(
          (r) => AttachmentsCompanion(
            id: Value(r.id),
            itemId: Value(r.itemId),
            role: Value(r.role),
            mime: Value(r.mime),
            width: Value(r.width),
            height: Value(r.height),
            sizeBytes: Value(r.sizeBytes),
            createdAt: Value(r.createdAt),
            updatedAt: Value(r.updatedAt),
            deletedAt: Value(r.deletedAt),
            deviceId: Value(r.deviceId),
          ),
        )
        .toList(growable: false);
  }
}

/// 不含 BLOB 的附件信息。
class AttachmentMeta {
  const AttachmentMeta({
    required this.id,
    required this.itemId,
    required this.role,
    required this.mime,
    required this.sizeBytes,
    required this.createdAt,
    this.width,
    this.height,
  });

  final String id;
  final String itemId;
  final AttachmentRole role;
  final String mime;
  final int? width;
  final int? height;
  final int sizeBytes;
  final DateTime createdAt;
}
