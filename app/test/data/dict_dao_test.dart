import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/data/dao/dict_dao.dart';
import 'package:ggjb/data/db/app_database.dart';
import 'package:drift/native.dart';

/// seam: DictDao —— 字典是「选项池」，商品表存的是文本快照。
/// 关键行为：同名复用、软删除不可见、排序号能整段重排。
void main() {
  late AppDatabase db;
  late DictDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // AppDatabase 建库时会写入字典种子数据，测试要的是干净的表
    await db.customSelect('SELECT 1').get();
    await db.customStatement('DELETE FROM dict_entries');
    dao = DictDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> add(String kind, String label, {String? parentId}) =>
      dao.insert(
        kind: kind,
        label: label,
        deviceId: 'dev-test',
        parentId: parentId,
      );

  test('insert 会去掉首尾空白并返回新 id', () async {
    final id = await add('brand', '  Apple  ');
    expect(id, isNotEmpty);
    final list = await dao.allOfKind('brand');
    expect(list.single.label, 'Apple');
  });

  test('空名称直接抛 ArgumentError，不写库', () async {
    await expectLater(add('brand', '   '), throwsA(isA<ArgumentError>()));
    expect(await dao.allOfKind('brand'), isEmpty);
  });

  test('同名同父已存在时复用同一个 id，不产生重复项', () async {
    final first = await add('brand', 'Apple');
    final second = await add('brand', 'Apple');
    expect(second, first);
    expect((await dao.allOfKind('brand')).length, 1);
  });

  test('不同父项下可以有同名子项', () async {
    final apple = await add('brand', 'Apple');
    final xiaomi = await add('brand', 'Xiaomi');
    await add('model', 'Pro', parentId: apple);
    await add('model', 'Pro', parentId: xiaomi);

    final underApple = await dao.allOfKind('model', parentId: apple);
    expect(underApple.single.parentId, apple);
    expect(await dao.allOfKind('model'), hasLength(2));
  });

  test('watchKind 按 parentId 过滤，只出挂在该父项下的', () async {
    final apple = await add('brand', 'Apple');
    final xiaomi = await add('brand', 'Xiaomi');
    await add('model', 'iPhone 15', parentId: apple);
    await add('model', 'Redmi K70', parentId: xiaomi);

    final rows = await dao.watchKind('model', parentId: apple).first;
    expect(rows.map((e) => e.label), ['iPhone 15']);
  });

  test('watchKindUnderLabel 用父项文本反查，父项被改名后过滤不到', () async {
    final apple = await add('brand', 'Apple');
    await add('model', 'iPhone 15', parentId: apple);

    final before = await dao
        .watchKindUnderLabel('model', parentKind: 'brand', parentLabel: 'Apple')
        .first;
    expect(before.map((e) => e.label), ['iPhone 15']);

    await dao.rename(apple, 'Apple 中国', now: DateTime(2026, 1, 2));
    final after = await dao
        .watchKindUnderLabel('model', parentKind: 'brand', parentLabel: 'Apple')
        .first;
    expect(after, isEmpty, reason: '已知取舍：宁可漏过滤也不存字典外键');
  });

  test('rename 只改字典项，不回写已存在的商品文本快照', () async {
    final id = await add('brand', 'Apple');
    await dao.rename(id, '苹果', now: DateTime(2026, 1, 2));
    expect((await dao.allOfKind('brand')).single.label, '苹果');
  });

  test('rename 空名称抛 ArgumentError', () async {
    final id = await add('brand', 'Apple');
    await expectLater(
      dao.rename(id, '  ', now: DateTime(2026, 1, 2)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('reorder 把排序号整段重写成 0..n-1', () async {
    await add('brand', 'A');
    await add('brand', 'B');
    await add('brand', 'C');

    final rows = await dao.allOfKind('brand');
    final reversed = rows.reversed.toList();
    await dao.reorder(reversed);

    final after = await dao.allOfKind('brand');
    expect(after.map((e) => e.label), ['C', 'B', 'A']);
    expect(after.map((e) => e.sortOrder), [0, 1, 2]);
  });

  test('softDelete 后 watchKind 与 allOfKind 都不再出现', () async {
    final id = await add('brand', 'Apple');
    await dao.softDelete(id, now: DateTime(2026, 1, 2));
    expect(await dao.allOfKind('brand'), isEmpty);
    expect(await dao.watchKind('brand').first, isEmpty);
    expect(await dao.all(), isEmpty);
  });

  test('软删除写的是墓碑，不是物理删除（同步靠它传播）', () async {
    final id = await add('brand', 'Apple');
    await dao.softDelete(id, now: DateTime(2026, 1, 2));
    final raw = await db.select(db.dictEntries).get();
    expect(raw.single.id, id);
    expect(raw.single.deletedAt, isNotNull);
  });

  test('idOfLabel 反查 id，找不到返回 null', () async {
    final id = await add('brand', 'Apple');
    expect(await dao.idOfLabel('brand', 'Apple'), id);
    expect(await dao.idOfLabel('brand', 'Nokia'), isNull);
    expect(await dao.idOfLabel('model', 'Apple'), isNull, reason: '种类不同不算');
  });

  test('watchAll 跨种类返回，按 kind 再按排序号', () async {
    await add('brand', 'Apple');
    await add('color', '黑色');
    final all = await dao.watchAll().first;
    expect(all.map((e) => e.kind), ['brand', 'color']);
  });
}
