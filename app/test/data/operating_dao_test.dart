import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/operating_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:drift/native.dart';

/// seam: OperatingDao —— 运营成本不进 expenses，看板单独减。
/// 区间是半开 `[from, to)`：`to` 当天 0 点不算在内。
void main() {
  late AppDatabase db;
  late OperatingDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = OperatingDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> add(DateTime spentAt, int cents, {String? note}) => dao.insert(
    spentAt: spentAt,
    kind: 'packaging',
    amountCents: cents,
    deviceId: 'dev-test',
    note: note,
  );

  test('insert 后 watch 能取到，字段原样保留', () async {
    await add(DateTime(2026, 3, 1), 5000, note: '气泡袋');
    final rows = await dao.watch().first;
    expect(rows.single.amountCents, 5000);
    expect(rows.single.note, '气泡袋');
    expect(rows.single.kind, 'packaging');
  });

  test('区间左闭右开：to 当天 0 点的记录不算在内', () async {
    await add(DateTime(2026, 3, 1), 100);
    await add(DateTime(2026, 3, 31), 200);
    final rows = await dao
        .watch(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 31))
        .first;
    expect(rows.map((r) => r.amountCents), [100], reason: '3-31 是上界，不含');
  });

  test('from 当天 0 点的记录算在内', () async {
    await add(DateTime(2026, 3, 1), 100);
    final rows = await dao.watch(from: DateTime(2026, 3, 1)).first;
    expect(rows, hasLength(1));
  });

  test('watchTotalCents 求和，空集返回 0 而不是 null', () async {
    expect(await dao.watchTotalCents().first, 0);
    await add(DateTime(2026, 3, 1), 1500);
    await add(DateTime(2026, 3, 2), 2500);
    expect(await dao.watchTotalCents().first, 4000);
  });

  test('合计也遵守半开区间', () async {
    await add(DateTime(2026, 3, 1), 1000);
    await add(DateTime(2026, 3, 31), 9000);
    final total = await dao
        .watchTotalCents(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 31))
        .first;
    expect(total, 1000);
  });

  test('软删除后列表与合计都不再计入', () async {
    final id = await add(DateTime(2026, 3, 1), 2000);
    await add(DateTime(2026, 3, 2), 1000);
    await dao.softDelete(id);

    expect((await dao.watch().first).map((r) => r.amountCents), [1000]);
    expect(await dao.watchTotalCents().first, 1000);
  });

  test('update 改金额与备注，spentAt 也跟着变', () async {
    final id = await add(DateTime(2026, 3, 1), 2000, note: '旧');
    await dao.update(
      id: id,
      spentAt: DateTime(2026, 4, 2),
      kind: 'rent',
      amountCents: 3000,
      note: '新',
    );
    final row = (await dao.watch().first).single;
    expect(row.amountCents, 3000);
    expect(row.note, '新');
    expect(row.kind, 'rent');
    expect(row.spentAt, DateTime(2026, 4, 2));
  });

  test('列表按 spentAt 倒序，最近的在前', () async {
    await add(DateTime(2026, 3, 1), 100);
    await add(DateTime(2026, 5, 1), 300);
    await add(DateTime(2026, 4, 1), 200);
    final rows = await dao.watch().first;
    expect(rows.map((r) => r.amountCents), [300, 200, 100]);
  });
}
