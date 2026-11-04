/// 内置字典数据（8 类）。
///
/// 只在新库创建或 schema 升级到 v2 时灌入一次，之后这些行就是普通记录，
/// 用户可以改、可以删、可以加 —— 内置数据只是「开局不要空白」。
///
/// 判定是否已灌入看 `dict_entries` 里是否已有 `built_in = 1` 的行，
/// 所以不要手工清空这张表再指望它自动恢复。
class DictSeeds {
  const DictSeeds._();

  static const String kindBrand = 'brand';
  static const String kindModel = 'model';
  static const String kindStorage = 'storage';
  static const String kindColor = 'color';
  static const String kindCategory = 'category';
  static const String kindSource = 'source';
  static const String kindPlatform = 'platform';
  static const String kindCondition = 'condition';

  /// 运营成本类别（v5 新增）。只用于「运营成本」页的分类下拉。
  static const String kindOperating = 'operating';

  /// 全部字典类别，含中文名，UI 里按这个顺序展示。
  static const List<({String kind, String label})> kinds = [
    (kind: kindBrand, label: '品牌'),
    (kind: kindModel, label: '机型'),
    (kind: kindStorage, label: '内存规格'),
    (kind: kindColor, label: '颜色'),
    (kind: kindCategory, label: '分类'),
    (kind: kindSource, label: '买入来源'),
    (kind: kindPlatform, label: '卖出渠道'),
    (kind: kindCondition, label: '成色'),
    (kind: kindOperating, label: '运营成本'),
  ];

  static String kindLabel(String kind) {
    for (final k in kinds) {
      if (k.kind == kind) return k.label;
    }
    return kind;
  }

  /// 品牌 → 机型。机型记录通过 `parent_id` 指向品牌记录。
  static const Map<String, List<String>> brandModels = {
    'Apple': [
      'iPhone 11', 'iPhone 11 Pro', 'iPhone 11 Pro Max',
      'iPhone 12 mini', 'iPhone 12', 'iPhone 12 Pro', 'iPhone 12 Pro Max',
      'iPhone 13 mini', 'iPhone 13', 'iPhone 13 Pro', 'iPhone 13 Pro Max',
      'iPhone 14', 'iPhone 14 Plus', 'iPhone 14 Pro', 'iPhone 14 Pro Max',
      'iPhone 15', 'iPhone 15 Plus', 'iPhone 15 Pro', 'iPhone 15 Pro Max',
      'iPhone 16', 'iPhone 16 Plus', 'iPhone 16 Pro', 'iPhone 16 Pro Max',
      'iPhone SE 2', 'iPhone SE 3',
      'iPhone XR', 'iPhone XS', 'iPhone XS Max',
    ],
    '华为': [
      'Mate 30 Pro', 'Mate 40', 'Mate 40 Pro', 'Mate 40 Pro+',
      'Mate 50', 'Mate 50 Pro', 'Mate 60', 'Mate 60 Pro', 'Mate 60 Pro+',
      'Mate 70', 'Mate 70 Pro',
      'P30', 'P30 Pro', 'P40', 'P40 Pro', 'P50', 'P50 Pro', 'P60', 'P60 Pro',
      'nova 9', 'nova 10', 'nova 11', 'nova 12',
      '畅享 50', '畅享 60',
    ],
    '荣耀': [
      '荣耀 30', '荣耀 30 Pro', '荣耀 50', '荣耀 60', '荣耀 70', '荣耀 80',
      '荣耀 90', '荣耀 90 Pro',
      'Magic 3', 'Magic 4', 'Magic 5', 'Magic 5 Pro', 'Magic 6', 'Magic 6 Pro',
      'X30', 'X40', 'X50',
    ],
    '小米': [
      '小米 10', '小米 10 Pro', '小米 10 Ultra',
      '小米 11', '小米 11 Pro', '小米 11 Ultra',
      '小米 12', '小米 12S', '小米 12S Ultra',
      '小米 13', '小米 13 Pro', '小米 13 Ultra',
      '小米 14', '小米 14 Pro', '小米 14 Ultra',
      '小米 15', '小米 15 Pro', '小米 15 Ultra',
      'MIX 4', 'Civi 2', 'Civi 3',
    ],
    'Redmi': [
      'K40', 'K40 Pro', 'K50', 'K50 Pro', 'K50 Ultra',
      'K60', 'K60 Pro', 'K70', 'K70 Pro',
      'Note 11', 'Note 11T Pro', 'Note 12', 'Note 12 Turbo',
      'Note 13', 'Note 13 Pro', 'Note 14',
    ],
    'OPPO': [
      'Find X2', 'Find X2 Pro', 'Find X3', 'Find X3 Pro',
      'Find X5', 'Find X5 Pro', 'Find X6', 'Find X6 Pro',
      'Find X7', 'Find X7 Ultra', 'Find X8', 'Find X8 Pro',
      'Reno 6', 'Reno 7', 'Reno 8', 'Reno 9', 'Reno 10', 'Reno 11', 'Reno 12',
      'A56', 'A58',
    ],
    'vivo': [
      'X50', 'X60', 'X70', 'X70 Pro', 'X80', 'X80 Pro',
      'X90', 'X90 Pro', 'X100', 'X100 Pro',
      'S15', 'S16', 'S17', 'S18', 'Y33s', 'Y77',
    ],
    'iQOO': [
      'Neo 5', 'Neo 6', 'Neo 7', 'Neo 8', 'Neo 9', 'Neo 10',
      'iQOO 8', 'iQOO 9', 'iQOO 10', 'iQOO 11', 'iQOO 12',
      'Z6', 'Z7', 'Z8',
    ],
    '一加': [
      '一加 8', '一加 8 Pro', '一加 8T', '一加 9', '一加 9 Pro', '一加 9RT',
      '一加 10 Pro', '一加 11', '一加 12',
      'Ace 2', 'Ace 2V', 'Ace 3', 'Ace 3V',
    ],
    'realme': [
      'GT', 'GT Neo', 'GT Neo 2', 'GT Neo 3', 'GT Neo 5',
      'GT 2', 'GT 5', 'GT 5 Pro', 'GT 6', 'GT 7',
      'Q5', '11 Pro',
    ],
    '三星': [
      'Galaxy S20', 'Galaxy S21', 'Galaxy S21 Ultra',
      'Galaxy S22', 'Galaxy S22 Ultra', 'Galaxy S23', 'Galaxy S23 Ultra',
      'Galaxy S24', 'Galaxy S24 Ultra', 'Galaxy S25', 'Galaxy S25 Ultra',
      'Galaxy A52', 'Galaxy A53', 'Galaxy A54', 'Galaxy A55',
      'Galaxy Z Flip 4', 'Galaxy Z Flip 5',
      'Galaxy Z Fold 4', 'Galaxy Z Fold 5',
    ],
    '魅族': ['魅族 17', '魅族 18', '魅族 18 Pro', '魅族 20', '魅族 20 Pro', '魅族 21', '魅族 21 Pro'],
    '摩托罗拉': ['Edge S30', 'Edge X30', 'Edge 30', 'Edge 40', 'Edge 50', 'razr 40', 'razr 50'],
    'Google': ['Pixel 6', 'Pixel 6 Pro', 'Pixel 7', 'Pixel 7 Pro', 'Pixel 8', 'Pixel 8 Pro', 'Pixel 9', 'Pixel 9 Pro'],
    '索尼': ['Xperia 1 II', 'Xperia 1 III', 'Xperia 1 IV', 'Xperia 1 V', 'Xperia 1 VI', 'Xperia 5 II', 'Xperia 5 III', 'Xperia 5 IV', 'Xperia 5 V'],
    '其他': [],
  };

  /// 内存规格：安卓常见「运行内存+存储」合并写法，后面几条是纯容量（平板/其他品类用）。
  static const List<String> storages = [
    '4+64', '4+128',
    '6+64', '6+128', '6+256',
    '8+128', '8+256', '8+512',
    '12+128', '12+256', '12+512',
    '16+256', '16+512', '16+1T',
    '24+1T',
    '64G', '128G', '256G', '512G', '1T',
  ];

  static const List<String> colors = [
    '黑色', '白色', '灰色', '银色', '深空灰',
    '金色', '玫瑰金', '沙漠金',
    '蓝色', '深蓝', '天蓝', '远峰蓝',
    '绿色', '墨绿', '青色',
    '紫色', '暗夜紫', '粉色', '红色', '橙色',
    '星光色', '午夜色', '钛金属', '原色钛金属',
  ];

  /// 商品分类。二手玩家常收的东西，不止手机。
  static const List<String> categories = [
    '手机', '平板', '笔记本', '台式机', '显示器',
    '相机', '镜头', '无人机', '耳机', '音箱',
    '智能手表', '手环', '游戏机', '手柄',
    '显卡', 'CPU', '主板', '内存条', '硬盘', '电源',
    '键鼠', '路由器', '充电器', '数据线',
    '平板笔', '保护壳', '其他',
  ];

  /// 买入来源。
  ///
  /// 采货侠、拍机堂是同行的手机批发/回收平台，二手贩子进货基本就这几个渠道，
  /// 放在最前面（顺序 = 录入时的点选频次）。
  static const List<String> sources = [
    '采货侠', '拍机堂',
    '闲鱼', '转转', '爱回收', '京东拍拍', '淘宝',
    '拼多多', '贴吧', '校园群', '朋友圈', '论坛',
    '线下店', '朋友', '同事', '家人', '其他',
  ];

  /// 卖出渠道。和买入来源有重叠但语义不同，分开维护。
  static const List<String> platforms = [
    '闲鱼', '转转', '爱回收', '回收宝', '找靓机',
    '京东', '淘宝', '拼多多', '贴吧', '校园群',
    '朋友圈', '同事', '线下店', '当铺', '其他',
  ];

  /// 成色描述。买入和卖出共用一套，具体到哪一档由用户自己判断。
  static const List<String> conditions = [
    '全新未拆', '全新拆封', '99新', '98新', '97新',
    '95新', '9成新', '85新', '8成新', '7成新',
    '有磕碰', '有划痕', '屏幕有伤', '功能正常有瑕疵',
    '拆修过', '缺配件', '仅主板',
  ];

  /// 运营成本类别。都是「摊不到某一单」的固定支出。
  static const List<String> operating = [
    '房租', '水电', '包装耗材', '快递费', '软件订阅', '推广', '其他',
  ];

  /// 无层级的字典类别 → 取值列表。灌库时统一遍历这组，
  /// 加新类别只要往这里加一行，不用再改迁移代码。
  static const List<({String kind, List<String> items})> flatKinds = [
    (kind: kindStorage, items: storages),
    (kind: kindColor, items: colors),
    (kind: kindCategory, items: categories),
    (kind: kindSource, items: sources),
    (kind: kindPlatform, items: platforms),
    (kind: kindCondition, items: conditions),
    (kind: kindOperating, items: operating),
  ];
}
