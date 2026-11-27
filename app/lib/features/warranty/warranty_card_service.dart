import 'package:drift/drift.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../data/dao/attachment_dao.dart';
import '../../data/db/app_database.dart';
import '../../domain/enums.dart';

/// 保修卡图片的存取。
///
/// 存进 `attachments` 表而不是文件系统：图片随商品一起同步、一起级联删除，
/// 换机器不用搬目录；角色用 `warranty_card`，和买入图/铭牌照片共用一张表。
///
/// 同一商品只保留最新一张：生成前把旧的软删。软删而非物理删，
/// 是为了让「这张卡没了」这个事实也能同步到另一台设备。
class WarrantyCardService {
  WarrantyCardService({
    required AppDatabase db,
    required AttachmentDao attachments,
    required String deviceId,
    Uuid? uuid,
  }) : _db = db,
       _attachments = attachments,
       _deviceId = deviceId,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final AttachmentDao _attachments;
  final String _deviceId;
  final Uuid _uuid;

  /// 最新一张保修卡（没有则 null）。
  Future<Attachment?> latest(String itemId) async {
    final query = _db.select(_db.attachments)
      ..where(
        (t) =>
            t.itemId.equals(itemId) &
            t.role.equalsValue(AttachmentRole.warrantyCard) &
            t.deletedAt.isNull(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  /// 缩略图长边上限。卡面原图 1080×1620，缩到长边 256 约 171×256，
  /// 详情页 84px 的格子里绰绰有余，单张十几 KB。
  static const int thumbMaxEdge = 256;

  /// 由卡面 PNG 生成缩略图。
  ///
  /// 不写 thumb 的后果是实打实的：详情页图片模块只认缩略图，列里为空的
  /// 时候它拿不到任何东西，就会一直转圈（用户报的就是这个）。
  /// 解不开的字节返回 null —— 宁可少一个缩略图，也不能让保存失败。
  Uint8List? _buildThumb(Uint8List png) {
    img.Image? decoded;
    try {
      decoded = img.decodePng(png);
    } catch (_) {
      // 字节坏了 / 不是 PNG：宁可没有缩略图，也不能让保存整体失败
      return null;
    }
    if (decoded == null) return null;
    final landscape = decoded.width >= decoded.height;
    if ((landscape ? decoded.width : decoded.height) <= thumbMaxEdge) {
      return png;
    }
    final resized = landscape
        ? img.copyResize(decoded, width: thumbMaxEdge)
        : img.copyResize(decoded, height: thumbMaxEdge);
    return Uint8List.fromList(img.encodePng(resized));
  }

  /// 保存一张新卡，并把旧的软删。整套在一个事务里，避免留下两张有效卡。
  Future<String> save(
    String itemId,
    Uint8List png, {
    int width = 1080,
    int height = 1620,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final thumb = _buildThumb(png);

    await _db.transaction(() async {
      final stale = await (_db.select(_db.attachments)..where(
            (t) =>
                t.itemId.equals(itemId) &
                t.role.equalsValue(AttachmentRole.warrantyCard) &
                t.deletedAt.isNull(),
          ))
          .get();
      for (final row in stale) {
        await _attachments.softDelete(row.id, now: now);
      }

      await _attachments.insert(
        AttachmentsCompanion.insert(
          id: id,
          itemId: itemId,
          role: AttachmentRole.warrantyCard,
          mime: Value('image/png'),
          bytes: png,
          thumb: thumb == null ? const Value.absent() : Value(thumb),
          width: Value(width),
          height: Value(height),
          sizeBytes: Value(png.length),
          createdAt: now,
          updatedAt: now,
          deviceId: _deviceId,
        ),
      );
    });

    return id;
  }

  /// 重置：把该商品的保修卡全部软删。商家保修日期不动，用户可以改完再生成。
  Future<int> reset(String itemId) async {
    final now = DateTime.now();
    final rows = await (_db.select(_db.attachments)..where(
          (t) =>
              t.itemId.equals(itemId) &
              t.role.equalsValue(AttachmentRole.warrantyCard) &
              t.deletedAt.isNull(),
        ))
        .get();
    for (final row in rows) {
      await _attachments.softDelete(row.id, now: now);
    }
    return rows.length;
  }
}
