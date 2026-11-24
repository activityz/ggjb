import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/attachment_dao.dart';
import 'package:ggjb/data/dao/item_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:ggjb/data/exchange/excel_export.dart';
import 'package:ggjb/data/exchange/excel_import.dart';
import 'package:ggjb/data/exchange/excel_rows.dart';
import 'package:ggjb/data/repo/item_repository.dart';
import 'package:ggjb/domain/enums.dart';

/// seam: 序列号与商家保修两列的 Excel 往返，以及旧表头的兼容。
///
/// 「旧表头还能导」是硬要求：上一版导出过的文件散落在用户电脑里，
/// 升级一次就让它们导不进来，等于把历史数据锁死。
void main() {
  late AppDatabase src;
  late AppDatabase dst;

  setUp(() {
    src = AppDatabase(NativeDatabase.memory());
    dst = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await src.close();
    await dst.close();
  });

  ExcelImportService serviceOn(AppDatabase db) => ExcelImportService(
    db: db,
    repository: ItemRepository(
      db: db,
      itemDao: ItemDao(db),
      attachmentDao: AttachmentDao(db),
      deviceId: 'dev-dst',
    ),
  );

  Future<void> put(
    AppDatabase db,
    String id, {
    required String title,
    String? serial,
    DateTime? merchantStart,
    DateTime? merchantEnd,
    WarrantyStatus status = WarrantyStatus.none,
    DateTime? start,
    DateTime? end,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db.into(db.items).insert(
      ItemsCompanion.insert(
        id: id,
        title: title,
        buyPriceCents: 300000,
        createdAt: at,
        updatedAt: at,
        deviceId: 'dev-src',
        status: const Value(ItemStatus.sold),
        sellPriceCents: const Value(480000),
        serial: Value(serial),
        merchantWarrantyStart: Value(merchantStart),
        merchantWarrantyEnd: Value(merchantEnd),
        warrantyStatus: Value(status),
        warrantyStart: Value(start),
        warrantyEnd: Value(end),
      ),
    );
  }

  Future<Item> rowOf(AppDatabase db, String id) =>
      (db.select(db.items)..where((t) => t.id.equals(id))).getSingle();

  List<CellValue?> headerRow(List<String> headers) =>
      headers.map((h) => TextCellValue(h) as CellValue?).toList();

  Uint8List buildBook({
    required List<String> headers,
    required List<Map<String, String>> rows,
  }) {
    final book = Excel.createExcel();
    final def = book.getDefaultSheet();
    if (def != null && def != ExcelSchema.sheetItems) {
      book.rename(def, ExcelSchema.sheetItems);
    }
    book.appendRow(ExcelSchema.sheetItems, headerRow(headers));
    for (final values in rows) {
      book.appendRow(
        ExcelSchema.sheetItems,
        headers
            .map(
              (h) => (values[h] ?? '').isEmpty
                  ? null
                  : TextCellValue(values[h]!) as CellValue?,
            )
            .toList(),
      );
    }
    book.appendRow(
      ExcelSchema.sheetExpenses,
      headerRow(ExcelSchema.expenseHeaders),
    );
    return Uint8List.fromList(book.save()!);
  }

  /// 上一版导出的表头：三列保修叫旧名字，且没有序列号与商家保修。
  List<String> legacyHeaders() => ExcelSchema.itemHeaders
      .where(
        (h) =>
            h != ExcelSchema.serial &&
            h != ExcelSchema.merchantWarrantyStart &&
            h != ExcelSchema.merchantWarrantyEnd,
      )
      .map(
        (h) => switch (h) {
          ExcelSchema.warrantyStatus => '保修状态',
          ExcelSchema.warrantyStart => '保修开始',
          ExcelSchema.warrantyEnd => '保修到期',
          _ => h,
        },
      )
      .toList();

  test('导出表头含序列号与商家保修两列，厂家保修改用新名', () {
    expect(ExcelSchema.itemHeaders, contains('序列号'));
    expect(ExcelSchema.itemHeaders, contains('商家保修开始'));
    expect(ExcelSchema.itemHeaders, contains('商家保修到期'));
    expect(ExcelSchema.itemHeaders, contains('厂家保修状态'));
    expect(ExcelSchema.itemHeaders, contains('厂家保修开始'));
    expect(ExcelSchema.itemHeaders, contains('厂家保修到期'));
    expect(ExcelSchema.itemHeaders, isNot(contains('保修状态')));
  });

  test('新表头导出再导入：序列号与商家保修往返不掉', () async {
    await put(
      src,
      'm1',
      title: '保修卡机',
      serial: 'SN-ABC123',
      merchantStart: DateTime(2026, 11, 24),
      merchantEnd: DateTime(2027, 11, 24),
    );

    final bytes = await ExcelExportService(src).buildBytes();
    final service = serviceOn(dst);
    final preview = await service.parse(Uint8List.fromList(bytes));
    expect(preview.errors, isEmpty);
    await service.apply(preview);

    final saved = await rowOf(dst, 'm1');
    expect(saved.serial, 'SN-ABC123');
    expect(saved.merchantWarrantyStart, DateTime(2026, 11, 24));
    expect(saved.merchantWarrantyEnd, DateTime(2027, 11, 24));
  });

  test('旧表头仍被读成厂家保修，且不因缺新列报错', () async {
    final bytes = buildBook(
      headers: legacyHeaders(),
      rows: [
        {
          ExcelSchema.title: '老表机',
          ExcelSchema.buyPrice: '1000',
          '保修状态': '在保',
          '保修开始': '2025-03-01',
          '保修到期': '2026-03-01',
        },
      ],
    );

    final service = serviceOn(dst);
    final preview = await service.parse(bytes);
    expect(preview.errors, isEmpty);
    await service.apply(preview);

    final saved = await (dst.select(dst.items)
          ..where((t) => t.title.equals('老表机')))
        .getSingle();
    expect(saved.warrantyStatus, WarrantyStatus.active);
    expect(saved.warrantyStart, DateTime(2025, 3, 1));
    expect(saved.warrantyEnd, DateTime(2026, 3, 1));
    expect(saved.serial, isNull);
    expect(saved.merchantWarrantyStart, isNull);
    expect(saved.merchantWarrantyEnd, isNull);
  });

  test('新表头的厂家保修列也能被读回', () async {
    final bytes = buildBook(
      headers: ExcelSchema.itemHeaders,
      rows: [
        {
          ExcelSchema.title: '新表机',
          ExcelSchema.buyPrice: '2000',
          ExcelSchema.warrantyStatus: '已过保',
          ExcelSchema.serial: 'SN-XYZ',
          ExcelSchema.merchantWarrantyStart: '2026-11-24',
          ExcelSchema.merchantWarrantyEnd: '2027-11-24',
        },
      ],
    );

    final service = serviceOn(dst);
    final preview = await service.parse(bytes);
    expect(preview.errors, isEmpty);
    await service.apply(preview);

    final saved = await (dst.select(dst.items)
          ..where((t) => t.title.equals('新表机')))
        .getSingle();
    expect(saved.warrantyStatus, WarrantyStatus.expired);
    expect(saved.serial, 'SN-XYZ');
    expect(saved.merchantWarrantyStart, DateTime(2026, 11, 24));
    expect(saved.merchantWarrantyEnd, DateTime(2027, 11, 24));
  });

  test('商家保修日期写坏时按行报错，不静默丢弃', () async {
    final bytes = buildBook(
      headers: ExcelSchema.itemHeaders,
      rows: [
        {
          ExcelSchema.title: '坏日期机',
          ExcelSchema.buyPrice: '1000',
          ExcelSchema.merchantWarrantyStart: '不是日期',
        },
      ],
    );

    final preview = await serviceOn(dst).parse(bytes);
    expect(preview.errors, isNotEmpty);
  });
}
