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

/// seam: Excel 三列保修字段的导出与导入。
///
/// 老表（没有这三列）必须照样导得进来：导入按表头名找列，缺列当「没填」，
/// 不能因为升级过一次就要求用户重下新模板。
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
    WarrantyStatus status = WarrantyStatus.none,
    DateTime? start,
    DateTime? end,
  }) async {
    final at = DateTime(2026, 1, 1, 12);
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: id,
            title: title,
            buyPriceCents: 300000,
            createdAt: at,
            updatedAt: at,
            deviceId: 'dev-src',
            status: const Value(ItemStatus.inStock),
            warrantyStatus: Value(status),
            warrantyStart: Value(start),
            warrantyEnd: Value(end),
          ),
        );
  }

  List<CellValue?> headerRow(List<String> headers) =>
      headers.map((h) => TextCellValue(h) as CellValue?).toList();

  Uint8List buildBook({
    List<String>? headers,
    required List<Map<String, String>> rows,
  }) {
    final book = Excel.createExcel();
    final def = book.getDefaultSheet();
    if (def != null && def != ExcelSchema.sheetItems) {
      book.rename(def, ExcelSchema.sheetItems);
    }
    final useHeaders = headers ?? ExcelSchema.itemHeaders;
    book.appendRow(ExcelSchema.sheetItems, headerRow(useHeaders));
    for (final values in rows) {
      book.appendRow(
        ExcelSchema.sheetItems,
        useHeaders
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

  test('导出再导入：在保状态与两个日期往返不掉', () async {
    await put(
      src,
      'w1',
      title: '在保机',
      status: WarrantyStatus.active,
      start: DateTime(2025, 3, 1),
      end: DateTime(2026, 3, 1),
    );
    await put(src, 'w2', title: '老机器', status: WarrantyStatus.expired);

    final bytes = await ExcelExportService(src).buildBytes();
    final service = serviceOn(dst);
    final preview = await service.parse(Uint8List.fromList(bytes));
    expect(preview.errors, isEmpty);
    await service.apply(preview);

    final rows = await dst.select(dst.items).get();
    final active = rows.firstWhere((r) => r.id == 'w1');
    expect(active.warrantyStatus, WarrantyStatus.active);
    expect(active.warrantyStart, DateTime(2025, 3, 1));
    expect(active.warrantyEnd, DateTime(2026, 3, 1));

    final expired = rows.firstWhere((r) => r.id == 'w2');
    expect(expired.warrantyStatus, WarrantyStatus.expired);
    expect(expired.warrantyStart, isNull);
    expect(expired.warrantyEnd, isNull);
  });

  test('旧表没有保修三列：照样导入成功，状态是无保修', () async {
    final bytes = buildBook(
      headers: const [
        ExcelSchema.id,
        ExcelSchema.title,
        ExcelSchema.buyPrice,
      ],
      rows: [
        {
          ExcelSchema.id: 'old-1',
          ExcelSchema.title: '没有保修列的老表',
          ExcelSchema.buyPrice: '1000',
        },
      ],
    );

    final service = serviceOn(dst);
    final preview = await service.parse(bytes);
    expect(preview.ok, isTrue, reason: preview.describeErrors());
    await service.apply(preview);

    final row = (await dst.select(dst.items).get()).single;
    expect(row.warrantyStatus, WarrantyStatus.none);
    expect(row.warrantyStart, isNull);
    expect(row.warrantyEnd, isNull);
  });

  test('状态不是「在保」的行，哪怕表里填了日期也不收', () async {
    final bytes = buildBook(
      rows: [
        {
          ExcelSchema.id: 'e1',
          ExcelSchema.title: '已过保的机器',
          ExcelSchema.buyPrice: '2000',
          ExcelSchema.status: '在库',
          '保修状态': '已过保',
          '保修开始': '2024-01-01',
          '保修到期': '2025-01-01',
        },
      ],
    );

    final service = serviceOn(dst);
    final preview = await service.parse(bytes);
    expect(preview.ok, isTrue, reason: preview.describeErrors());
    await service.apply(preview);

    final row = (await dst.select(dst.items).get()).single;
    expect(row.warrantyStatus, WarrantyStatus.expired);
    expect(row.warrantyStart, isNull, reason: '非在保的日期一律丢弃');
    expect(row.warrantyEnd, isNull);
  });

  test('中文标签与库内文本都认', () async {
    final bytes = buildBook(
      rows: [
        {
          ExcelSchema.id: 'a1',
          ExcelSchema.title: '标签写法',
          ExcelSchema.buyPrice: '2000',
          '保修状态': '在保',
          '保修开始': '2025-06-01',
        },
        {
          ExcelSchema.id: 'a2',
          ExcelSchema.title: '原始值写法',
          ExcelSchema.buyPrice: '2000',
          '保修状态': 'active',
          '保修开始': '2025/06/01',
        },
      ],
    );

    final service = serviceOn(dst);
    final preview = await service.parse(bytes);
    expect(preview.ok, isTrue, reason: preview.describeErrors());
    await service.apply(preview);

    final rows = await dst.select(dst.items).get();
    for (final row in rows) {
      expect(row.warrantyStatus, WarrantyStatus.active);
      expect(row.warrantyStart, DateTime(2025, 6, 1));
    }
  });
}
