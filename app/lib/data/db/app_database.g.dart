// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storageMeta = const VerificationMeta(
    'storage',
  );
  @override
  late final GeneratedColumn<String> storage = GeneratedColumn<String>(
    'storage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionBoughtMeta = const VerificationMeta(
    'conditionBought',
  );
  @override
  late final GeneratedColumn<String> conditionBought = GeneratedColumn<String>(
    'condition_bought',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionSoldMeta = const VerificationMeta(
    'conditionSold',
  );
  @override
  late final GeneratedColumn<String> conditionSold = GeneratedColumn<String>(
    'condition_sold',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(ItemStatus.inStock.dbValue),
      ).withConverter<ItemStatus>($ItemsTable.$converterstatus);
  static const VerificationMeta _sourcePlatformMeta = const VerificationMeta(
    'sourcePlatform',
  );
  @override
  late final GeneratedColumn<String> sourcePlatform = GeneratedColumn<String>(
    'source_platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buyDateMeta = const VerificationMeta(
    'buyDate',
  );
  @override
  late final GeneratedColumn<DateTime> buyDate = GeneratedColumn<DateTime>(
    'buy_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buyPriceCentsMeta = const VerificationMeta(
    'buyPriceCents',
  );
  @override
  late final GeneratedColumn<int> buyPriceCents = GeneratedColumn<int>(
    'buy_price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sellDateMeta = const VerificationMeta(
    'sellDate',
  );
  @override
  late final GeneratedColumn<DateTime> sellDate = GeneratedColumn<DateTime>(
    'sell_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellPriceCentsMeta = const VerificationMeta(
    'sellPriceCents',
  );
  @override
  late final GeneratedColumn<int> sellPriceCents = GeneratedColumn<int>(
    'sell_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellPlatformMeta = const VerificationMeta(
    'sellPlatform',
  );
  @override
  late final GeneratedColumn<String> sellPlatform = GeneratedColumn<String>(
    'sell_platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lotIdMeta = const VerificationMeta('lotId');
  @override
  late final GeneratedColumn<String> lotId = GeneratedColumn<String>(
    'lot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batteryHealthMeta = const VerificationMeta(
    'batteryHealth',
  );
  @override
  late final GeneratedColumn<int> batteryHealth = GeneratedColumn<int>(
    'battery_health',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _listPriceCentsMeta = const VerificationMeta(
    'listPriceCents',
  );
  @override
  late final GeneratedColumn<int> listPriceCents = GeneratedColumn<int>(
    'list_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tradeInCentsMeta = const VerificationMeta(
    'tradeInCents',
  );
  @override
  late final GeneratedColumn<int> tradeInCents = GeneratedColumn<int>(
    'trade_in_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WarrantyStatus, String>
  warrantyStatus = GeneratedColumn<String>(
    'warranty_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  ).withConverter<WarrantyStatus>($ItemsTable.$converterwarrantyStatus);
  static const VerificationMeta _warrantyStartMeta = const VerificationMeta(
    'warrantyStart',
  );
  @override
  late final GeneratedColumn<DateTime> warrantyStart =
      GeneratedColumn<DateTime>(
        'warranty_start',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _warrantyEndMeta = const VerificationMeta(
    'warrantyEnd',
  );
  @override
  late final GeneratedColumn<DateTime> warrantyEnd = GeneratedColumn<DateTime>(
    'warranty_end',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    category,
    brand,
    model,
    storage,
    color,
    conditionBought,
    conditionSold,
    status,
    sourcePlatform,
    buyDate,
    buyPriceCents,
    sellDate,
    sellPriceCents,
    sellPlatform,
    lotId,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
    batteryHealth,
    listPriceCents,
    tradeInCents,
    warrantyStatus,
    warrantyStart,
    warrantyEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('storage')) {
      context.handle(
        _storageMeta,
        storage.isAcceptableOrUnknown(data['storage']!, _storageMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('condition_bought')) {
      context.handle(
        _conditionBoughtMeta,
        conditionBought.isAcceptableOrUnknown(
          data['condition_bought']!,
          _conditionBoughtMeta,
        ),
      );
    }
    if (data.containsKey('condition_sold')) {
      context.handle(
        _conditionSoldMeta,
        conditionSold.isAcceptableOrUnknown(
          data['condition_sold']!,
          _conditionSoldMeta,
        ),
      );
    }
    if (data.containsKey('source_platform')) {
      context.handle(
        _sourcePlatformMeta,
        sourcePlatform.isAcceptableOrUnknown(
          data['source_platform']!,
          _sourcePlatformMeta,
        ),
      );
    }
    if (data.containsKey('buy_date')) {
      context.handle(
        _buyDateMeta,
        buyDate.isAcceptableOrUnknown(data['buy_date']!, _buyDateMeta),
      );
    }
    if (data.containsKey('buy_price_cents')) {
      context.handle(
        _buyPriceCentsMeta,
        buyPriceCents.isAcceptableOrUnknown(
          data['buy_price_cents']!,
          _buyPriceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_buyPriceCentsMeta);
    }
    if (data.containsKey('sell_date')) {
      context.handle(
        _sellDateMeta,
        sellDate.isAcceptableOrUnknown(data['sell_date']!, _sellDateMeta),
      );
    }
    if (data.containsKey('sell_price_cents')) {
      context.handle(
        _sellPriceCentsMeta,
        sellPriceCents.isAcceptableOrUnknown(
          data['sell_price_cents']!,
          _sellPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('sell_platform')) {
      context.handle(
        _sellPlatformMeta,
        sellPlatform.isAcceptableOrUnknown(
          data['sell_platform']!,
          _sellPlatformMeta,
        ),
      );
    }
    if (data.containsKey('lot_id')) {
      context.handle(
        _lotIdMeta,
        lotId.isAcceptableOrUnknown(data['lot_id']!, _lotIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('battery_health')) {
      context.handle(
        _batteryHealthMeta,
        batteryHealth.isAcceptableOrUnknown(
          data['battery_health']!,
          _batteryHealthMeta,
        ),
      );
    }
    if (data.containsKey('list_price_cents')) {
      context.handle(
        _listPriceCentsMeta,
        listPriceCents.isAcceptableOrUnknown(
          data['list_price_cents']!,
          _listPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('trade_in_cents')) {
      context.handle(
        _tradeInCentsMeta,
        tradeInCents.isAcceptableOrUnknown(
          data['trade_in_cents']!,
          _tradeInCentsMeta,
        ),
      );
    }
    if (data.containsKey('warranty_start')) {
      context.handle(
        _warrantyStartMeta,
        warrantyStart.isAcceptableOrUnknown(
          data['warranty_start']!,
          _warrantyStartMeta,
        ),
      );
    }
    if (data.containsKey('warranty_end')) {
      context.handle(
        _warrantyEndMeta,
        warrantyEnd.isAcceptableOrUnknown(
          data['warranty_end']!,
          _warrantyEndMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      storage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      conditionBought: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition_bought'],
      ),
      conditionSold: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition_sold'],
      ),
      status: $ItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      sourcePlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_platform'],
      ),
      buyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}buy_date'],
      ),
      buyPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buy_price_cents'],
      )!,
      sellDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sell_date'],
      ),
      sellPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sell_price_cents'],
      ),
      sellPlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sell_platform'],
      ),
      lotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      batteryHealth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_health'],
      ),
      listPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_price_cents'],
      ),
      tradeInCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trade_in_cents'],
      ),
      warrantyStatus: $ItemsTable.$converterwarrantyStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}warranty_status'],
        )!,
      ),
      warrantyStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}warranty_start'],
      ),
      warrantyEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}warranty_end'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<ItemStatus, String> $converterstatus =
      const ItemStatusConverter();
  static TypeConverter<WarrantyStatus, String> $converterwarrantyStatus =
      const WarrantyStatusConverter();
}

class Item extends DataClass implements Insertable<Item> {
  final String id;
  final String title;
  final String? category;
  final String? brand;
  final String? model;

  /// 内存规格（如 `12+256`），来自字典 `dict_entries.kind = 'storage'`。
  final String? storage;

  /// 颜色，来自字典 `dict_entries.kind = 'color'`。
  final String? color;

  /// 买入时成色描述，自由文本（如「95新」「有划痕」）。
  final String? conditionBought;

  /// 卖出时成色描述。
  final String? conditionSold;
  final ItemStatus status;

  /// 买入来源：闲鱼/转转/朋友/线下店……
  final String? sourcePlatform;
  final DateTime? buyDate;
  final int buyPriceCents;
  final DateTime? sellDate;
  final int? sellPriceCents;
  final String? sellPlatform;

  /// 打包买卖时，同批商品共享一个 lotId；单独交易为 null。
  final String? lotId;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;

  /// 电池健康百分比（0–100 整数）。null = 没测或没填。
  ///
  /// 用整数而不是「95新」这类文本：以后要按它排序、算均值、看衰减曲线，
  /// 文本没法比大小。
  final int? batteryHealth;

  /// 置换时的挂牌价（分）。例：挂牌 1000、旧机抵 600、实收 400。
  ///
  /// [sellPriceCents] 存的是**实收**（参与利润），这里只做记录，
  /// 两者之差就是抵扣额。挂牌价为空表示普通交易。
  final int? listPriceCents;

  /// 置换时买家旧机折的价（分）。
  ///
  /// **当前不参与利润计算**：旧机的价值要等它作为新商品再卖出去才结算，
  /// 否则同一笔 600 元会被算两次。只单独展示。
  final int? tradeInCents;

  /// 保修状态：无保修 / 在保 / 已过保。
  ///
  /// 不用布尔：旧机器要能区分「不知道」和「确定过保」。
  /// 带常量默认值，而不是可空：`ALTER TABLE ADD COLUMN` 带字面量默认值时
  /// SQLite 不会重写旧行，旧库升级后旧行读出来就是「无保修」，与新建库一致；
  /// 若做成可空，列类型就变成 `WarrantyStatus?`，调用端处处要判 null。
  final WarrantyStatus warrantyStatus;

  /// 保修开始日（只存日期，时分为零）。只在「在保」时有值。
  final DateTime? warrantyStart;

  /// 保修到期日。只在「在保」时有值。
  final DateTime? warrantyEnd;
  const Item({
    required this.id,
    required this.title,
    this.category,
    this.brand,
    this.model,
    this.storage,
    this.color,
    this.conditionBought,
    this.conditionSold,
    required this.status,
    this.sourcePlatform,
    this.buyDate,
    required this.buyPriceCents,
    this.sellDate,
    this.sellPriceCents,
    this.sellPlatform,
    this.lotId,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    this.batteryHealth,
    this.listPriceCents,
    this.tradeInCents,
    required this.warrantyStatus,
    this.warrantyStart,
    this.warrantyEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || storage != null) {
      map['storage'] = Variable<String>(storage);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || conditionBought != null) {
      map['condition_bought'] = Variable<String>(conditionBought);
    }
    if (!nullToAbsent || conditionSold != null) {
      map['condition_sold'] = Variable<String>(conditionSold);
    }
    {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || sourcePlatform != null) {
      map['source_platform'] = Variable<String>(sourcePlatform);
    }
    if (!nullToAbsent || buyDate != null) {
      map['buy_date'] = Variable<DateTime>(buyDate);
    }
    map['buy_price_cents'] = Variable<int>(buyPriceCents);
    if (!nullToAbsent || sellDate != null) {
      map['sell_date'] = Variable<DateTime>(sellDate);
    }
    if (!nullToAbsent || sellPriceCents != null) {
      map['sell_price_cents'] = Variable<int>(sellPriceCents);
    }
    if (!nullToAbsent || sellPlatform != null) {
      map['sell_platform'] = Variable<String>(sellPlatform);
    }
    if (!nullToAbsent || lotId != null) {
      map['lot_id'] = Variable<String>(lotId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || batteryHealth != null) {
      map['battery_health'] = Variable<int>(batteryHealth);
    }
    if (!nullToAbsent || listPriceCents != null) {
      map['list_price_cents'] = Variable<int>(listPriceCents);
    }
    if (!nullToAbsent || tradeInCents != null) {
      map['trade_in_cents'] = Variable<int>(tradeInCents);
    }
    {
      map['warranty_status'] = Variable<String>(
        $ItemsTable.$converterwarrantyStatus.toSql(warrantyStatus),
      );
    }
    if (!nullToAbsent || warrantyStart != null) {
      map['warranty_start'] = Variable<DateTime>(warrantyStart);
    }
    if (!nullToAbsent || warrantyEnd != null) {
      map['warranty_end'] = Variable<DateTime>(warrantyEnd);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      title: Value(title),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      storage: storage == null && nullToAbsent
          ? const Value.absent()
          : Value(storage),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      conditionBought: conditionBought == null && nullToAbsent
          ? const Value.absent()
          : Value(conditionBought),
      conditionSold: conditionSold == null && nullToAbsent
          ? const Value.absent()
          : Value(conditionSold),
      status: Value(status),
      sourcePlatform: sourcePlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePlatform),
      buyDate: buyDate == null && nullToAbsent
          ? const Value.absent()
          : Value(buyDate),
      buyPriceCents: Value(buyPriceCents),
      sellDate: sellDate == null && nullToAbsent
          ? const Value.absent()
          : Value(sellDate),
      sellPriceCents: sellPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(sellPriceCents),
      sellPlatform: sellPlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(sellPlatform),
      lotId: lotId == null && nullToAbsent
          ? const Value.absent()
          : Value(lotId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      batteryHealth: batteryHealth == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryHealth),
      listPriceCents: listPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(listPriceCents),
      tradeInCents: tradeInCents == null && nullToAbsent
          ? const Value.absent()
          : Value(tradeInCents),
      warrantyStatus: Value(warrantyStatus),
      warrantyStart: warrantyStart == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyStart),
      warrantyEnd: warrantyEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyEnd),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String?>(json['category']),
      brand: serializer.fromJson<String?>(json['brand']),
      model: serializer.fromJson<String?>(json['model']),
      storage: serializer.fromJson<String?>(json['storage']),
      color: serializer.fromJson<String?>(json['color']),
      conditionBought: serializer.fromJson<String?>(json['conditionBought']),
      conditionSold: serializer.fromJson<String?>(json['conditionSold']),
      status: serializer.fromJson<ItemStatus>(json['status']),
      sourcePlatform: serializer.fromJson<String?>(json['sourcePlatform']),
      buyDate: serializer.fromJson<DateTime?>(json['buyDate']),
      buyPriceCents: serializer.fromJson<int>(json['buyPriceCents']),
      sellDate: serializer.fromJson<DateTime?>(json['sellDate']),
      sellPriceCents: serializer.fromJson<int?>(json['sellPriceCents']),
      sellPlatform: serializer.fromJson<String?>(json['sellPlatform']),
      lotId: serializer.fromJson<String?>(json['lotId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      batteryHealth: serializer.fromJson<int?>(json['batteryHealth']),
      listPriceCents: serializer.fromJson<int?>(json['listPriceCents']),
      tradeInCents: serializer.fromJson<int?>(json['tradeInCents']),
      warrantyStatus: serializer.fromJson<WarrantyStatus>(
        json['warrantyStatus'],
      ),
      warrantyStart: serializer.fromJson<DateTime?>(json['warrantyStart']),
      warrantyEnd: serializer.fromJson<DateTime?>(json['warrantyEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String?>(category),
      'brand': serializer.toJson<String?>(brand),
      'model': serializer.toJson<String?>(model),
      'storage': serializer.toJson<String?>(storage),
      'color': serializer.toJson<String?>(color),
      'conditionBought': serializer.toJson<String?>(conditionBought),
      'conditionSold': serializer.toJson<String?>(conditionSold),
      'status': serializer.toJson<ItemStatus>(status),
      'sourcePlatform': serializer.toJson<String?>(sourcePlatform),
      'buyDate': serializer.toJson<DateTime?>(buyDate),
      'buyPriceCents': serializer.toJson<int>(buyPriceCents),
      'sellDate': serializer.toJson<DateTime?>(sellDate),
      'sellPriceCents': serializer.toJson<int?>(sellPriceCents),
      'sellPlatform': serializer.toJson<String?>(sellPlatform),
      'lotId': serializer.toJson<String?>(lotId),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'batteryHealth': serializer.toJson<int?>(batteryHealth),
      'listPriceCents': serializer.toJson<int?>(listPriceCents),
      'tradeInCents': serializer.toJson<int?>(tradeInCents),
      'warrantyStatus': serializer.toJson<WarrantyStatus>(warrantyStatus),
      'warrantyStart': serializer.toJson<DateTime?>(warrantyStart),
      'warrantyEnd': serializer.toJson<DateTime?>(warrantyEnd),
    };
  }

  Item copyWith({
    String? id,
    String? title,
    Value<String?> category = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<String?> storage = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> conditionBought = const Value.absent(),
    Value<String?> conditionSold = const Value.absent(),
    ItemStatus? status,
    Value<String?> sourcePlatform = const Value.absent(),
    Value<DateTime?> buyDate = const Value.absent(),
    int? buyPriceCents,
    Value<DateTime?> sellDate = const Value.absent(),
    Value<int?> sellPriceCents = const Value.absent(),
    Value<String?> sellPlatform = const Value.absent(),
    Value<String?> lotId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
    Value<int?> batteryHealth = const Value.absent(),
    Value<int?> listPriceCents = const Value.absent(),
    Value<int?> tradeInCents = const Value.absent(),
    WarrantyStatus? warrantyStatus,
    Value<DateTime?> warrantyStart = const Value.absent(),
    Value<DateTime?> warrantyEnd = const Value.absent(),
  }) => Item(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category.present ? category.value : this.category,
    brand: brand.present ? brand.value : this.brand,
    model: model.present ? model.value : this.model,
    storage: storage.present ? storage.value : this.storage,
    color: color.present ? color.value : this.color,
    conditionBought: conditionBought.present
        ? conditionBought.value
        : this.conditionBought,
    conditionSold: conditionSold.present
        ? conditionSold.value
        : this.conditionSold,
    status: status ?? this.status,
    sourcePlatform: sourcePlatform.present
        ? sourcePlatform.value
        : this.sourcePlatform,
    buyDate: buyDate.present ? buyDate.value : this.buyDate,
    buyPriceCents: buyPriceCents ?? this.buyPriceCents,
    sellDate: sellDate.present ? sellDate.value : this.sellDate,
    sellPriceCents: sellPriceCents.present
        ? sellPriceCents.value
        : this.sellPriceCents,
    sellPlatform: sellPlatform.present ? sellPlatform.value : this.sellPlatform,
    lotId: lotId.present ? lotId.value : this.lotId,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    batteryHealth: batteryHealth.present
        ? batteryHealth.value
        : this.batteryHealth,
    listPriceCents: listPriceCents.present
        ? listPriceCents.value
        : this.listPriceCents,
    tradeInCents: tradeInCents.present ? tradeInCents.value : this.tradeInCents,
    warrantyStatus: warrantyStatus ?? this.warrantyStatus,
    warrantyStart: warrantyStart.present
        ? warrantyStart.value
        : this.warrantyStart,
    warrantyEnd: warrantyEnd.present ? warrantyEnd.value : this.warrantyEnd,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      storage: data.storage.present ? data.storage.value : this.storage,
      color: data.color.present ? data.color.value : this.color,
      conditionBought: data.conditionBought.present
          ? data.conditionBought.value
          : this.conditionBought,
      conditionSold: data.conditionSold.present
          ? data.conditionSold.value
          : this.conditionSold,
      status: data.status.present ? data.status.value : this.status,
      sourcePlatform: data.sourcePlatform.present
          ? data.sourcePlatform.value
          : this.sourcePlatform,
      buyDate: data.buyDate.present ? data.buyDate.value : this.buyDate,
      buyPriceCents: data.buyPriceCents.present
          ? data.buyPriceCents.value
          : this.buyPriceCents,
      sellDate: data.sellDate.present ? data.sellDate.value : this.sellDate,
      sellPriceCents: data.sellPriceCents.present
          ? data.sellPriceCents.value
          : this.sellPriceCents,
      sellPlatform: data.sellPlatform.present
          ? data.sellPlatform.value
          : this.sellPlatform,
      lotId: data.lotId.present ? data.lotId.value : this.lotId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      batteryHealth: data.batteryHealth.present
          ? data.batteryHealth.value
          : this.batteryHealth,
      listPriceCents: data.listPriceCents.present
          ? data.listPriceCents.value
          : this.listPriceCents,
      tradeInCents: data.tradeInCents.present
          ? data.tradeInCents.value
          : this.tradeInCents,
      warrantyStatus: data.warrantyStatus.present
          ? data.warrantyStatus.value
          : this.warrantyStatus,
      warrantyStart: data.warrantyStart.present
          ? data.warrantyStart.value
          : this.warrantyStart,
      warrantyEnd: data.warrantyEnd.present
          ? data.warrantyEnd.value
          : this.warrantyEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('storage: $storage, ')
          ..write('color: $color, ')
          ..write('conditionBought: $conditionBought, ')
          ..write('conditionSold: $conditionSold, ')
          ..write('status: $status, ')
          ..write('sourcePlatform: $sourcePlatform, ')
          ..write('buyDate: $buyDate, ')
          ..write('buyPriceCents: $buyPriceCents, ')
          ..write('sellDate: $sellDate, ')
          ..write('sellPriceCents: $sellPriceCents, ')
          ..write('sellPlatform: $sellPlatform, ')
          ..write('lotId: $lotId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('batteryHealth: $batteryHealth, ')
          ..write('listPriceCents: $listPriceCents, ')
          ..write('tradeInCents: $tradeInCents, ')
          ..write('warrantyStatus: $warrantyStatus, ')
          ..write('warrantyStart: $warrantyStart, ')
          ..write('warrantyEnd: $warrantyEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    category,
    brand,
    model,
    storage,
    color,
    conditionBought,
    conditionSold,
    status,
    sourcePlatform,
    buyDate,
    buyPriceCents,
    sellDate,
    sellPriceCents,
    sellPlatform,
    lotId,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
    batteryHealth,
    listPriceCents,
    tradeInCents,
    warrantyStatus,
    warrantyStart,
    warrantyEnd,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.storage == this.storage &&
          other.color == this.color &&
          other.conditionBought == this.conditionBought &&
          other.conditionSold == this.conditionSold &&
          other.status == this.status &&
          other.sourcePlatform == this.sourcePlatform &&
          other.buyDate == this.buyDate &&
          other.buyPriceCents == this.buyPriceCents &&
          other.sellDate == this.sellDate &&
          other.sellPriceCents == this.sellPriceCents &&
          other.sellPlatform == this.sellPlatform &&
          other.lotId == this.lotId &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.batteryHealth == this.batteryHealth &&
          other.listPriceCents == this.listPriceCents &&
          other.tradeInCents == this.tradeInCents &&
          other.warrantyStatus == this.warrantyStatus &&
          other.warrantyStart == this.warrantyStart &&
          other.warrantyEnd == this.warrantyEnd);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> category;
  final Value<String?> brand;
  final Value<String?> model;
  final Value<String?> storage;
  final Value<String?> color;
  final Value<String?> conditionBought;
  final Value<String?> conditionSold;
  final Value<ItemStatus> status;
  final Value<String?> sourcePlatform;
  final Value<DateTime?> buyDate;
  final Value<int> buyPriceCents;
  final Value<DateTime?> sellDate;
  final Value<int?> sellPriceCents;
  final Value<String?> sellPlatform;
  final Value<String?> lotId;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int?> batteryHealth;
  final Value<int?> listPriceCents;
  final Value<int?> tradeInCents;
  final Value<WarrantyStatus> warrantyStatus;
  final Value<DateTime?> warrantyStart;
  final Value<DateTime?> warrantyEnd;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.storage = const Value.absent(),
    this.color = const Value.absent(),
    this.conditionBought = const Value.absent(),
    this.conditionSold = const Value.absent(),
    this.status = const Value.absent(),
    this.sourcePlatform = const Value.absent(),
    this.buyDate = const Value.absent(),
    this.buyPriceCents = const Value.absent(),
    this.sellDate = const Value.absent(),
    this.sellPriceCents = const Value.absent(),
    this.sellPlatform = const Value.absent(),
    this.lotId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.batteryHealth = const Value.absent(),
    this.listPriceCents = const Value.absent(),
    this.tradeInCents = const Value.absent(),
    this.warrantyStatus = const Value.absent(),
    this.warrantyStart = const Value.absent(),
    this.warrantyEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String title,
    this.category = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.storage = const Value.absent(),
    this.color = const Value.absent(),
    this.conditionBought = const Value.absent(),
    this.conditionSold = const Value.absent(),
    this.status = const Value.absent(),
    this.sourcePlatform = const Value.absent(),
    this.buyDate = const Value.absent(),
    required int buyPriceCents,
    this.sellDate = const Value.absent(),
    this.sellPriceCents = const Value.absent(),
    this.sellPlatform = const Value.absent(),
    this.lotId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.batteryHealth = const Value.absent(),
    this.listPriceCents = const Value.absent(),
    this.tradeInCents = const Value.absent(),
    this.warrantyStatus = const Value.absent(),
    this.warrantyStart = const Value.absent(),
    this.warrantyEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       buyPriceCents = Value(buyPriceCents),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<String>? storage,
    Expression<String>? color,
    Expression<String>? conditionBought,
    Expression<String>? conditionSold,
    Expression<String>? status,
    Expression<String>? sourcePlatform,
    Expression<DateTime>? buyDate,
    Expression<int>? buyPriceCents,
    Expression<DateTime>? sellDate,
    Expression<int>? sellPriceCents,
    Expression<String>? sellPlatform,
    Expression<String>? lotId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? batteryHealth,
    Expression<int>? listPriceCents,
    Expression<int>? tradeInCents,
    Expression<String>? warrantyStatus,
    Expression<DateTime>? warrantyStart,
    Expression<DateTime>? warrantyEnd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (storage != null) 'storage': storage,
      if (color != null) 'color': color,
      if (conditionBought != null) 'condition_bought': conditionBought,
      if (conditionSold != null) 'condition_sold': conditionSold,
      if (status != null) 'status': status,
      if (sourcePlatform != null) 'source_platform': sourcePlatform,
      if (buyDate != null) 'buy_date': buyDate,
      if (buyPriceCents != null) 'buy_price_cents': buyPriceCents,
      if (sellDate != null) 'sell_date': sellDate,
      if (sellPriceCents != null) 'sell_price_cents': sellPriceCents,
      if (sellPlatform != null) 'sell_platform': sellPlatform,
      if (lotId != null) 'lot_id': lotId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (batteryHealth != null) 'battery_health': batteryHealth,
      if (listPriceCents != null) 'list_price_cents': listPriceCents,
      if (tradeInCents != null) 'trade_in_cents': tradeInCents,
      if (warrantyStatus != null) 'warranty_status': warrantyStatus,
      if (warrantyStart != null) 'warranty_start': warrantyStart,
      if (warrantyEnd != null) 'warranty_end': warrantyEnd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? category,
    Value<String?>? brand,
    Value<String?>? model,
    Value<String?>? storage,
    Value<String?>? color,
    Value<String?>? conditionBought,
    Value<String?>? conditionSold,
    Value<ItemStatus>? status,
    Value<String?>? sourcePlatform,
    Value<DateTime?>? buyDate,
    Value<int>? buyPriceCents,
    Value<DateTime?>? sellDate,
    Value<int?>? sellPriceCents,
    Value<String?>? sellPlatform,
    Value<String?>? lotId,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int?>? batteryHealth,
    Value<int?>? listPriceCents,
    Value<int?>? tradeInCents,
    Value<WarrantyStatus>? warrantyStatus,
    Value<DateTime?>? warrantyStart,
    Value<DateTime?>? warrantyEnd,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      storage: storage ?? this.storage,
      color: color ?? this.color,
      conditionBought: conditionBought ?? this.conditionBought,
      conditionSold: conditionSold ?? this.conditionSold,
      status: status ?? this.status,
      sourcePlatform: sourcePlatform ?? this.sourcePlatform,
      buyDate: buyDate ?? this.buyDate,
      buyPriceCents: buyPriceCents ?? this.buyPriceCents,
      sellDate: sellDate ?? this.sellDate,
      sellPriceCents: sellPriceCents ?? this.sellPriceCents,
      sellPlatform: sellPlatform ?? this.sellPlatform,
      lotId: lotId ?? this.lotId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      batteryHealth: batteryHealth ?? this.batteryHealth,
      listPriceCents: listPriceCents ?? this.listPriceCents,
      tradeInCents: tradeInCents ?? this.tradeInCents,
      warrantyStatus: warrantyStatus ?? this.warrantyStatus,
      warrantyStart: warrantyStart ?? this.warrantyStart,
      warrantyEnd: warrantyEnd ?? this.warrantyEnd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (storage.present) {
      map['storage'] = Variable<String>(storage.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (conditionBought.present) {
      map['condition_bought'] = Variable<String>(conditionBought.value);
    }
    if (conditionSold.present) {
      map['condition_sold'] = Variable<String>(conditionSold.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (sourcePlatform.present) {
      map['source_platform'] = Variable<String>(sourcePlatform.value);
    }
    if (buyDate.present) {
      map['buy_date'] = Variable<DateTime>(buyDate.value);
    }
    if (buyPriceCents.present) {
      map['buy_price_cents'] = Variable<int>(buyPriceCents.value);
    }
    if (sellDate.present) {
      map['sell_date'] = Variable<DateTime>(sellDate.value);
    }
    if (sellPriceCents.present) {
      map['sell_price_cents'] = Variable<int>(sellPriceCents.value);
    }
    if (sellPlatform.present) {
      map['sell_platform'] = Variable<String>(sellPlatform.value);
    }
    if (lotId.present) {
      map['lot_id'] = Variable<String>(lotId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (batteryHealth.present) {
      map['battery_health'] = Variable<int>(batteryHealth.value);
    }
    if (listPriceCents.present) {
      map['list_price_cents'] = Variable<int>(listPriceCents.value);
    }
    if (tradeInCents.present) {
      map['trade_in_cents'] = Variable<int>(tradeInCents.value);
    }
    if (warrantyStatus.present) {
      map['warranty_status'] = Variable<String>(
        $ItemsTable.$converterwarrantyStatus.toSql(warrantyStatus.value),
      );
    }
    if (warrantyStart.present) {
      map['warranty_start'] = Variable<DateTime>(warrantyStart.value);
    }
    if (warrantyEnd.present) {
      map['warranty_end'] = Variable<DateTime>(warrantyEnd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('storage: $storage, ')
          ..write('color: $color, ')
          ..write('conditionBought: $conditionBought, ')
          ..write('conditionSold: $conditionSold, ')
          ..write('status: $status, ')
          ..write('sourcePlatform: $sourcePlatform, ')
          ..write('buyDate: $buyDate, ')
          ..write('buyPriceCents: $buyPriceCents, ')
          ..write('sellDate: $sellDate, ')
          ..write('sellPriceCents: $sellPriceCents, ')
          ..write('sellPlatform: $sellPlatform, ')
          ..write('lotId: $lotId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('batteryHealth: $batteryHealth, ')
          ..write('listPriceCents: $listPriceCents, ')
          ..write('tradeInCents: $tradeInCents, ')
          ..write('warrantyStatus: $warrantyStatus, ')
          ..write('warrantyStart: $warrantyStart, ')
          ..write('warrantyEnd: $warrantyEnd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExpenseKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ExpenseKind>($ExpensesTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<ExpenseSide, String> side =
      GeneratedColumn<String>(
        'side',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ExpenseSide>($ExpensesTable.$converterside);
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incurredAtMeta = const VerificationMeta(
    'incurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> incurredAt = GeneratedColumn<DateTime>(
    'incurred_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    kind,
    side,
    amountCents,
    incurredAt,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('incurred_at')) {
      context.handle(
        _incurredAtMeta,
        incurredAt.isAcceptableOrUnknown(data['incurred_at']!, _incurredAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      kind: $ExpensesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      side: $ExpensesTable.$converterside.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}side'],
        )!,
      ),
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      incurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}incurred_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }

  static TypeConverter<ExpenseKind, String> $converterkind =
      const ExpenseKindConverter();
  static TypeConverter<ExpenseSide, String> $converterside =
      const ExpenseSideConverter();
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String itemId;
  final ExpenseKind kind;
  final ExpenseSide side;
  final int amountCents;
  final DateTime? incurredAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const Expense({
    required this.id,
    required this.itemId,
    required this.kind,
    required this.side,
    required this.amountCents,
    this.incurredAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    {
      map['kind'] = Variable<String>($ExpensesTable.$converterkind.toSql(kind));
    }
    {
      map['side'] = Variable<String>($ExpensesTable.$converterside.toSql(side));
    }
    map['amount_cents'] = Variable<int>(amountCents);
    if (!nullToAbsent || incurredAt != null) {
      map['incurred_at'] = Variable<DateTime>(incurredAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      kind: Value(kind),
      side: Value(side),
      amountCents: Value(amountCents),
      incurredAt: incurredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(incurredAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      kind: serializer.fromJson<ExpenseKind>(json['kind']),
      side: serializer.fromJson<ExpenseSide>(json['side']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      incurredAt: serializer.fromJson<DateTime?>(json['incurredAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'kind': serializer.toJson<ExpenseKind>(kind),
      'side': serializer.toJson<ExpenseSide>(side),
      'amountCents': serializer.toJson<int>(amountCents),
      'incurredAt': serializer.toJson<DateTime?>(incurredAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  Expense copyWith({
    String? id,
    String? itemId,
    ExpenseKind? kind,
    ExpenseSide? side,
    int? amountCents,
    Value<DateTime?> incurredAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => Expense(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    kind: kind ?? this.kind,
    side: side ?? this.side,
    amountCents: amountCents ?? this.amountCents,
    incurredAt: incurredAt.present ? incurredAt.value : this.incurredAt,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      side: data.side.present ? data.side.value : this.side,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      incurredAt: data.incurredAt.present
          ? data.incurredAt.value
          : this.incurredAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('side: $side, ')
          ..write('amountCents: $amountCents, ')
          ..write('incurredAt: $incurredAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    kind,
    side,
    amountCents,
    incurredAt,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.kind == this.kind &&
          other.side == this.side &&
          other.amountCents == this.amountCents &&
          other.incurredAt == this.incurredAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<ExpenseKind> kind;
  final Value<ExpenseSide> side;
  final Value<int> amountCents;
  final Value<DateTime?> incurredAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.side = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.incurredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String itemId,
    required ExpenseKind kind,
    required ExpenseSide side,
    required int amountCents,
    this.incurredAt = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       kind = Value(kind),
       side = Value(side),
       amountCents = Value(amountCents),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? kind,
    Expression<String>? side,
    Expression<int>? amountCents,
    Expression<DateTime>? incurredAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (kind != null) 'kind': kind,
      if (side != null) 'side': side,
      if (amountCents != null) 'amount_cents': amountCents,
      if (incurredAt != null) 'incurred_at': incurredAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<ExpenseKind>? kind,
    Value<ExpenseSide>? side,
    Value<int>? amountCents,
    Value<DateTime?>? incurredAt,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      side: side ?? this.side,
      amountCents: amountCents ?? this.amountCents,
      incurredAt: incurredAt ?? this.incurredAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ExpensesTable.$converterkind.toSql(kind.value),
      );
    }
    if (side.present) {
      map['side'] = Variable<String>(
        $ExpensesTable.$converterside.toSql(side.value),
      );
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (incurredAt.present) {
      map['incurred_at'] = Variable<DateTime>(incurredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('side: $side, ')
          ..write('amountCents: $amountCents, ')
          ..write('incurredAt: $incurredAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachmentRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AttachmentRole>($AttachmentsTable.$converterrole);
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('image/jpeg'),
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbMeta = const VerificationMeta('thumb');
  @override
  late final GeneratedColumn<Uint8List> thumb = GeneratedColumn<Uint8List>(
    'thumb',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    role,
    mime,
    bytes,
    thumb,
    width,
    height,
    sizeBytes,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('thumb')) {
      context.handle(
        _thumbMeta,
        thumb.isAcceptableOrUnknown(data['thumb']!, _thumbMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      role: $AttachmentsTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
      thumb: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}thumb'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }

  static TypeConverter<AttachmentRole, String> $converterrole =
      const AttachmentRoleConverter();
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String itemId;
  final AttachmentRole role;
  final String mime;
  final Uint8List bytes;
  final Uint8List? thumb;
  final int? width;
  final int? height;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const Attachment({
    required this.id,
    required this.itemId,
    required this.role,
    required this.mime,
    required this.bytes,
    this.thumb,
    this.width,
    this.height,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    {
      map['role'] = Variable<String>(
        $AttachmentsTable.$converterrole.toSql(role),
      );
    }
    map['mime'] = Variable<String>(mime);
    map['bytes'] = Variable<Uint8List>(bytes);
    if (!nullToAbsent || thumb != null) {
      map['thumb'] = Variable<Uint8List>(thumb);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      role: Value(role),
      mime: Value(mime),
      bytes: Value(bytes),
      thumb: thumb == null && nullToAbsent
          ? const Value.absent()
          : Value(thumb),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      sizeBytes: Value(sizeBytes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      role: serializer.fromJson<AttachmentRole>(json['role']),
      mime: serializer.fromJson<String>(json['mime']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      thumb: serializer.fromJson<Uint8List?>(json['thumb']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'role': serializer.toJson<AttachmentRole>(role),
      'mime': serializer.toJson<String>(mime),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'thumb': serializer.toJson<Uint8List?>(thumb),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  Attachment copyWith({
    String? id,
    String? itemId,
    AttachmentRole? role,
    String? mime,
    Uint8List? bytes,
    Value<Uint8List?> thumb = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    int? sizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => Attachment(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    role: role ?? this.role,
    mime: mime ?? this.mime,
    bytes: bytes ?? this.bytes,
    thumb: thumb.present ? thumb.value : this.thumb,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      role: data.role.present ? data.role.value : this.role,
      mime: data.mime.present ? data.mime.value : this.mime,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      thumb: data.thumb.present ? data.thumb.value : this.thumb,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('role: $role, ')
          ..write('mime: $mime, ')
          ..write('bytes: $bytes, ')
          ..write('thumb: $thumb, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    role,
    mime,
    $driftBlobEquality.hash(bytes),
    $driftBlobEquality.hash(thumb),
    width,
    height,
    sizeBytes,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.role == this.role &&
          other.mime == this.mime &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          $driftBlobEquality.equals(other.thumb, this.thumb) &&
          other.width == this.width &&
          other.height == this.height &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<AttachmentRole> role;
  final Value<String> mime;
  final Value<Uint8List> bytes;
  final Value<Uint8List?> thumb;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int> sizeBytes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.role = const Value.absent(),
    this.mime = const Value.absent(),
    this.bytes = const Value.absent(),
    this.thumb = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String itemId,
    required AttachmentRole role,
    this.mime = const Value.absent(),
    required Uint8List bytes,
    this.thumb = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       role = Value(role),
       bytes = Value(bytes),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? role,
    Expression<String>? mime,
    Expression<Uint8List>? bytes,
    Expression<Uint8List>? thumb,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (role != null) 'role': role,
      if (mime != null) 'mime': mime,
      if (bytes != null) 'bytes': bytes,
      if (thumb != null) 'thumb': thumb,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<AttachmentRole>? role,
    Value<String>? mime,
    Value<Uint8List>? bytes,
    Value<Uint8List?>? thumb,
    Value<int?>? width,
    Value<int?>? height,
    Value<int>? sizeBytes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      role: role ?? this.role,
      mime: mime ?? this.mime,
      bytes: bytes ?? this.bytes,
      thumb: thumb ?? this.thumb,
      width: width ?? this.width,
      height: height ?? this.height,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $AttachmentsTable.$converterrole.toSql(role.value),
      );
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (thumb.present) {
      map['thumb'] = Variable<Uint8List>(thumb.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('role: $role, ')
          ..write('mime: $mime, ')
          ..write('bytes: $bytes, ')
          ..write('thumb: $thumb, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatesTable extends SyncStates
    with TableInfo<$SyncStatesTable, SyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
    'peer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerNameMeta = const VerificationMeta(
    'peerName',
  );
  @override
  late final GeneratedColumn<String> peerName = GeneratedColumn<String>(
    'peer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPushAtMeta = const VerificationMeta(
    'lastPushAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPushAt = GeneratedColumn<DateTime>(
    'last_push_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerTokenMeta = const VerificationMeta(
    'peerToken',
  );
  @override
  late final GeneratedColumn<String> peerToken = GeneratedColumn<String>(
    'peer_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerHostMeta = const VerificationMeta(
    'peerHost',
  );
  @override
  late final GeneratedColumn<String> peerHost = GeneratedColumn<String>(
    'peer_host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerPortMeta = const VerificationMeta(
    'peerPort',
  );
  @override
  late final GeneratedColumn<int> peerPort = GeneratedColumn<int>(
    'peer_port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoSyncMeta = const VerificationMeta(
    'autoSync',
  );
  @override
  late final GeneratedColumn<int> autoSync = GeneratedColumn<int>(
    'auto_sync',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    peerId,
    peerName,
    lastPullAt,
    lastPushAt,
    pairedAt,
    peerToken,
    peerHost,
    peerPort,
    lastSyncAt,
    autoSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('peer_name')) {
      context.handle(
        _peerNameMeta,
        peerName.isAcceptableOrUnknown(data['peer_name']!, _peerNameMeta),
      );
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    }
    if (data.containsKey('last_push_at')) {
      context.handle(
        _lastPushAtMeta,
        lastPushAt.isAcceptableOrUnknown(
          data['last_push_at']!,
          _lastPushAtMeta,
        ),
      );
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pairedAtMeta);
    }
    if (data.containsKey('peer_token')) {
      context.handle(
        _peerTokenMeta,
        peerToken.isAcceptableOrUnknown(data['peer_token']!, _peerTokenMeta),
      );
    }
    if (data.containsKey('peer_host')) {
      context.handle(
        _peerHostMeta,
        peerHost.isAcceptableOrUnknown(data['peer_host']!, _peerHostMeta),
      );
    }
    if (data.containsKey('peer_port')) {
      context.handle(
        _peerPortMeta,
        peerPort.isAcceptableOrUnknown(data['peer_port']!, _peerPortMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('auto_sync')) {
      context.handle(
        _autoSyncMeta,
        autoSync.isAcceptableOrUnknown(data['auto_sync']!, _autoSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {peerId};
  @override
  SyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncState(
      peerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_id'],
      )!,
      peerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_name'],
      ),
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      ),
      lastPushAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_push_at'],
      ),
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paired_at'],
      )!,
      peerToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_token'],
      ),
      peerHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_host'],
      ),
      peerPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}peer_port'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      autoSync: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_sync'],
      )!,
    );
  }

  @override
  $SyncStatesTable createAlias(String alias) {
    return $SyncStatesTable(attachedDatabase, alias);
  }
}

class SyncState extends DataClass implements Insertable<SyncState> {
  final String peerId;
  final String? peerName;
  final DateTime? lastPullAt;
  final DateTime? lastPushAt;
  final DateTime pairedAt;

  /// 配对时对端签发的 Bearer 凭证。持久化它，重启后才能自动同步
  /// —— 只放内存的话，进程一退出旧 token 就全失效，自动同步永远失败。
  final String? peerToken;

  /// 对端地址与端口，自动同步时直接拿来 ping，不用再问用户。
  final String? peerHost;
  final int? peerPort;

  /// 上次**成功**同步完成的时刻。冲突判据（「同步之后两边都改过」）靠它。
  final DateTime? lastSyncAt;

  /// 是否在启动时自动连这台对端：1 开（默认）、0 关。
  final int autoSync;
  const SyncState({
    required this.peerId,
    this.peerName,
    this.lastPullAt,
    this.lastPushAt,
    required this.pairedAt,
    this.peerToken,
    this.peerHost,
    this.peerPort,
    this.lastSyncAt,
    required this.autoSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['peer_id'] = Variable<String>(peerId);
    if (!nullToAbsent || peerName != null) {
      map['peer_name'] = Variable<String>(peerName);
    }
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    }
    if (!nullToAbsent || lastPushAt != null) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt);
    }
    map['paired_at'] = Variable<DateTime>(pairedAt);
    if (!nullToAbsent || peerToken != null) {
      map['peer_token'] = Variable<String>(peerToken);
    }
    if (!nullToAbsent || peerHost != null) {
      map['peer_host'] = Variable<String>(peerHost);
    }
    if (!nullToAbsent || peerPort != null) {
      map['peer_port'] = Variable<int>(peerPort);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    map['auto_sync'] = Variable<int>(autoSync);
    return map;
  }

  SyncStatesCompanion toCompanion(bool nullToAbsent) {
    return SyncStatesCompanion(
      peerId: Value(peerId),
      peerName: peerName == null && nullToAbsent
          ? const Value.absent()
          : Value(peerName),
      lastPullAt: lastPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullAt),
      lastPushAt: lastPushAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushAt),
      pairedAt: Value(pairedAt),
      peerToken: peerToken == null && nullToAbsent
          ? const Value.absent()
          : Value(peerToken),
      peerHost: peerHost == null && nullToAbsent
          ? const Value.absent()
          : Value(peerHost),
      peerPort: peerPort == null && nullToAbsent
          ? const Value.absent()
          : Value(peerPort),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      autoSync: Value(autoSync),
    );
  }

  factory SyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncState(
      peerId: serializer.fromJson<String>(json['peerId']),
      peerName: serializer.fromJson<String?>(json['peerName']),
      lastPullAt: serializer.fromJson<DateTime?>(json['lastPullAt']),
      lastPushAt: serializer.fromJson<DateTime?>(json['lastPushAt']),
      pairedAt: serializer.fromJson<DateTime>(json['pairedAt']),
      peerToken: serializer.fromJson<String?>(json['peerToken']),
      peerHost: serializer.fromJson<String?>(json['peerHost']),
      peerPort: serializer.fromJson<int?>(json['peerPort']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      autoSync: serializer.fromJson<int>(json['autoSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'peerId': serializer.toJson<String>(peerId),
      'peerName': serializer.toJson<String?>(peerName),
      'lastPullAt': serializer.toJson<DateTime?>(lastPullAt),
      'lastPushAt': serializer.toJson<DateTime?>(lastPushAt),
      'pairedAt': serializer.toJson<DateTime>(pairedAt),
      'peerToken': serializer.toJson<String?>(peerToken),
      'peerHost': serializer.toJson<String?>(peerHost),
      'peerPort': serializer.toJson<int?>(peerPort),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'autoSync': serializer.toJson<int>(autoSync),
    };
  }

  SyncState copyWith({
    String? peerId,
    Value<String?> peerName = const Value.absent(),
    Value<DateTime?> lastPullAt = const Value.absent(),
    Value<DateTime?> lastPushAt = const Value.absent(),
    DateTime? pairedAt,
    Value<String?> peerToken = const Value.absent(),
    Value<String?> peerHost = const Value.absent(),
    Value<int?> peerPort = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
    int? autoSync,
  }) => SyncState(
    peerId: peerId ?? this.peerId,
    peerName: peerName.present ? peerName.value : this.peerName,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
    lastPushAt: lastPushAt.present ? lastPushAt.value : this.lastPushAt,
    pairedAt: pairedAt ?? this.pairedAt,
    peerToken: peerToken.present ? peerToken.value : this.peerToken,
    peerHost: peerHost.present ? peerHost.value : this.peerHost,
    peerPort: peerPort.present ? peerPort.value : this.peerPort,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    autoSync: autoSync ?? this.autoSync,
  );
  SyncState copyWithCompanion(SyncStatesCompanion data) {
    return SyncState(
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      peerName: data.peerName.present ? data.peerName.value : this.peerName,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
      lastPushAt: data.lastPushAt.present
          ? data.lastPushAt.value
          : this.lastPushAt,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      peerToken: data.peerToken.present ? data.peerToken.value : this.peerToken,
      peerHost: data.peerHost.present ? data.peerHost.value : this.peerHost,
      peerPort: data.peerPort.present ? data.peerPort.value : this.peerPort,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      autoSync: data.autoSync.present ? data.autoSync.value : this.autoSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncState(')
          ..write('peerId: $peerId, ')
          ..write('peerName: $peerName, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('peerToken: $peerToken, ')
          ..write('peerHost: $peerHost, ')
          ..write('peerPort: $peerPort, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('autoSync: $autoSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    peerId,
    peerName,
    lastPullAt,
    lastPushAt,
    pairedAt,
    peerToken,
    peerHost,
    peerPort,
    lastSyncAt,
    autoSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncState &&
          other.peerId == this.peerId &&
          other.peerName == this.peerName &&
          other.lastPullAt == this.lastPullAt &&
          other.lastPushAt == this.lastPushAt &&
          other.pairedAt == this.pairedAt &&
          other.peerToken == this.peerToken &&
          other.peerHost == this.peerHost &&
          other.peerPort == this.peerPort &&
          other.lastSyncAt == this.lastSyncAt &&
          other.autoSync == this.autoSync);
}

class SyncStatesCompanion extends UpdateCompanion<SyncState> {
  final Value<String> peerId;
  final Value<String?> peerName;
  final Value<DateTime?> lastPullAt;
  final Value<DateTime?> lastPushAt;
  final Value<DateTime> pairedAt;
  final Value<String?> peerToken;
  final Value<String?> peerHost;
  final Value<int?> peerPort;
  final Value<DateTime?> lastSyncAt;
  final Value<int> autoSync;
  final Value<int> rowid;
  const SyncStatesCompanion({
    this.peerId = const Value.absent(),
    this.peerName = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.peerToken = const Value.absent(),
    this.peerHost = const Value.absent(),
    this.peerPort = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.autoSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatesCompanion.insert({
    required String peerId,
    this.peerName = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    required DateTime pairedAt,
    this.peerToken = const Value.absent(),
    this.peerHost = const Value.absent(),
    this.peerPort = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.autoSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : peerId = Value(peerId),
       pairedAt = Value(pairedAt);
  static Insertable<SyncState> custom({
    Expression<String>? peerId,
    Expression<String>? peerName,
    Expression<DateTime>? lastPullAt,
    Expression<DateTime>? lastPushAt,
    Expression<DateTime>? pairedAt,
    Expression<String>? peerToken,
    Expression<String>? peerHost,
    Expression<int>? peerPort,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? autoSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (peerId != null) 'peer_id': peerId,
      if (peerName != null) 'peer_name': peerName,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (lastPushAt != null) 'last_push_at': lastPushAt,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (peerToken != null) 'peer_token': peerToken,
      if (peerHost != null) 'peer_host': peerHost,
      if (peerPort != null) 'peer_port': peerPort,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (autoSync != null) 'auto_sync': autoSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatesCompanion copyWith({
    Value<String>? peerId,
    Value<String?>? peerName,
    Value<DateTime?>? lastPullAt,
    Value<DateTime?>? lastPushAt,
    Value<DateTime>? pairedAt,
    Value<String?>? peerToken,
    Value<String?>? peerHost,
    Value<int?>? peerPort,
    Value<DateTime?>? lastSyncAt,
    Value<int>? autoSync,
    Value<int>? rowid,
  }) {
    return SyncStatesCompanion(
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      pairedAt: pairedAt ?? this.pairedAt,
      peerToken: peerToken ?? this.peerToken,
      peerHost: peerHost ?? this.peerHost,
      peerPort: peerPort ?? this.peerPort,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      autoSync: autoSync ?? this.autoSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (peerName.present) {
      map['peer_name'] = Variable<String>(peerName.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (lastPushAt.present) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (peerToken.present) {
      map['peer_token'] = Variable<String>(peerToken.value);
    }
    if (peerHost.present) {
      map['peer_host'] = Variable<String>(peerHost.value);
    }
    if (peerPort.present) {
      map['peer_port'] = Variable<int>(peerPort.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (autoSync.present) {
      map['auto_sync'] = Variable<int>(autoSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatesCompanion(')
          ..write('peerId: $peerId, ')
          ..write('peerName: $peerName, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('peerToken: $peerToken, ')
          ..write('peerHost: $peerHost, ')
          ..write('peerPort: $peerPort, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('autoSync: $autoSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDevicesTable extends LocalDevices
    with TableInfo<$LocalDevicesTable, LocalDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('light'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, themeMode, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDevice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalDevicesTable createAlias(String alias) {
    return $LocalDevicesTable(attachedDatabase, alias);
  }
}

class LocalDevice extends DataClass implements Insertable<LocalDevice> {
  final String id;
  final String name;

  /// 主题偏好：`light` / `dark` / `system`，缺省亮色。
  ///
  /// 放在这张表而不是 [SyncStates]：主题是**设备本地偏好**，
  /// 电脑上想用深色不代表手机上也要深色，不该跟着同步跑。
  final String themeMode;
  final DateTime createdAt;
  const LocalDevice({
    required this.id,
    required this.name,
    required this.themeMode,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['theme_mode'] = Variable<String>(themeMode);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalDevicesCompanion toCompanion(bool nullToAbsent) {
    return LocalDevicesCompanion(
      id: Value(id),
      name: Value(name),
      themeMode: Value(themeMode),
      createdAt: Value(createdAt),
    );
  }

  factory LocalDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDevice(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'themeMode': serializer.toJson<String>(themeMode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalDevice copyWith({
    String? id,
    String? name,
    String? themeMode,
    DateTime? createdAt,
  }) => LocalDevice(
    id: id ?? this.id,
    name: name ?? this.name,
    themeMode: themeMode ?? this.themeMode,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalDevice copyWithCompanion(LocalDevicesCompanion data) {
    return LocalDevice(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDevice(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('themeMode: $themeMode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, themeMode, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDevice &&
          other.id == this.id &&
          other.name == this.name &&
          other.themeMode == this.themeMode &&
          other.createdAt == this.createdAt);
}

class LocalDevicesCompanion extends UpdateCompanion<LocalDevice> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> themeMode;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalDevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDevicesCompanion.insert({
    required String id,
    required String name,
    this.themeMode = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<LocalDevice> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? themeMode,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (themeMode != null) 'theme_mode': themeMode,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? themeMode,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalDevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDevicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('themeMode: $themeMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictEntriesTable extends DictEntries
    with TableInfo<$DictEntriesTable, DictEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _builtInMeta = const VerificationMeta(
    'builtIn',
  );
  @override
  late final GeneratedColumn<int> builtIn = GeneratedColumn<int>(
    'built_in',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    label,
    parentId,
    sortOrder,
    builtIn,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dict_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('built_in')) {
      context.handle(
        _builtInMeta,
        builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      builtIn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}built_in'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $DictEntriesTable createAlias(String alias) {
    return $DictEntriesTable(attachedDatabase, alias);
  }
}

class DictEntry extends DataClass implements Insertable<DictEntry> {
  final String id;
  final String kind;
  final String label;
  final String? parentId;
  final int sortOrder;
  final int builtIn;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const DictEntry({
    required this.id,
    required this.kind,
    required this.label,
    this.parentId,
    required this.sortOrder,
    required this.builtIn,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['built_in'] = Variable<int>(builtIn);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  DictEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      label: Value(label),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      sortOrder: Value(sortOrder),
      builtIn: Value(builtIn),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory DictEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictEntry(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      label: serializer.fromJson<String>(json['label']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      builtIn: serializer.fromJson<int>(json['builtIn']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'label': serializer.toJson<String>(label),
      'parentId': serializer.toJson<String?>(parentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'builtIn': serializer.toJson<int>(builtIn),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  DictEntry copyWith({
    String? id,
    String? kind,
    String? label,
    Value<String?> parentId = const Value.absent(),
    int? sortOrder,
    int? builtIn,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => DictEntry(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    label: label ?? this.label,
    parentId: parentId.present ? parentId.value : this.parentId,
    sortOrder: sortOrder ?? this.sortOrder,
    builtIn: builtIn ?? this.builtIn,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  DictEntry copyWithCompanion(DictEntriesCompanion data) {
    return DictEntry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictEntry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('builtIn: $builtIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    label,
    parentId,
    sortOrder,
    builtIn,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictEntry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.label == this.label &&
          other.parentId == this.parentId &&
          other.sortOrder == this.sortOrder &&
          other.builtIn == this.builtIn &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class DictEntriesCompanion extends UpdateCompanion<DictEntry> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> label;
  final Value<String?> parentId;
  final Value<int> sortOrder;
  final Value<int> builtIn;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const DictEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictEntriesCompanion.insert({
    required String id,
    required String kind,
    required String label,
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.builtIn = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       label = Value(label),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<DictEntry> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<String>? parentId,
    Expression<int>? sortOrder,
    Expression<int>? builtIn,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (parentId != null) 'parent_id': parentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (builtIn != null) 'built_in': builtIn,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? label,
    Value<String?>? parentId,
    Value<int>? sortOrder,
    Value<int>? builtIn,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return DictEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      builtIn: builtIn ?? this.builtIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<int>(builtIn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('builtIn: $builtIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperatingCostsTable extends OperatingCosts
    with TableInfo<$OperatingCostsTable, OperatingCost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperatingCostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spentAtMeta = const VerificationMeta(
    'spentAt',
  );
  @override
  late final GeneratedColumn<DateTime> spentAt = GeneratedColumn<DateTime>(
    'spent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    spentAt,
    kind,
    amountCents,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operating_costs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OperatingCost> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('spent_at')) {
      context.handle(
        _spentAtMeta,
        spentAt.isAcceptableOrUnknown(data['spent_at']!, _spentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_spentAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OperatingCost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OperatingCost(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      spentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}spent_at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $OperatingCostsTable createAlias(String alias) {
    return $OperatingCostsTable(attachedDatabase, alias);
  }
}

class OperatingCost extends DataClass implements Insertable<OperatingCost> {
  final String id;

  /// 发生日期。看板按它做时间筛选，必填（默认今天）。
  final DateTime spentAt;

  /// 类别文本快照，来自字典 `dict_entries.kind = 'operating'`。
  ///
  /// 存文本不存外键，和商品表的品牌/分类一致：字典改名不回写历史。
  final String kind;
  final int amountCents;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  const OperatingCost({
    required this.id,
    required this.spentAt,
    required this.kind,
    required this.amountCents,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['spent_at'] = Variable<DateTime>(spentAt);
    map['kind'] = Variable<String>(kind);
    map['amount_cents'] = Variable<int>(amountCents);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  OperatingCostsCompanion toCompanion(bool nullToAbsent) {
    return OperatingCostsCompanion(
      id: Value(id),
      spentAt: Value(spentAt),
      kind: Value(kind),
      amountCents: Value(amountCents),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
    );
  }

  factory OperatingCost.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OperatingCost(
      id: serializer.fromJson<String>(json['id']),
      spentAt: serializer.fromJson<DateTime>(json['spentAt']),
      kind: serializer.fromJson<String>(json['kind']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'spentAt': serializer.toJson<DateTime>(spentAt),
      'kind': serializer.toJson<String>(kind),
      'amountCents': serializer.toJson<int>(amountCents),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  OperatingCost copyWith({
    String? id,
    DateTime? spentAt,
    String? kind,
    int? amountCents,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? deviceId,
  }) => OperatingCost(
    id: id ?? this.id,
    spentAt: spentAt ?? this.spentAt,
    kind: kind ?? this.kind,
    amountCents: amountCents ?? this.amountCents,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  OperatingCost copyWithCompanion(OperatingCostsCompanion data) {
    return OperatingCost(
      id: data.id.present ? data.id.value : this.id,
      spentAt: data.spentAt.present ? data.spentAt.value : this.spentAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OperatingCost(')
          ..write('id: $id, ')
          ..write('spentAt: $spentAt, ')
          ..write('kind: $kind, ')
          ..write('amountCents: $amountCents, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    spentAt,
    kind,
    amountCents,
    note,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperatingCost &&
          other.id == this.id &&
          other.spentAt == this.spentAt &&
          other.kind == this.kind &&
          other.amountCents == this.amountCents &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class OperatingCostsCompanion extends UpdateCompanion<OperatingCost> {
  final Value<String> id;
  final Value<DateTime> spentAt;
  final Value<String> kind;
  final Value<int> amountCents;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const OperatingCostsCompanion({
    this.id = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperatingCostsCompanion.insert({
    required String id,
    required DateTime spentAt,
    required String kind,
    required int amountCents,
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       spentAt = Value(spentAt),
       kind = Value(kind),
       amountCents = Value(amountCents),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<OperatingCost> custom({
    Expression<String>? id,
    Expression<DateTime>? spentAt,
    Expression<String>? kind,
    Expression<int>? amountCents,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spentAt != null) 'spent_at': spentAt,
      if (kind != null) 'kind': kind,
      if (amountCents != null) 'amount_cents': amountCents,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperatingCostsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? spentAt,
    Value<String>? kind,
    Value<int>? amountCents,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return OperatingCostsCompanion(
      id: id ?? this.id,
      spentAt: spentAt ?? this.spentAt,
      kind: kind ?? this.kind,
      amountCents: amountCents ?? this.amountCents,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (spentAt.present) {
      map['spent_at'] = Variable<DateTime>(spentAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperatingCostsCompanion(')
          ..write('id: $id, ')
          ..write('spentAt: $spentAt, ')
          ..write('kind: $kind, ')
          ..write('amountCents: $amountCents, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $SyncStatesTable syncStates = $SyncStatesTable(this);
  late final $LocalDevicesTable localDevices = $LocalDevicesTable(this);
  late final $DictEntriesTable dictEntries = $DictEntriesTable(this);
  late final $OperatingCostsTable operatingCosts = $OperatingCostsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    items,
    expenses,
    attachments,
    syncStates,
    localDevices,
    dictEntries,
    operatingCosts,
  ];
}

typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      required String id,
      required String title,
      Value<String?> category,
      Value<String?> brand,
      Value<String?> model,
      Value<String?> storage,
      Value<String?> color,
      Value<String?> conditionBought,
      Value<String?> conditionSold,
      Value<ItemStatus> status,
      Value<String?> sourcePlatform,
      Value<DateTime?> buyDate,
      required int buyPriceCents,
      Value<DateTime?> sellDate,
      Value<int?> sellPriceCents,
      Value<String?> sellPlatform,
      Value<String?> lotId,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int?> batteryHealth,
      Value<int?> listPriceCents,
      Value<int?> tradeInCents,
      Value<WarrantyStatus> warrantyStatus,
      Value<DateTime?> warrantyStart,
      Value<DateTime?> warrantyEnd,
      Value<int> rowid,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> category,
      Value<String?> brand,
      Value<String?> model,
      Value<String?> storage,
      Value<String?> color,
      Value<String?> conditionBought,
      Value<String?> conditionSold,
      Value<ItemStatus> status,
      Value<String?> sourcePlatform,
      Value<DateTime?> buyDate,
      Value<int> buyPriceCents,
      Value<DateTime?> sellDate,
      Value<int?> sellPriceCents,
      Value<String?> sellPlatform,
      Value<String?> lotId,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int?> batteryHealth,
      Value<int?> listPriceCents,
      Value<int?> tradeInCents,
      Value<WarrantyStatus> warrantyStatus,
      Value<DateTime?> warrantyStart,
      Value<DateTime?> warrantyEnd,
      Value<int> rowid,
    });

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storage => $composableBuilder(
    column: $table.storage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditionBought => $composableBuilder(
    column: $table.conditionBought,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditionSold => $composableBuilder(
    column: $table.conditionSold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemStatus, ItemStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get sourcePlatform => $composableBuilder(
    column: $table.sourcePlatform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get buyDate => $composableBuilder(
    column: $table.buyDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get buyPriceCents => $composableBuilder(
    column: $table.buyPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sellDate => $composableBuilder(
    column: $table.sellDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellPriceCents => $composableBuilder(
    column: $table.sellPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellPlatform => $composableBuilder(
    column: $table.sellPlatform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lotId => $composableBuilder(
    column: $table.lotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batteryHealth => $composableBuilder(
    column: $table.batteryHealth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listPriceCents => $composableBuilder(
    column: $table.listPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tradeInCents => $composableBuilder(
    column: $table.tradeInCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WarrantyStatus, WarrantyStatus, String>
  get warrantyStatus => $composableBuilder(
    column: $table.warrantyStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get warrantyStart => $composableBuilder(
    column: $table.warrantyStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get warrantyEnd => $composableBuilder(
    column: $table.warrantyEnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storage => $composableBuilder(
    column: $table.storage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditionBought => $composableBuilder(
    column: $table.conditionBought,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditionSold => $composableBuilder(
    column: $table.conditionSold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePlatform => $composableBuilder(
    column: $table.sourcePlatform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get buyDate => $composableBuilder(
    column: $table.buyDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get buyPriceCents => $composableBuilder(
    column: $table.buyPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sellDate => $composableBuilder(
    column: $table.sellDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellPriceCents => $composableBuilder(
    column: $table.sellPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellPlatform => $composableBuilder(
    column: $table.sellPlatform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lotId => $composableBuilder(
    column: $table.lotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batteryHealth => $composableBuilder(
    column: $table.batteryHealth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listPriceCents => $composableBuilder(
    column: $table.listPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tradeInCents => $composableBuilder(
    column: $table.tradeInCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warrantyStatus => $composableBuilder(
    column: $table.warrantyStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get warrantyStart => $composableBuilder(
    column: $table.warrantyStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get warrantyEnd => $composableBuilder(
    column: $table.warrantyEnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get storage =>
      $composableBuilder(column: $table.storage, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get conditionBought => $composableBuilder(
    column: $table.conditionBought,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conditionSold => $composableBuilder(
    column: $table.conditionSold,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get sourcePlatform => $composableBuilder(
    column: $table.sourcePlatform,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get buyDate =>
      $composableBuilder(column: $table.buyDate, builder: (column) => column);

  GeneratedColumn<int> get buyPriceCents => $composableBuilder(
    column: $table.buyPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sellDate =>
      $composableBuilder(column: $table.sellDate, builder: (column) => column);

  GeneratedColumn<int> get sellPriceCents => $composableBuilder(
    column: $table.sellPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellPlatform => $composableBuilder(
    column: $table.sellPlatform,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lotId =>
      $composableBuilder(column: $table.lotId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get batteryHealth => $composableBuilder(
    column: $table.batteryHealth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get listPriceCents => $composableBuilder(
    column: $table.listPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tradeInCents => $composableBuilder(
    column: $table.tradeInCents,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WarrantyStatus, String> get warrantyStatus =>
      $composableBuilder(
        column: $table.warrantyStatus,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get warrantyStart => $composableBuilder(
    column: $table.warrantyStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get warrantyEnd => $composableBuilder(
    column: $table.warrantyEnd,
    builder: (column) => column,
  );
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
          Item,
          PrefetchHooks Function()
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> storage = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> conditionBought = const Value.absent(),
                Value<String?> conditionSold = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<String?> sourcePlatform = const Value.absent(),
                Value<DateTime?> buyDate = const Value.absent(),
                Value<int> buyPriceCents = const Value.absent(),
                Value<DateTime?> sellDate = const Value.absent(),
                Value<int?> sellPriceCents = const Value.absent(),
                Value<String?> sellPlatform = const Value.absent(),
                Value<String?> lotId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int?> batteryHealth = const Value.absent(),
                Value<int?> listPriceCents = const Value.absent(),
                Value<int?> tradeInCents = const Value.absent(),
                Value<WarrantyStatus> warrantyStatus = const Value.absent(),
                Value<DateTime?> warrantyStart = const Value.absent(),
                Value<DateTime?> warrantyEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                title: title,
                category: category,
                brand: brand,
                model: model,
                storage: storage,
                color: color,
                conditionBought: conditionBought,
                conditionSold: conditionSold,
                status: status,
                sourcePlatform: sourcePlatform,
                buyDate: buyDate,
                buyPriceCents: buyPriceCents,
                sellDate: sellDate,
                sellPriceCents: sellPriceCents,
                sellPlatform: sellPlatform,
                lotId: lotId,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                batteryHealth: batteryHealth,
                listPriceCents: listPriceCents,
                tradeInCents: tradeInCents,
                warrantyStatus: warrantyStatus,
                warrantyStart: warrantyStart,
                warrantyEnd: warrantyEnd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> category = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> storage = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> conditionBought = const Value.absent(),
                Value<String?> conditionSold = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<String?> sourcePlatform = const Value.absent(),
                Value<DateTime?> buyDate = const Value.absent(),
                required int buyPriceCents,
                Value<DateTime?> sellDate = const Value.absent(),
                Value<int?> sellPriceCents = const Value.absent(),
                Value<String?> sellPlatform = const Value.absent(),
                Value<String?> lotId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int?> batteryHealth = const Value.absent(),
                Value<int?> listPriceCents = const Value.absent(),
                Value<int?> tradeInCents = const Value.absent(),
                Value<WarrantyStatus> warrantyStatus = const Value.absent(),
                Value<DateTime?> warrantyStart = const Value.absent(),
                Value<DateTime?> warrantyEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                title: title,
                category: category,
                brand: brand,
                model: model,
                storage: storage,
                color: color,
                conditionBought: conditionBought,
                conditionSold: conditionSold,
                status: status,
                sourcePlatform: sourcePlatform,
                buyDate: buyDate,
                buyPriceCents: buyPriceCents,
                sellDate: sellDate,
                sellPriceCents: sellPriceCents,
                sellPlatform: sellPlatform,
                lotId: lotId,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                batteryHealth: batteryHealth,
                listPriceCents: listPriceCents,
                tradeInCents: tradeInCents,
                warrantyStatus: warrantyStatus,
                warrantyStart: warrantyStart,
                warrantyEnd: warrantyEnd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
      Item,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String id,
      required String itemId,
      required ExpenseKind kind,
      required ExpenseSide side,
      required int amountCents,
      Value<DateTime?> incurredAt,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<ExpenseKind> kind,
      Value<ExpenseSide> side,
      Value<int> amountCents,
      Value<DateTime?> incurredAt,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExpenseKind, ExpenseKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ExpenseSide, ExpenseSide, String> get side =>
      $composableBuilder(
        column: $table.side,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get incurredAt => $composableBuilder(
    column: $table.incurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get incurredAt => $composableBuilder(
    column: $table.incurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExpenseKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExpenseSide, String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get incurredAt => $composableBuilder(
    column: $table.incurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
          Expense,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<ExpenseKind> kind = const Value.absent(),
                Value<ExpenseSide> side = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<DateTime?> incurredAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                itemId: itemId,
                kind: kind,
                side: side,
                amountCents: amountCents,
                incurredAt: incurredAt,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required ExpenseKind kind,
                required ExpenseSide side,
                required int amountCents,
                Value<DateTime?> incurredAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                itemId: itemId,
                kind: kind,
                side: side,
                amountCents: amountCents,
                incurredAt: incurredAt,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, BaseReferences<_$AppDatabase, $ExpensesTable, Expense>),
      Expense,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String itemId,
      required AttachmentRole role,
      Value<String> mime,
      required Uint8List bytes,
      Value<Uint8List?> thumb,
      Value<int?> width,
      Value<int?> height,
      Value<int> sizeBytes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<AttachmentRole> role,
      Value<String> mime,
      Value<Uint8List> bytes,
      Value<Uint8List?> thumb,
      Value<int?> width,
      Value<int?> height,
      Value<int> sizeBytes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AttachmentRole, AttachmentRole, String>
  get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AttachmentRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<Uint8List> get thumb =>
      $composableBuilder(column: $table.thumb, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (
            Attachment,
            BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>,
          ),
          Attachment,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<AttachmentRole> role = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<Uint8List?> thumb = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                itemId: itemId,
                role: role,
                mime: mime,
                bytes: bytes,
                thumb: thumb,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required AttachmentRole role,
                Value<String> mime = const Value.absent(),
                required Uint8List bytes,
                Value<Uint8List?> thumb = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                itemId: itemId,
                role: role,
                mime: mime,
                bytes: bytes,
                thumb: thumb,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (
        Attachment,
        BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>,
      ),
      Attachment,
      PrefetchHooks Function()
    >;
typedef $$SyncStatesTableCreateCompanionBuilder =
    SyncStatesCompanion Function({
      required String peerId,
      Value<String?> peerName,
      Value<DateTime?> lastPullAt,
      Value<DateTime?> lastPushAt,
      required DateTime pairedAt,
      Value<String?> peerToken,
      Value<String?> peerHost,
      Value<int?> peerPort,
      Value<DateTime?> lastSyncAt,
      Value<int> autoSync,
      Value<int> rowid,
    });
typedef $$SyncStatesTableUpdateCompanionBuilder =
    SyncStatesCompanion Function({
      Value<String> peerId,
      Value<String?> peerName,
      Value<DateTime?> lastPullAt,
      Value<DateTime?> lastPushAt,
      Value<DateTime> pairedAt,
      Value<String?> peerToken,
      Value<String?> peerHost,
      Value<int?> peerPort,
      Value<DateTime?> lastSyncAt,
      Value<int> autoSync,
      Value<int> rowid,
    });

class $$SyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerName => $composableBuilder(
    column: $table.peerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerToken => $composableBuilder(
    column: $table.peerToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerHost => $composableBuilder(
    column: $table.peerHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get peerPort => $composableBuilder(
    column: $table.peerPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autoSync => $composableBuilder(
    column: $table.autoSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerName => $composableBuilder(
    column: $table.peerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerToken => $composableBuilder(
    column: $table.peerToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerHost => $composableBuilder(
    column: $table.peerHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get peerPort => $composableBuilder(
    column: $table.peerPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autoSync => $composableBuilder(
    column: $table.autoSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatesTable> {
  $$SyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<String> get peerName =>
      $composableBuilder(column: $table.peerName, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<String> get peerToken =>
      $composableBuilder(column: $table.peerToken, builder: (column) => column);

  GeneratedColumn<String> get peerHost =>
      $composableBuilder(column: $table.peerHost, builder: (column) => column);

  GeneratedColumn<int> get peerPort =>
      $composableBuilder(column: $table.peerPort, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get autoSync =>
      $composableBuilder(column: $table.autoSync, builder: (column) => column);
}

class $$SyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatesTable,
          SyncState,
          $$SyncStatesTableFilterComposer,
          $$SyncStatesTableOrderingComposer,
          $$SyncStatesTableAnnotationComposer,
          $$SyncStatesTableCreateCompanionBuilder,
          $$SyncStatesTableUpdateCompanionBuilder,
          (
            SyncState,
            BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>,
          ),
          SyncState,
          PrefetchHooks Function()
        > {
  $$SyncStatesTableTableManager(_$AppDatabase db, $SyncStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> peerId = const Value.absent(),
                Value<String?> peerName = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<String?> peerToken = const Value.absent(),
                Value<String?> peerHost = const Value.absent(),
                Value<int?> peerPort = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> autoSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion(
                peerId: peerId,
                peerName: peerName,
                lastPullAt: lastPullAt,
                lastPushAt: lastPushAt,
                pairedAt: pairedAt,
                peerToken: peerToken,
                peerHost: peerHost,
                peerPort: peerPort,
                lastSyncAt: lastSyncAt,
                autoSync: autoSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String peerId,
                Value<String?> peerName = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                required DateTime pairedAt,
                Value<String?> peerToken = const Value.absent(),
                Value<String?> peerHost = const Value.absent(),
                Value<int?> peerPort = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> autoSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatesCompanion.insert(
                peerId: peerId,
                peerName: peerName,
                lastPullAt: lastPullAt,
                lastPushAt: lastPushAt,
                pairedAt: pairedAt,
                peerToken: peerToken,
                peerHost: peerHost,
                peerPort: peerPort,
                lastSyncAt: lastSyncAt,
                autoSync: autoSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatesTable,
      SyncState,
      $$SyncStatesTableFilterComposer,
      $$SyncStatesTableOrderingComposer,
      $$SyncStatesTableAnnotationComposer,
      $$SyncStatesTableCreateCompanionBuilder,
      $$SyncStatesTableUpdateCompanionBuilder,
      (SyncState, BaseReferences<_$AppDatabase, $SyncStatesTable, SyncState>),
      SyncState,
      PrefetchHooks Function()
    >;
typedef $$LocalDevicesTableCreateCompanionBuilder =
    LocalDevicesCompanion Function({
      required String id,
      required String name,
      Value<String> themeMode,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalDevicesTableUpdateCompanionBuilder =
    LocalDevicesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> themeMode,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDevicesTable> {
  $$LocalDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDevicesTable> {
  $$LocalDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDevicesTable> {
  $$LocalDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDevicesTable,
          LocalDevice,
          $$LocalDevicesTableFilterComposer,
          $$LocalDevicesTableOrderingComposer,
          $$LocalDevicesTableAnnotationComposer,
          $$LocalDevicesTableCreateCompanionBuilder,
          $$LocalDevicesTableUpdateCompanionBuilder,
          (
            LocalDevice,
            BaseReferences<_$AppDatabase, $LocalDevicesTable, LocalDevice>,
          ),
          LocalDevice,
          PrefetchHooks Function()
        > {
  $$LocalDevicesTableTableManager(_$AppDatabase db, $LocalDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDevicesCompanion(
                id: id,
                name: name,
                themeMode: themeMode,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> themeMode = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalDevicesCompanion.insert(
                id: id,
                name: name,
                themeMode: themeMode,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDevicesTable,
      LocalDevice,
      $$LocalDevicesTableFilterComposer,
      $$LocalDevicesTableOrderingComposer,
      $$LocalDevicesTableAnnotationComposer,
      $$LocalDevicesTableCreateCompanionBuilder,
      $$LocalDevicesTableUpdateCompanionBuilder,
      (
        LocalDevice,
        BaseReferences<_$AppDatabase, $LocalDevicesTable, LocalDevice>,
      ),
      LocalDevice,
      PrefetchHooks Function()
    >;
typedef $$DictEntriesTableCreateCompanionBuilder =
    DictEntriesCompanion Function({
      required String id,
      required String kind,
      required String label,
      Value<String?> parentId,
      Value<int> sortOrder,
      Value<int> builtIn,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$DictEntriesTableUpdateCompanionBuilder =
    DictEntriesCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> label,
      Value<String?> parentId,
      Value<int> sortOrder,
      Value<int> builtIn,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$DictEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictEntriesTable> {
  $$DictEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictEntriesTable> {
  $$DictEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get builtIn => $composableBuilder(
    column: $table.builtIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictEntriesTable> {
  $$DictEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$DictEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictEntriesTable,
          DictEntry,
          $$DictEntriesTableFilterComposer,
          $$DictEntriesTableOrderingComposer,
          $$DictEntriesTableAnnotationComposer,
          $$DictEntriesTableCreateCompanionBuilder,
          $$DictEntriesTableUpdateCompanionBuilder,
          (
            DictEntry,
            BaseReferences<_$AppDatabase, $DictEntriesTable, DictEntry>,
          ),
          DictEntry,
          PrefetchHooks Function()
        > {
  $$DictEntriesTableTableManager(_$AppDatabase db, $DictEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> builtIn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictEntriesCompanion(
                id: id,
                kind: kind,
                label: label,
                parentId: parentId,
                sortOrder: sortOrder,
                builtIn: builtIn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String label,
                Value<String?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> builtIn = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => DictEntriesCompanion.insert(
                id: id,
                kind: kind,
                label: label,
                parentId: parentId,
                sortOrder: sortOrder,
                builtIn: builtIn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictEntriesTable,
      DictEntry,
      $$DictEntriesTableFilterComposer,
      $$DictEntriesTableOrderingComposer,
      $$DictEntriesTableAnnotationComposer,
      $$DictEntriesTableCreateCompanionBuilder,
      $$DictEntriesTableUpdateCompanionBuilder,
      (DictEntry, BaseReferences<_$AppDatabase, $DictEntriesTable, DictEntry>),
      DictEntry,
      PrefetchHooks Function()
    >;
typedef $$OperatingCostsTableCreateCompanionBuilder =
    OperatingCostsCompanion Function({
      required String id,
      required DateTime spentAt,
      required String kind,
      required int amountCents,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$OperatingCostsTableUpdateCompanionBuilder =
    OperatingCostsCompanion Function({
      Value<String> id,
      Value<DateTime> spentAt,
      Value<String> kind,
      Value<int> amountCents,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$OperatingCostsTableFilterComposer
    extends Composer<_$AppDatabase, $OperatingCostsTable> {
  $$OperatingCostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OperatingCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperatingCostsTable> {
  $$OperatingCostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OperatingCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperatingCostsTable> {
  $$OperatingCostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get spentAt =>
      $composableBuilder(column: $table.spentAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$OperatingCostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperatingCostsTable,
          OperatingCost,
          $$OperatingCostsTableFilterComposer,
          $$OperatingCostsTableOrderingComposer,
          $$OperatingCostsTableAnnotationComposer,
          $$OperatingCostsTableCreateCompanionBuilder,
          $$OperatingCostsTableUpdateCompanionBuilder,
          (
            OperatingCost,
            BaseReferences<_$AppDatabase, $OperatingCostsTable, OperatingCost>,
          ),
          OperatingCost,
          PrefetchHooks Function()
        > {
  $$OperatingCostsTableTableManager(
    _$AppDatabase db,
    $OperatingCostsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperatingCostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperatingCostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperatingCostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> spentAt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperatingCostsCompanion(
                id: id,
                spentAt: spentAt,
                kind: kind,
                amountCents: amountCents,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime spentAt,
                required String kind,
                required int amountCents,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => OperatingCostsCompanion.insert(
                id: id,
                spentAt: spentAt,
                kind: kind,
                amountCents: amountCents,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OperatingCostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperatingCostsTable,
      OperatingCost,
      $$OperatingCostsTableFilterComposer,
      $$OperatingCostsTableOrderingComposer,
      $$OperatingCostsTableAnnotationComposer,
      $$OperatingCostsTableCreateCompanionBuilder,
      $$OperatingCostsTableUpdateCompanionBuilder,
      (
        OperatingCost,
        BaseReferences<_$AppDatabase, $OperatingCostsTable, OperatingCost>,
      ),
      OperatingCost,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$SyncStatesTableTableManager get syncStates =>
      $$SyncStatesTableTableManager(_db, _db.syncStates);
  $$LocalDevicesTableTableManager get localDevices =>
      $$LocalDevicesTableTableManager(_db, _db.localDevices);
  $$DictEntriesTableTableManager get dictEntries =>
      $$DictEntriesTableTableManager(_db, _db.dictEntries);
  $$OperatingCostsTableTableManager get operatingCosts =>
      $$OperatingCostsTableTableManager(_db, _db.operatingCosts);
}
