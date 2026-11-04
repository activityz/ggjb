import 'package:flutter_test/flutter_test.dart';
import 'package:ggjb/domain/dict_seeds.dart';

void main() {
  group('DictSeeds 结构', () {
    test('9 类字典都有中文名且 kind 唯一', () {
      expect(DictSeeds.kinds.length, 9);
      final ids = DictSeeds.kinds.map((e) => e.kind).toSet();
      expect(ids.length, DictSeeds.kinds.length);
      for (final k in DictSeeds.kinds) {
        expect(k.kind, isNotEmpty);
        expect(k.label, isNotEmpty);
      }
    });

    test('kindLabel 认得每一类，未知值兜底不抛', () {
      for (final k in DictSeeds.kinds) {
        expect(DictSeeds.kindLabel(k.kind), k.label);
      }
      expect(DictSeeds.kindLabel('nope'), isNotEmpty);
    });

    test('常量与 kinds 里的 kind 值一一对应', () {
      final declared = {
        DictSeeds.kindBrand,
        DictSeeds.kindModel,
        DictSeeds.kindStorage,
        DictSeeds.kindColor,
        DictSeeds.kindCategory,
        DictSeeds.kindSource,
        DictSeeds.kindPlatform,
        DictSeeds.kindCondition,
        DictSeeds.kindOperating,
      };
      expect(declared.length, DictSeeds.kinds.length);
      expect(declared, DictSeeds.kinds.map((e) => e.kind).toSet());
    });
  });

  group('DictSeeds 数据', () {
    test('扁平列表覆盖除品牌机型外的 7 类，且每类非空', () {
      expect(DictSeeds.flatKinds.length, 7);
      for (final group in DictSeeds.flatKinds) {
        expect(group.items, isNotEmpty, reason: '${group.kind} 不能为空');
      }
      final flatKinds = DictSeeds.flatKinds.map((e) => e.kind).toSet();
      expect(flatKinds.contains(DictSeeds.kindBrand), isFalse);
      expect(flatKinds.contains(DictSeeds.kindModel), isFalse);
    });

    test('每一类内部没有重复项', () {
      for (final group in DictSeeds.flatKinds) {
        final labels = group.items;
        expect(
          labels.toSet().length,
          labels.length,
          reason: '${group.kind} 里有重复项',
        );
      }
    });

    test('每个品牌都没有重复机型', () {
      for (final entry in DictSeeds.brandModels.entries) {
        final models = entry.value;
        expect(
          models.toSet().length,
          models.length,
          reason: '${entry.key} 有重复机型',
        );
      }
    });

    test('品牌表非空，常见品牌都在', () {
      expect(DictSeeds.brandModels, isNotEmpty);
      expect(DictSeeds.brandModels.containsKey('Apple'), isTrue);
      expect(DictSeeds.brandModels.containsKey('华为'), isTrue);
      expect(DictSeeds.brandModels.containsKey('小米'), isTrue);
      expect(DictSeeds.brandModels['Apple'], isNotEmpty);
    });

    test('内存规格覆盖小容量到大容量', () {
      expect(DictSeeds.storages, contains('8+256'));
      expect(DictSeeds.storages, contains('12+512'));
      expect(DictSeeds.storages.any((e) => e.contains('1T')), isTrue);
    });
  });

  group(' seeding id 确定性', () {
    test('同一 kind + label 每次算出的 id 相同', () {
      // 与 AppDatabase._seedDicts 里的拼法保持一致：seed|kind|label
      String idOf(String kind, String label) => 'seed|$kind|$label';

      expect(
        idOf(DictSeeds.kindBrand, 'Apple'),
        idOf(DictSeeds.kindBrand, 'Apple'),
      );
      expect(
        idOf(DictSeeds.kindStorage, '8+256'),
        'seed|storage|8+256',
      );
    });

    test('7 类扁平数据的 id 全局唯一', () {
      final ids = <String>{};
      for (final group in DictSeeds.flatKinds) {
        for (final label in group.items) {
          expect(
            ids.add('seed|${group.kind}|$label'),
            isTrue,
            reason: '${group.kind}/$label 的 id 撞了',
          );
        }
      }
    });
  });
}
