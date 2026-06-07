// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SurahsTable extends Surahs with TableInfo<$SurahsTable, Surah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameTransliterationMeta =
      const VerificationMeta('nameTransliteration');
  @override
  late final GeneratedColumn<String> nameTransliteration =
      GeneratedColumn<String>(
        'name_transliteration',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _revelationTypeMeta = const VerificationMeta(
    'revelationType',
  );
  @override
  late final GeneratedColumn<String> revelationType = GeneratedColumn<String>(
    'revelation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahCountMeta = const VerificationMeta(
    'ayahCount',
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderInMushafMeta = const VerificationMeta(
    'orderInMushaf',
  );
  @override
  late final GeneratedColumn<int> orderInMushaf = GeneratedColumn<int>(
    'order_in_mushaf',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameAr,
    nameEn,
    nameTransliteration,
    revelationType,
    ayahCount,
    orderInMushaf,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Surah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_transliteration')) {
      context.handle(
        _nameTransliterationMeta,
        nameTransliteration.isAcceptableOrUnknown(
          data['name_transliteration']!,
          _nameTransliterationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameTransliterationMeta);
    }
    if (data.containsKey('revelation_type')) {
      context.handle(
        _revelationTypeMeta,
        revelationType.isAcceptableOrUnknown(
          data['revelation_type']!,
          _revelationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_revelationTypeMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(
        _ayahCountMeta,
        ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('order_in_mushaf')) {
      context.handle(
        _orderInMushafMeta,
        orderInMushaf.isAcceptableOrUnknown(
          data['order_in_mushaf']!,
          _orderInMushafMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderInMushafMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Surah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Surah(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameTransliteration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_transliteration'],
      )!,
      revelationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revelation_type'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
      orderInMushaf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_in_mushaf'],
      )!,
    );
  }

  @override
  $SurahsTable createAlias(String alias) {
    return $SurahsTable(attachedDatabase, alias);
  }
}

class Surah extends DataClass implements Insertable<Surah> {
  final int id;
  final String nameAr;
  final String nameEn;
  final String nameTransliteration;
  final String revelationType;
  final int ayahCount;
  final int orderInMushaf;
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameTransliteration,
    required this.revelationType,
    required this.ayahCount,
    required this.orderInMushaf,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    map['name_transliteration'] = Variable<String>(nameTransliteration);
    map['revelation_type'] = Variable<String>(revelationType);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['order_in_mushaf'] = Variable<int>(orderInMushaf);
    return map;
  }

  SurahsCompanion toCompanion(bool nullToAbsent) {
    return SurahsCompanion(
      id: Value(id),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      nameTransliteration: Value(nameTransliteration),
      revelationType: Value(revelationType),
      ayahCount: Value(ayahCount),
      orderInMushaf: Value(orderInMushaf),
    );
  }

  factory Surah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Surah(
      id: serializer.fromJson<int>(json['id']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameTransliteration: serializer.fromJson<String>(
        json['nameTransliteration'],
      ),
      revelationType: serializer.fromJson<String>(json['revelationType']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      orderInMushaf: serializer.fromJson<int>(json['orderInMushaf']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameTransliteration': serializer.toJson<String>(nameTransliteration),
      'revelationType': serializer.toJson<String>(revelationType),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'orderInMushaf': serializer.toJson<int>(orderInMushaf),
    };
  }

  Surah copyWith({
    int? id,
    String? nameAr,
    String? nameEn,
    String? nameTransliteration,
    String? revelationType,
    int? ayahCount,
    int? orderInMushaf,
  }) => Surah(
    id: id ?? this.id,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    nameTransliteration: nameTransliteration ?? this.nameTransliteration,
    revelationType: revelationType ?? this.revelationType,
    ayahCount: ayahCount ?? this.ayahCount,
    orderInMushaf: orderInMushaf ?? this.orderInMushaf,
  );
  Surah copyWithCompanion(SurahsCompanion data) {
    return Surah(
      id: data.id.present ? data.id.value : this.id,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameTransliteration: data.nameTransliteration.present
          ? data.nameTransliteration.value
          : this.nameTransliteration,
      revelationType: data.revelationType.present
          ? data.revelationType.value
          : this.revelationType,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      orderInMushaf: data.orderInMushaf.present
          ? data.orderInMushaf.value
          : this.orderInMushaf,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Surah(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameTransliteration: $nameTransliteration, ')
          ..write('revelationType: $revelationType, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('orderInMushaf: $orderInMushaf')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nameAr,
    nameEn,
    nameTransliteration,
    revelationType,
    ayahCount,
    orderInMushaf,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Surah &&
          other.id == this.id &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.nameTransliteration == this.nameTransliteration &&
          other.revelationType == this.revelationType &&
          other.ayahCount == this.ayahCount &&
          other.orderInMushaf == this.orderInMushaf);
}

class SurahsCompanion extends UpdateCompanion<Surah> {
  final Value<int> id;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<String> nameTransliteration;
  final Value<String> revelationType;
  final Value<int> ayahCount;
  final Value<int> orderInMushaf;
  const SurahsCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameTransliteration = const Value.absent(),
    this.revelationType = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.orderInMushaf = const Value.absent(),
  });
  SurahsCompanion.insert({
    this.id = const Value.absent(),
    required String nameAr,
    required String nameEn,
    required String nameTransliteration,
    required String revelationType,
    required int ayahCount,
    required int orderInMushaf,
  }) : nameAr = Value(nameAr),
       nameEn = Value(nameEn),
       nameTransliteration = Value(nameTransliteration),
       revelationType = Value(revelationType),
       ayahCount = Value(ayahCount),
       orderInMushaf = Value(orderInMushaf);
  static Insertable<Surah> custom({
    Expression<int>? id,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? nameTransliteration,
    Expression<String>? revelationType,
    Expression<int>? ayahCount,
    Expression<int>? orderInMushaf,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (nameTransliteration != null)
        'name_transliteration': nameTransliteration,
      if (revelationType != null) 'revelation_type': revelationType,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (orderInMushaf != null) 'order_in_mushaf': orderInMushaf,
    });
  }

  SurahsCompanion copyWith({
    Value<int>? id,
    Value<String>? nameAr,
    Value<String>? nameEn,
    Value<String>? nameTransliteration,
    Value<String>? revelationType,
    Value<int>? ayahCount,
    Value<int>? orderInMushaf,
  }) {
    return SurahsCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      nameTransliteration: nameTransliteration ?? this.nameTransliteration,
      revelationType: revelationType ?? this.revelationType,
      ayahCount: ayahCount ?? this.ayahCount,
      orderInMushaf: orderInMushaf ?? this.orderInMushaf,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameTransliteration.present) {
      map['name_transliteration'] = Variable<String>(nameTransliteration.value);
    }
    if (revelationType.present) {
      map['revelation_type'] = Variable<String>(revelationType.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (orderInMushaf.present) {
      map['order_in_mushaf'] = Variable<int>(orderInMushaf.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahsCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameTransliteration: $nameTransliteration, ')
          ..write('revelationType: $revelationType, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('orderInMushaf: $orderInMushaf')
          ..write(')'))
        .toString();
  }
}

class $AyahsTable extends Ayahs with TableInfo<$AyahsTable, Ayah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surahIdMeta = const VerificationMeta(
    'surahId',
  );
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surahs (id)',
    ),
  );
  static const VerificationMeta _ayahNumberMeta = const VerificationMeta(
    'ayahNumber',
  );
  @override
  late final GeneratedColumn<int> ayahNumber = GeneratedColumn<int>(
    'ayah_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _juzMeta = const VerificationMeta('juz');
  @override
  late final GeneratedColumn<int> juz = GeneratedColumn<int>(
    'juz',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hizbMeta = const VerificationMeta('hizb');
  @override
  late final GeneratedColumn<int> hizb = GeneratedColumn<int>(
    'hizb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textUthmaniMeta = const VerificationMeta(
    'textUthmani',
  );
  @override
  late final GeneratedColumn<String> textUthmani = GeneratedColumn<String>(
    'text_uthmani',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textNormalizedMeta = const VerificationMeta(
    'textNormalized',
  );
  @override
  late final GeneratedColumn<String> textNormalized = GeneratedColumn<String>(
    'text_normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surahId,
    ayahNumber,
    page,
    juz,
    hizb,
    textUthmani,
    textNormalized,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ayah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah_id')) {
      context.handle(
        _surahIdMeta,
        surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('ayah_number')) {
      context.handle(
        _ayahNumberMeta,
        ayahNumber.isAcceptableOrUnknown(data['ayah_number']!, _ayahNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahNumberMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    }
    if (data.containsKey('juz')) {
      context.handle(
        _juzMeta,
        juz.isAcceptableOrUnknown(data['juz']!, _juzMeta),
      );
    }
    if (data.containsKey('hizb')) {
      context.handle(
        _hizbMeta,
        hizb.isAcceptableOrUnknown(data['hizb']!, _hizbMeta),
      );
    }
    if (data.containsKey('text_uthmani')) {
      context.handle(
        _textUthmaniMeta,
        textUthmani.isAcceptableOrUnknown(
          data['text_uthmani']!,
          _textUthmaniMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textUthmaniMeta);
    }
    if (data.containsKey('text_normalized')) {
      context.handle(
        _textNormalizedMeta,
        textNormalized.isAcceptableOrUnknown(
          data['text_normalized']!,
          _textNormalizedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textNormalizedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ayah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ayah(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      ayahNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_number'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      ),
      juz: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}juz'],
      ),
      hizb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hizb'],
      ),
      textUthmani: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_uthmani'],
      )!,
      textNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_normalized'],
      )!,
    );
  }

  @override
  $AyahsTable createAlias(String alias) {
    return $AyahsTable(attachedDatabase, alias);
  }
}

class Ayah extends DataClass implements Insertable<Ayah> {
  final int id;
  final int surahId;
  final int ayahNumber;
  final int? page;
  final int? juz;
  final int? hizb;
  final String textUthmani;
  final String textNormalized;
  const Ayah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    this.page,
    this.juz,
    this.hizb,
    required this.textUthmani,
    required this.textNormalized,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah_id'] = Variable<int>(surahId);
    map['ayah_number'] = Variable<int>(ayahNumber);
    if (!nullToAbsent || page != null) {
      map['page'] = Variable<int>(page);
    }
    if (!nullToAbsent || juz != null) {
      map['juz'] = Variable<int>(juz);
    }
    if (!nullToAbsent || hizb != null) {
      map['hizb'] = Variable<int>(hizb);
    }
    map['text_uthmani'] = Variable<String>(textUthmani);
    map['text_normalized'] = Variable<String>(textNormalized);
    return map;
  }

  AyahsCompanion toCompanion(bool nullToAbsent) {
    return AyahsCompanion(
      id: Value(id),
      surahId: Value(surahId),
      ayahNumber: Value(ayahNumber),
      page: page == null && nullToAbsent ? const Value.absent() : Value(page),
      juz: juz == null && nullToAbsent ? const Value.absent() : Value(juz),
      hizb: hizb == null && nullToAbsent ? const Value.absent() : Value(hizb),
      textUthmani: Value(textUthmani),
      textNormalized: Value(textNormalized),
    );
  }

  factory Ayah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ayah(
      id: serializer.fromJson<int>(json['id']),
      surahId: serializer.fromJson<int>(json['surahId']),
      ayahNumber: serializer.fromJson<int>(json['ayahNumber']),
      page: serializer.fromJson<int?>(json['page']),
      juz: serializer.fromJson<int?>(json['juz']),
      hizb: serializer.fromJson<int?>(json['hizb']),
      textUthmani: serializer.fromJson<String>(json['textUthmani']),
      textNormalized: serializer.fromJson<String>(json['textNormalized']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahId': serializer.toJson<int>(surahId),
      'ayahNumber': serializer.toJson<int>(ayahNumber),
      'page': serializer.toJson<int?>(page),
      'juz': serializer.toJson<int?>(juz),
      'hizb': serializer.toJson<int?>(hizb),
      'textUthmani': serializer.toJson<String>(textUthmani),
      'textNormalized': serializer.toJson<String>(textNormalized),
    };
  }

  Ayah copyWith({
    int? id,
    int? surahId,
    int? ayahNumber,
    Value<int?> page = const Value.absent(),
    Value<int?> juz = const Value.absent(),
    Value<int?> hizb = const Value.absent(),
    String? textUthmani,
    String? textNormalized,
  }) => Ayah(
    id: id ?? this.id,
    surahId: surahId ?? this.surahId,
    ayahNumber: ayahNumber ?? this.ayahNumber,
    page: page.present ? page.value : this.page,
    juz: juz.present ? juz.value : this.juz,
    hizb: hizb.present ? hizb.value : this.hizb,
    textUthmani: textUthmani ?? this.textUthmani,
    textNormalized: textNormalized ?? this.textNormalized,
  );
  Ayah copyWithCompanion(AyahsCompanion data) {
    return Ayah(
      id: data.id.present ? data.id.value : this.id,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      ayahNumber: data.ayahNumber.present
          ? data.ayahNumber.value
          : this.ayahNumber,
      page: data.page.present ? data.page.value : this.page,
      juz: data.juz.present ? data.juz.value : this.juz,
      hizb: data.hizb.present ? data.hizb.value : this.hizb,
      textUthmani: data.textUthmani.present
          ? data.textUthmani.value
          : this.textUthmani,
      textNormalized: data.textNormalized.present
          ? data.textNormalized.value
          : this.textNormalized,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ayah(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('page: $page, ')
          ..write('juz: $juz, ')
          ..write('hizb: $hizb, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textNormalized: $textNormalized')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    surahId,
    ayahNumber,
    page,
    juz,
    hizb,
    textUthmani,
    textNormalized,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ayah &&
          other.id == this.id &&
          other.surahId == this.surahId &&
          other.ayahNumber == this.ayahNumber &&
          other.page == this.page &&
          other.juz == this.juz &&
          other.hizb == this.hizb &&
          other.textUthmani == this.textUthmani &&
          other.textNormalized == this.textNormalized);
}

class AyahsCompanion extends UpdateCompanion<Ayah> {
  final Value<int> id;
  final Value<int> surahId;
  final Value<int> ayahNumber;
  final Value<int?> page;
  final Value<int?> juz;
  final Value<int?> hizb;
  final Value<String> textUthmani;
  final Value<String> textNormalized;
  const AyahsCompanion({
    this.id = const Value.absent(),
    this.surahId = const Value.absent(),
    this.ayahNumber = const Value.absent(),
    this.page = const Value.absent(),
    this.juz = const Value.absent(),
    this.hizb = const Value.absent(),
    this.textUthmani = const Value.absent(),
    this.textNormalized = const Value.absent(),
  });
  AyahsCompanion.insert({
    this.id = const Value.absent(),
    required int surahId,
    required int ayahNumber,
    this.page = const Value.absent(),
    this.juz = const Value.absent(),
    this.hizb = const Value.absent(),
    required String textUthmani,
    required String textNormalized,
  }) : surahId = Value(surahId),
       ayahNumber = Value(ayahNumber),
       textUthmani = Value(textUthmani),
       textNormalized = Value(textNormalized);
  static Insertable<Ayah> custom({
    Expression<int>? id,
    Expression<int>? surahId,
    Expression<int>? ayahNumber,
    Expression<int>? page,
    Expression<int>? juz,
    Expression<int>? hizb,
    Expression<String>? textUthmani,
    Expression<String>? textNormalized,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surahId != null) 'surah_id': surahId,
      if (ayahNumber != null) 'ayah_number': ayahNumber,
      if (page != null) 'page': page,
      if (juz != null) 'juz': juz,
      if (hizb != null) 'hizb': hizb,
      if (textUthmani != null) 'text_uthmani': textUthmani,
      if (textNormalized != null) 'text_normalized': textNormalized,
    });
  }

  AyahsCompanion copyWith({
    Value<int>? id,
    Value<int>? surahId,
    Value<int>? ayahNumber,
    Value<int?>? page,
    Value<int?>? juz,
    Value<int?>? hizb,
    Value<String>? textUthmani,
    Value<String>? textNormalized,
  }) {
    return AyahsCompanion(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      page: page ?? this.page,
      juz: juz ?? this.juz,
      hizb: hizb ?? this.hizb,
      textUthmani: textUthmani ?? this.textUthmani,
      textNormalized: textNormalized ?? this.textNormalized,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (ayahNumber.present) {
      map['ayah_number'] = Variable<int>(ayahNumber.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (juz.present) {
      map['juz'] = Variable<int>(juz.value);
    }
    if (hizb.present) {
      map['hizb'] = Variable<int>(hizb.value);
    }
    if (textUthmani.present) {
      map['text_uthmani'] = Variable<String>(textUthmani.value);
    }
    if (textNormalized.present) {
      map['text_normalized'] = Variable<String>(textNormalized.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahsCompanion(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('page: $page, ')
          ..write('juz: $juz, ')
          ..write('hizb: $hizb, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textNormalized: $textNormalized')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayahs (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arabicMeta = const VerificationMeta('arabic');
  @override
  late final GeneratedColumn<String> arabic = GeneratedColumn<String>(
    'arabic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedMeta = const VerificationMeta(
    'normalized',
  );
  @override
  late final GeneratedColumn<String> normalized = GeneratedColumn<String>(
    'normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rootMeta = const VerificationMeta('root');
  @override
  late final GeneratedColumn<String> root = GeneratedColumn<String>(
    'root',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ayahId,
    position,
    arabic,
    normalized,
    translation,
    lemma,
    root,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('arabic')) {
      context.handle(
        _arabicMeta,
        arabic.isAcceptableOrUnknown(data['arabic']!, _arabicMeta),
      );
    } else if (isInserting) {
      context.missing(_arabicMeta);
    }
    if (data.containsKey('normalized')) {
      context.handle(
        _normalizedMeta,
        normalized.isAcceptableOrUnknown(data['normalized']!, _normalizedMeta),
      );
    } else if (isInserting) {
      context.missing(_normalizedMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
      );
    }
    if (data.containsKey('root')) {
      context.handle(
        _rootMeta,
        root.isAcceptableOrUnknown(data['root']!, _rootMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ayahId, position},
  ];
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      arabic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arabic'],
      )!,
      normalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      ),
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      ),
      root: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root'],
      ),
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final int id;
  final int ayahId;
  final int position;
  final String arabic;
  final String normalized;
  final String? translation;
  final String? lemma;
  final String? root;
  const Word({
    required this.id,
    required this.ayahId,
    required this.position,
    required this.arabic,
    required this.normalized,
    this.translation,
    this.lemma,
    this.root,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['position'] = Variable<int>(position);
    map['arabic'] = Variable<String>(arabic);
    map['normalized'] = Variable<String>(normalized);
    if (!nullToAbsent || translation != null) {
      map['translation'] = Variable<String>(translation);
    }
    if (!nullToAbsent || lemma != null) {
      map['lemma'] = Variable<String>(lemma);
    }
    if (!nullToAbsent || root != null) {
      map['root'] = Variable<String>(root);
    }
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      position: Value(position),
      arabic: Value(arabic),
      normalized: Value(normalized),
      translation: translation == null && nullToAbsent
          ? const Value.absent()
          : Value(translation),
      lemma: lemma == null && nullToAbsent
          ? const Value.absent()
          : Value(lemma),
      root: root == null && nullToAbsent ? const Value.absent() : Value(root),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      position: serializer.fromJson<int>(json['position']),
      arabic: serializer.fromJson<String>(json['arabic']),
      normalized: serializer.fromJson<String>(json['normalized']),
      translation: serializer.fromJson<String?>(json['translation']),
      lemma: serializer.fromJson<String?>(json['lemma']),
      root: serializer.fromJson<String?>(json['root']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'position': serializer.toJson<int>(position),
      'arabic': serializer.toJson<String>(arabic),
      'normalized': serializer.toJson<String>(normalized),
      'translation': serializer.toJson<String?>(translation),
      'lemma': serializer.toJson<String?>(lemma),
      'root': serializer.toJson<String?>(root),
    };
  }

  Word copyWith({
    int? id,
    int? ayahId,
    int? position,
    String? arabic,
    String? normalized,
    Value<String?> translation = const Value.absent(),
    Value<String?> lemma = const Value.absent(),
    Value<String?> root = const Value.absent(),
  }) => Word(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    position: position ?? this.position,
    arabic: arabic ?? this.arabic,
    normalized: normalized ?? this.normalized,
    translation: translation.present ? translation.value : this.translation,
    lemma: lemma.present ? lemma.value : this.lemma,
    root: root.present ? root.value : this.root,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      position: data.position.present ? data.position.value : this.position,
      arabic: data.arabic.present ? data.arabic.value : this.arabic,
      normalized: data.normalized.present
          ? data.normalized.value
          : this.normalized,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      root: data.root.present ? data.root.value : this.root,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('position: $position, ')
          ..write('arabic: $arabic, ')
          ..write('normalized: $normalized, ')
          ..write('translation: $translation, ')
          ..write('lemma: $lemma, ')
          ..write('root: $root')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ayahId,
    position,
    arabic,
    normalized,
    translation,
    lemma,
    root,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.position == this.position &&
          other.arabic == this.arabic &&
          other.normalized == this.normalized &&
          other.translation == this.translation &&
          other.lemma == this.lemma &&
          other.root == this.root);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<int> position;
  final Value<String> arabic;
  final Value<String> normalized;
  final Value<String?> translation;
  final Value<String?> lemma;
  final Value<String?> root;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.position = const Value.absent(),
    this.arabic = const Value.absent(),
    this.normalized = const Value.absent(),
    this.translation = const Value.absent(),
    this.lemma = const Value.absent(),
    this.root = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required int position,
    required String arabic,
    required String normalized,
    this.translation = const Value.absent(),
    this.lemma = const Value.absent(),
    this.root = const Value.absent(),
  }) : ayahId = Value(ayahId),
       position = Value(position),
       arabic = Value(arabic),
       normalized = Value(normalized);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<int>? position,
    Expression<String>? arabic,
    Expression<String>? normalized,
    Expression<String>? translation,
    Expression<String>? lemma,
    Expression<String>? root,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (position != null) 'position': position,
      if (arabic != null) 'arabic': arabic,
      if (normalized != null) 'normalized': normalized,
      if (translation != null) 'translation': translation,
      if (lemma != null) 'lemma': lemma,
      if (root != null) 'root': root,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<int>? position,
    Value<String>? arabic,
    Value<String>? normalized,
    Value<String?>? translation,
    Value<String?>? lemma,
    Value<String?>? root,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      position: position ?? this.position,
      arabic: arabic ?? this.arabic,
      normalized: normalized ?? this.normalized,
      translation: translation ?? this.translation,
      lemma: lemma ?? this.lemma,
      root: root ?? this.root,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (arabic.present) {
      map['arabic'] = Variable<String>(arabic.value);
    }
    if (normalized.present) {
      map['normalized'] = Variable<String>(normalized.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (root.present) {
      map['root'] = Variable<String>(root.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('position: $position, ')
          ..write('arabic: $arabic, ')
          ..write('normalized: $normalized, ')
          ..write('translation: $translation, ')
          ..write('lemma: $lemma, ')
          ..write('root: $root')
          ..write(')'))
        .toString();
  }
}

class $WordTimingsTable extends WordTimings
    with TableInfo<$WordTimingsTable, WordTiming> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordTimingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _reciterIdMeta = const VerificationMeta(
    'reciterId',
  );
  @override
  late final GeneratedColumn<String> reciterId = GeneratedColumn<String>(
    'reciter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, wordId, reciterId, startMs, endMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_timings';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordTiming> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('reciter_id')) {
      context.handle(
        _reciterIdMeta,
        reciterId.isAcceptableOrUnknown(data['reciter_id']!, _reciterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reciterIdMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordTiming map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordTiming(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      reciterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reciter_id'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
    );
  }

  @override
  $WordTimingsTable createAlias(String alias) {
    return $WordTimingsTable(attachedDatabase, alias);
  }
}

class WordTiming extends DataClass implements Insertable<WordTiming> {
  final int id;
  final int wordId;
  final String reciterId;
  final int startMs;
  final int endMs;
  const WordTiming({
    required this.id,
    required this.wordId,
    required this.reciterId,
    required this.startMs,
    required this.endMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['reciter_id'] = Variable<String>(reciterId);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    return map;
  }

  WordTimingsCompanion toCompanion(bool nullToAbsent) {
    return WordTimingsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      reciterId: Value(reciterId),
      startMs: Value(startMs),
      endMs: Value(endMs),
    );
  }

  factory WordTiming.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordTiming(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      reciterId: serializer.fromJson<String>(json['reciterId']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'reciterId': serializer.toJson<String>(reciterId),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
    };
  }

  WordTiming copyWith({
    int? id,
    int? wordId,
    String? reciterId,
    int? startMs,
    int? endMs,
  }) => WordTiming(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    reciterId: reciterId ?? this.reciterId,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
  );
  WordTiming copyWithCompanion(WordTimingsCompanion data) {
    return WordTiming(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      reciterId: data.reciterId.present ? data.reciterId.value : this.reciterId,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordTiming(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('reciterId: $reciterId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wordId, reciterId, startMs, endMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordTiming &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.reciterId == this.reciterId &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs);
}

class WordTimingsCompanion extends UpdateCompanion<WordTiming> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<String> reciterId;
  final Value<int> startMs;
  final Value<int> endMs;
  const WordTimingsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.reciterId = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
  });
  WordTimingsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required String reciterId,
    required int startMs,
    required int endMs,
  }) : wordId = Value(wordId),
       reciterId = Value(reciterId),
       startMs = Value(startMs),
       endMs = Value(endMs);
  static Insertable<WordTiming> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<String>? reciterId,
    Expression<int>? startMs,
    Expression<int>? endMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (reciterId != null) 'reciter_id': reciterId,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
    });
  }

  WordTimingsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<String>? reciterId,
    Value<int>? startMs,
    Value<int>? endMs,
  }) {
    return WordTimingsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      reciterId: reciterId ?? this.reciterId,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (reciterId.present) {
      map['reciter_id'] = Variable<String>(reciterId.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordTimingsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('reciterId: $reciterId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }
}

class $RecitersTable extends Reciters with TableInfo<$RecitersTable, Reciter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecitersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDownloadedMeta = const VerificationMeta(
    'isDownloaded',
  );
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
    'is_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slug,
    nameAr,
    nameEn,
    style,
    isDownloaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reciters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reciter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    } else if (isInserting) {
      context.missing(_styleMeta);
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
        _isDownloadedMeta,
        isDownloaded.isAcceptableOrUnknown(
          data['is_downloaded']!,
          _isDownloadedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reciter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reciter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      isDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_downloaded'],
      )!,
    );
  }

  @override
  $RecitersTable createAlias(String alias) {
    return $RecitersTable(attachedDatabase, alias);
  }
}

class Reciter extends DataClass implements Insertable<Reciter> {
  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String style;
  final bool isDownloaded;
  const Reciter({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    required this.style,
    required this.isDownloaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slug'] = Variable<String>(slug);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    map['style'] = Variable<String>(style);
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    return map;
  }

  RecitersCompanion toCompanion(bool nullToAbsent) {
    return RecitersCompanion(
      id: Value(id),
      slug: Value(slug),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      style: Value(style),
      isDownloaded: Value(isDownloaded),
    );
  }

  factory Reciter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reciter(
      id: serializer.fromJson<String>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      style: serializer.fromJson<String>(json['style']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slug': serializer.toJson<String>(slug),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'style': serializer.toJson<String>(style),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
    };
  }

  Reciter copyWith({
    String? id,
    String? slug,
    String? nameAr,
    String? nameEn,
    String? style,
    bool? isDownloaded,
  }) => Reciter(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    style: style ?? this.style,
    isDownloaded: isDownloaded ?? this.isDownloaded,
  );
  Reciter copyWithCompanion(RecitersCompanion data) {
    return Reciter(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      style: data.style.present ? data.style.value : this.style,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reciter(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('style: $style, ')
          ..write('isDownloaded: $isDownloaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, slug, nameAr, nameEn, style, isDownloaded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reciter &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.style == this.style &&
          other.isDownloaded == this.isDownloaded);
}

class RecitersCompanion extends UpdateCompanion<Reciter> {
  final Value<String> id;
  final Value<String> slug;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<String> style;
  final Value<bool> isDownloaded;
  final Value<int> rowid;
  const RecitersCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.style = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecitersCompanion.insert({
    required String id,
    required String slug,
    required String nameAr,
    required String nameEn,
    required String style,
    this.isDownloaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slug = Value(slug),
       nameAr = Value(nameAr),
       nameEn = Value(nameEn),
       style = Value(style);
  static Insertable<Reciter> custom({
    Expression<String>? id,
    Expression<String>? slug,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? style,
    Expression<bool>? isDownloaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (style != null) 'style': style,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecitersCompanion copyWith({
    Value<String>? id,
    Value<String>? slug,
    Value<String>? nameAr,
    Value<String>? nameEn,
    Value<String>? style,
    Value<bool>? isDownloaded,
    Value<int>? rowid,
  }) {
    return RecitersCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      style: style ?? this.style,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecitersCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('style: $style, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranslatorsTable extends Translators
    with TableInfo<$TranslatorsTable, Translator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslatorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, languageCode, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translators';
  @override
  VerificationContext validateIntegrity(
    Insertable<Translator> instance, {
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
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Translator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Translator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $TranslatorsTable createAlias(String alias) {
    return $TranslatorsTable(attachedDatabase, alias);
  }
}

class Translator extends DataClass implements Insertable<Translator> {
  final int id;
  final String name;
  final String languageCode;
  final String source;
  const Translator({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['language_code'] = Variable<String>(languageCode);
    map['source'] = Variable<String>(source);
    return map;
  }

  TranslatorsCompanion toCompanion(bool nullToAbsent) {
    return TranslatorsCompanion(
      id: Value(id),
      name: Value(name),
      languageCode: Value(languageCode),
      source: Value(source),
    );
  }

  factory Translator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Translator(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'languageCode': serializer.toJson<String>(languageCode),
      'source': serializer.toJson<String>(source),
    };
  }

  Translator copyWith({
    int? id,
    String? name,
    String? languageCode,
    String? source,
  }) => Translator(
    id: id ?? this.id,
    name: name ?? this.name,
    languageCode: languageCode ?? this.languageCode,
    source: source ?? this.source,
  );
  Translator copyWithCompanion(TranslatorsCompanion data) {
    return Translator(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Translator(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('languageCode: $languageCode, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, languageCode, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Translator &&
          other.id == this.id &&
          other.name == this.name &&
          other.languageCode == this.languageCode &&
          other.source == this.source);
}

class TranslatorsCompanion extends UpdateCompanion<Translator> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> languageCode;
  final Value<String> source;
  final Value<int> rowid;
  const TranslatorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranslatorsCompanion.insert({
    required int id,
    required String name,
    required String languageCode,
    required String source,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       languageCode = Value(languageCode),
       source = Value(source);
  static Insertable<Translator> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? languageCode,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (languageCode != null) 'language_code': languageCode,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranslatorsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? languageCode,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return TranslatorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      languageCode: languageCode ?? this.languageCode,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslatorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('languageCode: $languageCode, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranslationsTable extends Translations
    with TableInfo<$TranslationsTable, Translation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayahs (id)',
    ),
  );
  static const VerificationMeta _translatorIdMeta = const VerificationMeta(
    'translatorId',
  );
  @override
  late final GeneratedColumn<int> translatorId = GeneratedColumn<int>(
    'translator_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES translators (id)',
    ),
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textValueMeta = const VerificationMeta(
    'textValue',
  );
  @override
  late final GeneratedColumn<String> textValue = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ayahId,
    translatorId,
    languageCode,
    textValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Translation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('translator_id')) {
      context.handle(
        _translatorIdMeta,
        translatorId.isAcceptableOrUnknown(
          data['translator_id']!,
          _translatorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translatorIdMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _textValueMeta,
        textValue.isAcceptableOrUnknown(data['text']!, _textValueMeta),
      );
    } else if (isInserting) {
      context.missing(_textValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ayahId, translatorId},
  ];
  @override
  Translation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Translation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      translatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}translator_id'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      textValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
    );
  }

  @override
  $TranslationsTable createAlias(String alias) {
    return $TranslationsTable(attachedDatabase, alias);
  }
}

class Translation extends DataClass implements Insertable<Translation> {
  final int id;
  final int ayahId;
  final int translatorId;
  final String languageCode;
  final String textValue;
  const Translation({
    required this.id,
    required this.ayahId,
    required this.translatorId,
    required this.languageCode,
    required this.textValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['translator_id'] = Variable<int>(translatorId);
    map['language_code'] = Variable<String>(languageCode);
    map['text'] = Variable<String>(textValue);
    return map;
  }

  TranslationsCompanion toCompanion(bool nullToAbsent) {
    return TranslationsCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      translatorId: Value(translatorId),
      languageCode: Value(languageCode),
      textValue: Value(textValue),
    );
  }

  factory Translation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Translation(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      translatorId: serializer.fromJson<int>(json['translatorId']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      textValue: serializer.fromJson<String>(json['textValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'translatorId': serializer.toJson<int>(translatorId),
      'languageCode': serializer.toJson<String>(languageCode),
      'textValue': serializer.toJson<String>(textValue),
    };
  }

  Translation copyWith({
    int? id,
    int? ayahId,
    int? translatorId,
    String? languageCode,
    String? textValue,
  }) => Translation(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    translatorId: translatorId ?? this.translatorId,
    languageCode: languageCode ?? this.languageCode,
    textValue: textValue ?? this.textValue,
  );
  Translation copyWithCompanion(TranslationsCompanion data) {
    return Translation(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      translatorId: data.translatorId.present
          ? data.translatorId.value
          : this.translatorId,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      textValue: data.textValue.present ? data.textValue.value : this.textValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Translation(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('translatorId: $translatorId, ')
          ..write('languageCode: $languageCode, ')
          ..write('textValue: $textValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ayahId, translatorId, languageCode, textValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Translation &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.translatorId == this.translatorId &&
          other.languageCode == this.languageCode &&
          other.textValue == this.textValue);
}

class TranslationsCompanion extends UpdateCompanion<Translation> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<int> translatorId;
  final Value<String> languageCode;
  final Value<String> textValue;
  const TranslationsCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.translatorId = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.textValue = const Value.absent(),
  });
  TranslationsCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required int translatorId,
    required String languageCode,
    required String textValue,
  }) : ayahId = Value(ayahId),
       translatorId = Value(translatorId),
       languageCode = Value(languageCode),
       textValue = Value(textValue);
  static Insertable<Translation> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<int>? translatorId,
    Expression<String>? languageCode,
    Expression<String>? textValue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (translatorId != null) 'translator_id': translatorId,
      if (languageCode != null) 'language_code': languageCode,
      if (textValue != null) 'text': textValue,
    });
  }

  TranslationsCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<int>? translatorId,
    Value<String>? languageCode,
    Value<String>? textValue,
  }) {
    return TranslationsCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      translatorId: translatorId ?? this.translatorId,
      languageCode: languageCode ?? this.languageCode,
      textValue: textValue ?? this.textValue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (translatorId.present) {
      map['translator_id'] = Variable<int>(translatorId.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (textValue.present) {
      map['text'] = Variable<String>(textValue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationsCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('translatorId: $translatorId, ')
          ..write('languageCode: $languageCode, ')
          ..write('textValue: $textValue')
          ..write(')'))
        .toString();
  }
}

class $TafsirSourcesTable extends TafsirSources
    with TableInfo<$TafsirSourcesTable, TafsirSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TafsirSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slug,
    nameAr,
    nameEn,
    languageCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tafsir_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<TafsirSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  TafsirSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TafsirSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
    );
  }

  @override
  $TafsirSourcesTable createAlias(String alias) {
    return $TafsirSourcesTable(attachedDatabase, alias);
  }
}

class TafsirSource extends DataClass implements Insertable<TafsirSource> {
  final int id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String languageCode;
  const TafsirSource({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    required this.languageCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['slug'] = Variable<String>(slug);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    map['language_code'] = Variable<String>(languageCode);
    return map;
  }

  TafsirSourcesCompanion toCompanion(bool nullToAbsent) {
    return TafsirSourcesCompanion(
      id: Value(id),
      slug: Value(slug),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      languageCode: Value(languageCode),
    );
  }

  factory TafsirSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TafsirSource(
      id: serializer.fromJson<int>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'slug': serializer.toJson<String>(slug),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'languageCode': serializer.toJson<String>(languageCode),
    };
  }

  TafsirSource copyWith({
    int? id,
    String? slug,
    String? nameAr,
    String? nameEn,
    String? languageCode,
  }) => TafsirSource(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    languageCode: languageCode ?? this.languageCode,
  );
  TafsirSource copyWithCompanion(TafsirSourcesCompanion data) {
    return TafsirSource(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TafsirSource(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('languageCode: $languageCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, slug, nameAr, nameEn, languageCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TafsirSource &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.languageCode == this.languageCode);
}

class TafsirSourcesCompanion extends UpdateCompanion<TafsirSource> {
  final Value<int> id;
  final Value<String> slug;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<String> languageCode;
  final Value<int> rowid;
  const TafsirSourcesCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TafsirSourcesCompanion.insert({
    required int id,
    required String slug,
    required String nameAr,
    required String nameEn,
    required String languageCode,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slug = Value(slug),
       nameAr = Value(nameAr),
       nameEn = Value(nameEn),
       languageCode = Value(languageCode);
  static Insertable<TafsirSource> custom({
    Expression<int>? id,
    Expression<String>? slug,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? languageCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (languageCode != null) 'language_code': languageCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TafsirSourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? slug,
    Value<String>? nameAr,
    Value<String>? nameEn,
    Value<String>? languageCode,
    Value<int>? rowid,
  }) {
    return TafsirSourcesCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      languageCode: languageCode ?? this.languageCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TafsirSourcesCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('languageCode: $languageCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TafsirsTable extends Tafsirs with TableInfo<$TafsirsTable, Tafsir> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TafsirsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayahs (id)',
    ),
  );
  static const VerificationMeta _tafsirSourceIdMeta = const VerificationMeta(
    'tafsirSourceId',
  );
  @override
  late final GeneratedColumn<int> tafsirSourceId = GeneratedColumn<int>(
    'tafsir_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tafsir_sources (id)',
    ),
  );
  static const VerificationMeta _textValueMeta = const VerificationMeta(
    'textValue',
  );
  @override
  late final GeneratedColumn<String> textValue = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, ayahId, tafsirSourceId, textValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tafsirs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tafsir> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('tafsir_source_id')) {
      context.handle(
        _tafsirSourceIdMeta,
        tafsirSourceId.isAcceptableOrUnknown(
          data['tafsir_source_id']!,
          _tafsirSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tafsirSourceIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _textValueMeta,
        textValue.isAcceptableOrUnknown(data['text']!, _textValueMeta),
      );
    } else if (isInserting) {
      context.missing(_textValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tafsir map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tafsir(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      tafsirSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tafsir_source_id'],
      )!,
      textValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
    );
  }

  @override
  $TafsirsTable createAlias(String alias) {
    return $TafsirsTable(attachedDatabase, alias);
  }
}

class Tafsir extends DataClass implements Insertable<Tafsir> {
  final int id;
  final int ayahId;
  final int tafsirSourceId;
  final String textValue;
  const Tafsir({
    required this.id,
    required this.ayahId,
    required this.tafsirSourceId,
    required this.textValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['tafsir_source_id'] = Variable<int>(tafsirSourceId);
    map['text'] = Variable<String>(textValue);
    return map;
  }

  TafsirsCompanion toCompanion(bool nullToAbsent) {
    return TafsirsCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      tafsirSourceId: Value(tafsirSourceId),
      textValue: Value(textValue),
    );
  }

  factory Tafsir.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tafsir(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      tafsirSourceId: serializer.fromJson<int>(json['tafsirSourceId']),
      textValue: serializer.fromJson<String>(json['textValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'tafsirSourceId': serializer.toJson<int>(tafsirSourceId),
      'textValue': serializer.toJson<String>(textValue),
    };
  }

  Tafsir copyWith({
    int? id,
    int? ayahId,
    int? tafsirSourceId,
    String? textValue,
  }) => Tafsir(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    tafsirSourceId: tafsirSourceId ?? this.tafsirSourceId,
    textValue: textValue ?? this.textValue,
  );
  Tafsir copyWithCompanion(TafsirsCompanion data) {
    return Tafsir(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      tafsirSourceId: data.tafsirSourceId.present
          ? data.tafsirSourceId.value
          : this.tafsirSourceId,
      textValue: data.textValue.present ? data.textValue.value : this.textValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tafsir(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('tafsirSourceId: $tafsirSourceId, ')
          ..write('textValue: $textValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ayahId, tafsirSourceId, textValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tafsir &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.tafsirSourceId == this.tafsirSourceId &&
          other.textValue == this.textValue);
}

class TafsirsCompanion extends UpdateCompanion<Tafsir> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<int> tafsirSourceId;
  final Value<String> textValue;
  const TafsirsCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.tafsirSourceId = const Value.absent(),
    this.textValue = const Value.absent(),
  });
  TafsirsCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required int tafsirSourceId,
    required String textValue,
  }) : ayahId = Value(ayahId),
       tafsirSourceId = Value(tafsirSourceId),
       textValue = Value(textValue);
  static Insertable<Tafsir> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<int>? tafsirSourceId,
    Expression<String>? textValue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (tafsirSourceId != null) 'tafsir_source_id': tafsirSourceId,
      if (textValue != null) 'text': textValue,
    });
  }

  TafsirsCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<int>? tafsirSourceId,
    Value<String>? textValue,
  }) {
    return TafsirsCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      tafsirSourceId: tafsirSourceId ?? this.tafsirSourceId,
      textValue: textValue ?? this.textValue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (tafsirSourceId.present) {
      map['tafsir_source_id'] = Variable<int>(tafsirSourceId.value);
    }
    if (textValue.present) {
      map['text'] = Variable<String>(textValue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TafsirsCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('tafsirSourceId: $tafsirSourceId, ')
          ..write('textValue: $textValue')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _surahIdMeta = const VerificationMeta(
    'surahId',
  );
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surahs (id)',
    ),
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayahs (id)',
    ),
  );
  static const VerificationMeta _ayahNumberMeta = const VerificationMeta(
    'ayahNumber',
  );
  @override
  late final GeneratedColumn<int> ayahNumber = GeneratedColumn<int>(
    'ayah_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surahId,
    ayahId,
    ayahNumber,
    label,
    color,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah_id')) {
      context.handle(
        _surahIdMeta,
        surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('ayah_number')) {
      context.handle(
        _ayahNumberMeta,
        ayahNumber.isAcceptableOrUnknown(data['ayah_number']!, _ayahNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahNumberMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {surahId, ayahId},
  ];
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      ayahNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_number'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;
  final int surahId;
  final int ayahId;
  final int ayahNumber;
  final String? label;
  final int? color;
  final DateTime createdAt;
  const Bookmark({
    required this.id,
    required this.surahId,
    required this.ayahId,
    required this.ayahNumber,
    this.label,
    this.color,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah_id'] = Variable<int>(surahId);
    map['ayah_id'] = Variable<int>(ayahId);
    map['ayah_number'] = Variable<int>(ayahNumber);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      surahId: Value(surahId),
      ayahId: Value(ayahId),
      ayahNumber: Value(ayahNumber),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      surahId: serializer.fromJson<int>(json['surahId']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      ayahNumber: serializer.fromJson<int>(json['ayahNumber']),
      label: serializer.fromJson<String?>(json['label']),
      color: serializer.fromJson<int?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahId': serializer.toJson<int>(surahId),
      'ayahId': serializer.toJson<int>(ayahId),
      'ayahNumber': serializer.toJson<int>(ayahNumber),
      'label': serializer.toJson<String?>(label),
      'color': serializer.toJson<int?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith({
    int? id,
    int? surahId,
    int? ayahId,
    int? ayahNumber,
    Value<String?> label = const Value.absent(),
    Value<int?> color = const Value.absent(),
    DateTime? createdAt,
  }) => Bookmark(
    id: id ?? this.id,
    surahId: surahId ?? this.surahId,
    ayahId: ayahId ?? this.ayahId,
    ayahNumber: ayahNumber ?? this.ayahNumber,
    label: label.present ? label.value : this.label,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      ayahNumber: data.ayahNumber.present
          ? data.ayahNumber.value
          : this.ayahNumber,
      label: data.label.present ? data.label.value : this.label,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('ayahId: $ayahId, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('label: $label, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, surahId, ayahId, ayahNumber, label, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.surahId == this.surahId &&
          other.ayahId == this.ayahId &&
          other.ayahNumber == this.ayahNumber &&
          other.label == this.label &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<int> surahId;
  final Value<int> ayahId;
  final Value<int> ayahNumber;
  final Value<String?> label;
  final Value<int?> color;
  final Value<DateTime> createdAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.surahId = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.ayahNumber = const Value.absent(),
    this.label = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int surahId,
    required int ayahId,
    required int ayahNumber,
    this.label = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : surahId = Value(surahId),
       ayahId = Value(ayahId),
       ayahNumber = Value(ayahNumber);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<int>? surahId,
    Expression<int>? ayahId,
    Expression<int>? ayahNumber,
    Expression<String>? label,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surahId != null) 'surah_id': surahId,
      if (ayahId != null) 'ayah_id': ayahId,
      if (ayahNumber != null) 'ayah_number': ayahNumber,
      if (label != null) 'label': label,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<int>? surahId,
    Value<int>? ayahId,
    Value<int>? ayahNumber,
    Value<String?>? label,
    Value<int?>? color,
    Value<DateTime>? createdAt,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      ayahId: ayahId ?? this.ayahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      label: label ?? this.label,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (ayahNumber.present) {
      map['ayah_number'] = Variable<int>(ayahNumber.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('ayahId: $ayahId, ')
          ..write('ayahNumber: $ayahNumber, ')
          ..write('label: $label, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayahs (id)',
    ),
  );
  static const VerificationMeta _textValueMeta = const VerificationMeta(
    'textValue',
  );
  @override
  late final GeneratedColumn<String> textValue = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ayahId,
    textValue,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _textValueMeta,
        textValue.isAcceptableOrUnknown(data['text']!, _textValueMeta),
      );
    } else if (isInserting) {
      context.missing(_textValueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      textValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final int ayahId;
  final String textValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Note({
    required this.id,
    required this.ayahId,
    required this.textValue,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['text'] = Variable<String>(textValue);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      textValue: Value(textValue),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      textValue: serializer.fromJson<String>(json['textValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'textValue': serializer.toJson<String>(textValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Note copyWith({
    int? id,
    int? ayahId,
    String? textValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Note(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    textValue: textValue ?? this.textValue,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      textValue: data.textValue.present ? data.textValue.value : this.textValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('textValue: $textValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ayahId, textValue, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.textValue == this.textValue &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<String> textValue;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.textValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required String textValue,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : ayahId = Value(ayahId),
       textValue = Value(textValue);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<String>? textValue,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (textValue != null) 'text': textValue,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<String>? textValue,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      textValue: textValue ?? this.textValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (textValue.present) {
      map['text'] = Variable<String>(textValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('textValue: $textValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LastPositionTable extends LastPosition
    with TableInfo<$LastPositionTable, LastPositionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LastPositionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _surahIdMeta = const VerificationMeta(
    'surahId',
  );
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, surahId, ayahId, page, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'last_position';
  @override
  VerificationContext validateIntegrity(
    Insertable<LastPositionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah_id')) {
      context.handle(
        _surahIdMeta,
        surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('ayah_id')) {
      context.handle(
        _ayahIdMeta,
        ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LastPositionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LastPositionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LastPositionTable createAlias(String alias) {
    return $LastPositionTable(attachedDatabase, alias);
  }
}

class LastPositionData extends DataClass
    implements Insertable<LastPositionData> {
  final int id;
  final int surahId;
  final int ayahId;
  final int? page;
  final DateTime updatedAt;
  const LastPositionData({
    required this.id,
    required this.surahId,
    required this.ayahId,
    this.page,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah_id'] = Variable<int>(surahId);
    map['ayah_id'] = Variable<int>(ayahId);
    if (!nullToAbsent || page != null) {
      map['page'] = Variable<int>(page);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LastPositionCompanion toCompanion(bool nullToAbsent) {
    return LastPositionCompanion(
      id: Value(id),
      surahId: Value(surahId),
      ayahId: Value(ayahId),
      page: page == null && nullToAbsent ? const Value.absent() : Value(page),
      updatedAt: Value(updatedAt),
    );
  }

  factory LastPositionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LastPositionData(
      id: serializer.fromJson<int>(json['id']),
      surahId: serializer.fromJson<int>(json['surahId']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      page: serializer.fromJson<int?>(json['page']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahId': serializer.toJson<int>(surahId),
      'ayahId': serializer.toJson<int>(ayahId),
      'page': serializer.toJson<int?>(page),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LastPositionData copyWith({
    int? id,
    int? surahId,
    int? ayahId,
    Value<int?> page = const Value.absent(),
    DateTime? updatedAt,
  }) => LastPositionData(
    id: id ?? this.id,
    surahId: surahId ?? this.surahId,
    ayahId: ayahId ?? this.ayahId,
    page: page.present ? page.value : this.page,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LastPositionData copyWithCompanion(LastPositionCompanion data) {
    return LastPositionData(
      id: data.id.present ? data.id.value : this.id,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      page: data.page.present ? data.page.value : this.page,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LastPositionData(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('ayahId: $ayahId, ')
          ..write('page: $page, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surahId, ayahId, page, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LastPositionData &&
          other.id == this.id &&
          other.surahId == this.surahId &&
          other.ayahId == this.ayahId &&
          other.page == this.page &&
          other.updatedAt == this.updatedAt);
}

class LastPositionCompanion extends UpdateCompanion<LastPositionData> {
  final Value<int> id;
  final Value<int> surahId;
  final Value<int> ayahId;
  final Value<int?> page;
  final Value<DateTime> updatedAt;
  const LastPositionCompanion({
    this.id = const Value.absent(),
    this.surahId = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.page = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LastPositionCompanion.insert({
    this.id = const Value.absent(),
    required int surahId,
    required int ayahId,
    this.page = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : surahId = Value(surahId),
       ayahId = Value(ayahId);
  static Insertable<LastPositionData> custom({
    Expression<int>? id,
    Expression<int>? surahId,
    Expression<int>? ayahId,
    Expression<int>? page,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surahId != null) 'surah_id': surahId,
      if (ayahId != null) 'ayah_id': ayahId,
      if (page != null) 'page': page,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LastPositionCompanion copyWith({
    Value<int>? id,
    Value<int>? surahId,
    Value<int>? ayahId,
    Value<int?>? page,
    Value<DateTime>? updatedAt,
  }) {
    return LastPositionCompanion(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      ayahId: ayahId ?? this.ayahId,
      page: page ?? this.page,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LastPositionCompanion(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('ayahId: $ayahId, ')
          ..write('page: $page, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingHistoryTable extends ReadingHistory
    with TableInfo<$ReadingHistoryTable, ReadingHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surahIdMeta = const VerificationMeta(
    'surahId',
  );
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ayahsReadMeta = const VerificationMeta(
    'ayahsRead',
  );
  @override
  late final GeneratedColumn<int> ayahsRead = GeneratedColumn<int>(
    'ayahs_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, surahId, ayahsRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('surah_id')) {
      context.handle(
        _surahIdMeta,
        surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('ayahs_read')) {
      context.handle(
        _ayahsReadMeta,
        ayahsRead.isAcceptableOrUnknown(data['ayahs_read']!, _ayahsReadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {date, surahId},
  ];
  @override
  ReadingHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      ayahsRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayahs_read'],
      )!,
    );
  }

  @override
  $ReadingHistoryTable createAlias(String alias) {
    return $ReadingHistoryTable(attachedDatabase, alias);
  }
}

class ReadingHistoryData extends DataClass
    implements Insertable<ReadingHistoryData> {
  final int id;
  final String date;
  final int surahId;
  final int ayahsRead;
  const ReadingHistoryData({
    required this.id,
    required this.date,
    required this.surahId,
    required this.ayahsRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['surah_id'] = Variable<int>(surahId);
    map['ayahs_read'] = Variable<int>(ayahsRead);
    return map;
  }

  ReadingHistoryCompanion toCompanion(bool nullToAbsent) {
    return ReadingHistoryCompanion(
      id: Value(id),
      date: Value(date),
      surahId: Value(surahId),
      ayahsRead: Value(ayahsRead),
    );
  }

  factory ReadingHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingHistoryData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      surahId: serializer.fromJson<int>(json['surahId']),
      ayahsRead: serializer.fromJson<int>(json['ayahsRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'surahId': serializer.toJson<int>(surahId),
      'ayahsRead': serializer.toJson<int>(ayahsRead),
    };
  }

  ReadingHistoryData copyWith({
    int? id,
    String? date,
    int? surahId,
    int? ayahsRead,
  }) => ReadingHistoryData(
    id: id ?? this.id,
    date: date ?? this.date,
    surahId: surahId ?? this.surahId,
    ayahsRead: ayahsRead ?? this.ayahsRead,
  );
  ReadingHistoryData copyWithCompanion(ReadingHistoryCompanion data) {
    return ReadingHistoryData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      ayahsRead: data.ayahsRead.present ? data.ayahsRead.value : this.ayahsRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingHistoryData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('surahId: $surahId, ')
          ..write('ayahsRead: $ayahsRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, surahId, ayahsRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingHistoryData &&
          other.id == this.id &&
          other.date == this.date &&
          other.surahId == this.surahId &&
          other.ayahsRead == this.ayahsRead);
}

class ReadingHistoryCompanion extends UpdateCompanion<ReadingHistoryData> {
  final Value<int> id;
  final Value<String> date;
  final Value<int> surahId;
  final Value<int> ayahsRead;
  const ReadingHistoryCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.surahId = const Value.absent(),
    this.ayahsRead = const Value.absent(),
  });
  ReadingHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required int surahId,
    this.ayahsRead = const Value.absent(),
  }) : date = Value(date),
       surahId = Value(surahId);
  static Insertable<ReadingHistoryData> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<int>? surahId,
    Expression<int>? ayahsRead,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (surahId != null) 'surah_id': surahId,
      if (ayahsRead != null) 'ayahs_read': ayahsRead,
    });
  }

  ReadingHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<int>? surahId,
    Value<int>? ayahsRead,
  }) {
    return ReadingHistoryCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      surahId: surahId ?? this.surahId,
      ayahsRead: ayahsRead ?? this.ayahsRead,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (ayahsRead.present) {
      map['ayahs_read'] = Variable<int>(ayahsRead.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingHistoryCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('surahId: $surahId, ')
          ..write('ayahsRead: $ayahsRead')
          ..write(')'))
        .toString();
  }
}

class $LearningWordsTable extends LearningWords
    with TableInfo<$LearningWordsTable, LearningWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewAtMeta = const VerificationMeta(
    'lastReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewAt = GeneratedColumn<DateTime>(
    'last_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    status,
    easeFactor,
    intervalDays,
    repetitions,
    nextReviewAt,
    lastReviewAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextReviewAtMeta);
    }
    if (data.containsKey('last_review_at')) {
      context.handle(
        _lastReviewAtMeta,
        lastReviewAt.isAcceptableOrUnknown(
          data['last_review_at']!,
          _lastReviewAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      )!,
      lastReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review_at'],
      ),
    );
  }

  @override
  $LearningWordsTable createAlias(String alias) {
    return $LearningWordsTable(attachedDatabase, alias);
  }
}

class LearningWord extends DataClass implements Insertable<LearningWord> {
  final int id;
  final int wordId;
  final String status;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;
  final DateTime? lastReviewAt;
  const LearningWord({
    required this.id,
    required this.wordId,
    required this.status,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReviewAt,
    this.lastReviewAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['status'] = Variable<String>(status);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    if (!nullToAbsent || lastReviewAt != null) {
      map['last_review_at'] = Variable<DateTime>(lastReviewAt);
    }
    return map;
  }

  LearningWordsCompanion toCompanion(bool nullToAbsent) {
    return LearningWordsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      status: Value(status),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      nextReviewAt: Value(nextReviewAt),
      lastReviewAt: lastReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewAt),
    );
  }

  factory LearningWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningWord(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      status: serializer.fromJson<String>(json['status']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      nextReviewAt: serializer.fromJson<DateTime>(json['nextReviewAt']),
      lastReviewAt: serializer.fromJson<DateTime?>(json['lastReviewAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'status': serializer.toJson<String>(status),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'nextReviewAt': serializer.toJson<DateTime>(nextReviewAt),
      'lastReviewAt': serializer.toJson<DateTime?>(lastReviewAt),
    };
  }

  LearningWord copyWith({
    int? id,
    int? wordId,
    String? status,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewAt,
    Value<DateTime?> lastReviewAt = const Value.absent(),
  }) => LearningWord(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    status: status ?? this.status,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    lastReviewAt: lastReviewAt.present ? lastReviewAt.value : this.lastReviewAt,
  );
  LearningWord copyWithCompanion(LearningWordsCompanion data) {
    return LearningWord(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      status: data.status.present ? data.status.value : this.status,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      lastReviewAt: data.lastReviewAt.present
          ? data.lastReviewAt.value
          : this.lastReviewAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningWord(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('status: $status, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastReviewAt: $lastReviewAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wordId,
    status,
    easeFactor,
    intervalDays,
    repetitions,
    nextReviewAt,
    lastReviewAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningWord &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.status == this.status &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.nextReviewAt == this.nextReviewAt &&
          other.lastReviewAt == this.lastReviewAt);
}

class LearningWordsCompanion extends UpdateCompanion<LearningWord> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<String> status;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<DateTime> nextReviewAt;
  final Value<DateTime?> lastReviewAt;
  const LearningWordsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.status = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
  });
  LearningWordsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required String status,
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    required DateTime nextReviewAt,
    this.lastReviewAt = const Value.absent(),
  }) : wordId = Value(wordId),
       status = Value(status),
       nextReviewAt = Value(nextReviewAt);
  static Insertable<LearningWord> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<String>? status,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<DateTime>? nextReviewAt,
    Expression<DateTime>? lastReviewAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (status != null) 'status': status,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (lastReviewAt != null) 'last_review_at': lastReviewAt,
    });
  }

  LearningWordsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<String>? status,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<DateTime>? nextReviewAt,
    Value<DateTime?>? lastReviewAt,
  }) {
    return LearningWordsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      status: status ?? this.status,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (lastReviewAt.present) {
      map['last_review_at'] = Variable<DateTime>(lastReviewAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningWordsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('status: $status, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastReviewAt: $lastReviewAt')
          ..write(')'))
        .toString();
  }
}

class $AudioCacheMetadataTable extends AudioCacheMetadata
    with TableInfo<$AudioCacheMetadataTable, AudioCacheMetadatum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioCacheMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reciterIdMeta = const VerificationMeta(
    'reciterId',
  );
  @override
  late final GeneratedColumn<String> reciterId = GeneratedColumn<String>(
    'reciter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surahIdMeta = const VerificationMeta(
    'surahId',
  );
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reciterId,
    surahId,
    filePath,
    fileSizeBytes,
    downloadedAt,
    lastPlayedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_cache_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioCacheMetadatum> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reciter_id')) {
      context.handle(
        _reciterIdMeta,
        reciterId.isAcceptableOrUnknown(data['reciter_id']!, _reciterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reciterIdMeta);
    }
    if (data.containsKey('surah_id')) {
      context.handle(
        _surahIdMeta,
        surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {reciterId, surahId},
  ];
  @override
  AudioCacheMetadatum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioCacheMetadatum(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reciterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reciter_id'],
      )!,
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
    );
  }

  @override
  $AudioCacheMetadataTable createAlias(String alias) {
    return $AudioCacheMetadataTable(attachedDatabase, alias);
  }
}

class AudioCacheMetadatum extends DataClass
    implements Insertable<AudioCacheMetadatum> {
  final int id;
  final String reciterId;
  final int surahId;
  final String filePath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final DateTime? lastPlayedAt;
  const AudioCacheMetadatum({
    required this.id,
    required this.reciterId,
    required this.surahId,
    required this.filePath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    this.lastPlayedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reciter_id'] = Variable<String>(reciterId);
    map['surah_id'] = Variable<int>(surahId);
    map['file_path'] = Variable<String>(filePath);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    return map;
  }

  AudioCacheMetadataCompanion toCompanion(bool nullToAbsent) {
    return AudioCacheMetadataCompanion(
      id: Value(id),
      reciterId: Value(reciterId),
      surahId: Value(surahId),
      filePath: Value(filePath),
      fileSizeBytes: Value(fileSizeBytes),
      downloadedAt: Value(downloadedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory AudioCacheMetadatum.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioCacheMetadatum(
      id: serializer.fromJson<int>(json['id']),
      reciterId: serializer.fromJson<String>(json['reciterId']),
      surahId: serializer.fromJson<int>(json['surahId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reciterId': serializer.toJson<String>(reciterId),
      'surahId': serializer.toJson<int>(surahId),
      'filePath': serializer.toJson<String>(filePath),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
    };
  }

  AudioCacheMetadatum copyWith({
    int? id,
    String? reciterId,
    int? surahId,
    String? filePath,
    int? fileSizeBytes,
    DateTime? downloadedAt,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
  }) => AudioCacheMetadatum(
    id: id ?? this.id,
    reciterId: reciterId ?? this.reciterId,
    surahId: surahId ?? this.surahId,
    filePath: filePath ?? this.filePath,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
  );
  AudioCacheMetadatum copyWithCompanion(AudioCacheMetadataCompanion data) {
    return AudioCacheMetadatum(
      id: data.id.present ? data.id.value : this.id,
      reciterId: data.reciterId.present ? data.reciterId.value : this.reciterId,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheMetadatum(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('surahId: $surahId, ')
          ..write('filePath: $filePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reciterId,
    surahId,
    filePath,
    fileSizeBytes,
    downloadedAt,
    lastPlayedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioCacheMetadatum &&
          other.id == this.id &&
          other.reciterId == this.reciterId &&
          other.surahId == this.surahId &&
          other.filePath == this.filePath &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.downloadedAt == this.downloadedAt &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class AudioCacheMetadataCompanion extends UpdateCompanion<AudioCacheMetadatum> {
  final Value<int> id;
  final Value<String> reciterId;
  final Value<int> surahId;
  final Value<String> filePath;
  final Value<int> fileSizeBytes;
  final Value<DateTime> downloadedAt;
  final Value<DateTime?> lastPlayedAt;
  const AudioCacheMetadataCompanion({
    this.id = const Value.absent(),
    this.reciterId = const Value.absent(),
    this.surahId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  });
  AudioCacheMetadataCompanion.insert({
    this.id = const Value.absent(),
    required String reciterId,
    required int surahId,
    required String filePath,
    required int fileSizeBytes,
    this.downloadedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  }) : reciterId = Value(reciterId),
       surahId = Value(surahId),
       filePath = Value(filePath),
       fileSizeBytes = Value(fileSizeBytes);
  static Insertable<AudioCacheMetadatum> custom({
    Expression<int>? id,
    Expression<String>? reciterId,
    Expression<int>? surahId,
    Expression<String>? filePath,
    Expression<int>? fileSizeBytes,
    Expression<DateTime>? downloadedAt,
    Expression<DateTime>? lastPlayedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reciterId != null) 'reciter_id': reciterId,
      if (surahId != null) 'surah_id': surahId,
      if (filePath != null) 'file_path': filePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
    });
  }

  AudioCacheMetadataCompanion copyWith({
    Value<int>? id,
    Value<String>? reciterId,
    Value<int>? surahId,
    Value<String>? filePath,
    Value<int>? fileSizeBytes,
    Value<DateTime>? downloadedAt,
    Value<DateTime?>? lastPlayedAt,
  }) {
    return AudioCacheMetadataCompanion(
      id: id ?? this.id,
      reciterId: reciterId ?? this.reciterId,
      surahId: surahId ?? this.surahId,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reciterId.present) {
      map['reciter_id'] = Variable<String>(reciterId.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheMetadataCompanion(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('surahId: $surahId, ')
          ..write('filePath: $filePath, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String value;
  const SettingsEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsEntry copyWith({String? key, String? value}) =>
      SettingsEntry(key: key ?? this.key, value: value ?? this.value);
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SurahsTable surahs = $SurahsTable(this);
  late final $AyahsTable ayahs = $AyahsTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $WordTimingsTable wordTimings = $WordTimingsTable(this);
  late final $RecitersTable reciters = $RecitersTable(this);
  late final $TranslatorsTable translators = $TranslatorsTable(this);
  late final $TranslationsTable translations = $TranslationsTable(this);
  late final $TafsirSourcesTable tafsirSources = $TafsirSourcesTable(this);
  late final $TafsirsTable tafsirs = $TafsirsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $LastPositionTable lastPosition = $LastPositionTable(this);
  late final $ReadingHistoryTable readingHistory = $ReadingHistoryTable(this);
  late final $LearningWordsTable learningWords = $LearningWordsTable(this);
  late final $AudioCacheMetadataTable audioCacheMetadata =
      $AudioCacheMetadataTable(this);
  late final $SettingsEntriesTable settingsEntries = $SettingsEntriesTable(
    this,
  );
  late final SurahDao surahDao = SurahDao(this as AppDatabase);
  late final AyahDao ayahDao = AyahDao(this as AppDatabase);
  late final BookmarkDao bookmarkDao = BookmarkDao(this as AppDatabase);
  late final TranslationDao translationDao = TranslationDao(
    this as AppDatabase,
  );
  late final PositionDao positionDao = PositionDao(this as AppDatabase);
  late final ReciterDao reciterDao = ReciterDao(this as AppDatabase);
  late final AudioCacheDao audioCacheDao = AudioCacheDao(this as AppDatabase);
  late final WordsDao wordsDao = WordsDao(this as AppDatabase);
  late final WordTimingsDao wordTimingsDao = WordTimingsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    surahs,
    ayahs,
    words,
    wordTimings,
    reciters,
    translators,
    translations,
    tafsirSources,
    tafsirs,
    bookmarks,
    notes,
    lastPosition,
    readingHistory,
    learningWords,
    audioCacheMetadata,
    settingsEntries,
  ];
}

typedef $$SurahsTableCreateCompanionBuilder =
    SurahsCompanion Function({
      Value<int> id,
      required String nameAr,
      required String nameEn,
      required String nameTransliteration,
      required String revelationType,
      required int ayahCount,
      required int orderInMushaf,
    });
typedef $$SurahsTableUpdateCompanionBuilder =
    SurahsCompanion Function({
      Value<int> id,
      Value<String> nameAr,
      Value<String> nameEn,
      Value<String> nameTransliteration,
      Value<String> revelationType,
      Value<int> ayahCount,
      Value<int> orderInMushaf,
    });

final class $$SurahsTableReferences
    extends BaseReferences<_$AppDatabase, $SurahsTable, Surah> {
  $$SurahsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AyahsTable, List<Ayah>> _ayahsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ayahs,
    aliasName: $_aliasNameGenerator(db.surahs.id, db.ayahs.surahId),
  );

  $$AyahsTableProcessedTableManager get ayahsRefs {
    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.surahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ayahsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: $_aliasNameGenerator(db.surahs.id, db.bookmarks.surahId),
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.surahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SurahsTableFilterComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameTransliteration => $composableBuilder(
    column: $table.nameTransliteration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revelationType => $composableBuilder(
    column: $table.revelationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderInMushaf => $composableBuilder(
    column: $table.orderInMushaf,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ayahsRefs(
    Expression<bool> Function($$AyahsTableFilterComposer f) f,
  ) {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.surahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.surahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SurahsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameTransliteration => $composableBuilder(
    column: $table.nameTransliteration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revelationType => $composableBuilder(
    column: $table.revelationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahCount => $composableBuilder(
    column: $table.ayahCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderInMushaf => $composableBuilder(
    column: $table.orderInMushaf,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameTransliteration => $composableBuilder(
    column: $table.nameTransliteration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get revelationType => $composableBuilder(
    column: $table.revelationType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<int> get orderInMushaf => $composableBuilder(
    column: $table.orderInMushaf,
    builder: (column) => column,
  );

  Expression<T> ayahsRefs<T extends Object>(
    Expression<T> Function($$AyahsTableAnnotationComposer a) f,
  ) {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.surahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.surahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SurahsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurahsTable,
          Surah,
          $$SurahsTableFilterComposer,
          $$SurahsTableOrderingComposer,
          $$SurahsTableAnnotationComposer,
          $$SurahsTableCreateCompanionBuilder,
          $$SurahsTableUpdateCompanionBuilder,
          (Surah, $$SurahsTableReferences),
          Surah,
          PrefetchHooks Function({bool ayahsRefs, bool bookmarksRefs})
        > {
  $$SurahsTableTableManager(_$AppDatabase db, $SurahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameTransliteration = const Value.absent(),
                Value<String> revelationType = const Value.absent(),
                Value<int> ayahCount = const Value.absent(),
                Value<int> orderInMushaf = const Value.absent(),
              }) => SurahsCompanion(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                nameTransliteration: nameTransliteration,
                revelationType: revelationType,
                ayahCount: ayahCount,
                orderInMushaf: orderInMushaf,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nameAr,
                required String nameEn,
                required String nameTransliteration,
                required String revelationType,
                required int ayahCount,
                required int orderInMushaf,
              }) => SurahsCompanion.insert(
                id: id,
                nameAr: nameAr,
                nameEn: nameEn,
                nameTransliteration: nameTransliteration,
                revelationType: revelationType,
                ayahCount: ayahCount,
                orderInMushaf: orderInMushaf,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SurahsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({ayahsRefs = false, bookmarksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ayahsRefs) db.ayahs,
                if (bookmarksRefs) db.bookmarks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ayahsRefs)
                    await $_getPrefetchedData<Surah, $SurahsTable, Ayah>(
                      currentTable: table,
                      referencedTable: $$SurahsTableReferences._ayahsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$SurahsTableReferences(db, table, p0).ayahsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.surahId == item.id),
                      typedResults: items,
                    ),
                  if (bookmarksRefs)
                    await $_getPrefetchedData<Surah, $SurahsTable, Bookmark>(
                      currentTable: table,
                      referencedTable: $$SurahsTableReferences
                          ._bookmarksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SurahsTableReferences(db, table, p0).bookmarksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.surahId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SurahsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurahsTable,
      Surah,
      $$SurahsTableFilterComposer,
      $$SurahsTableOrderingComposer,
      $$SurahsTableAnnotationComposer,
      $$SurahsTableCreateCompanionBuilder,
      $$SurahsTableUpdateCompanionBuilder,
      (Surah, $$SurahsTableReferences),
      Surah,
      PrefetchHooks Function({bool ayahsRefs, bool bookmarksRefs})
    >;
typedef $$AyahsTableCreateCompanionBuilder =
    AyahsCompanion Function({
      Value<int> id,
      required int surahId,
      required int ayahNumber,
      Value<int?> page,
      Value<int?> juz,
      Value<int?> hizb,
      required String textUthmani,
      required String textNormalized,
    });
typedef $$AyahsTableUpdateCompanionBuilder =
    AyahsCompanion Function({
      Value<int> id,
      Value<int> surahId,
      Value<int> ayahNumber,
      Value<int?> page,
      Value<int?> juz,
      Value<int?> hizb,
      Value<String> textUthmani,
      Value<String> textNormalized,
    });

final class $$AyahsTableReferences
    extends BaseReferences<_$AppDatabase, $AyahsTable, Ayah> {
  $$AyahsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SurahsTable _surahIdTable(_$AppDatabase db) => db.surahs.createAlias(
    $_aliasNameGenerator(db.ayahs.surahId, db.surahs.id),
  );

  $$SurahsTableProcessedTableManager get surahId {
    final $_column = $_itemColumn<int>('surah_id')!;

    final manager = $$SurahsTableTableManager(
      $_db,
      $_db.surahs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WordsTable, List<Word>> _wordsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.words,
    aliasName: $_aliasNameGenerator(db.ayahs.id, db.words.ayahId),
  );

  $$WordsTableProcessedTableManager get wordsRefs {
    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.ayahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TranslationsTable, List<Translation>>
  _translationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.translations,
    aliasName: $_aliasNameGenerator(db.ayahs.id, db.translations.ayahId),
  );

  $$TranslationsTableProcessedTableManager get translationsRefs {
    final manager = $$TranslationsTableTableManager(
      $_db,
      $_db.translations,
    ).filter((f) => f.ayahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_translationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TafsirsTable, List<Tafsir>> _tafsirsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tafsirs,
    aliasName: $_aliasNameGenerator(db.ayahs.id, db.tafsirs.ayahId),
  );

  $$TafsirsTableProcessedTableManager get tafsirsRefs {
    final manager = $$TafsirsTableTableManager(
      $_db,
      $_db.tafsirs,
    ).filter((f) => f.ayahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tafsirsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: $_aliasNameGenerator(db.ayahs.id, db.bookmarks.ayahId),
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.ayahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotesTable, List<Note>> _notesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.notes,
    aliasName: $_aliasNameGenerator(db.ayahs.id, db.notes.ayahId),
  );

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.ayahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AyahsTableFilterComposer extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get juz => $composableBuilder(
    column: $table.juz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hizb => $composableBuilder(
    column: $table.hizb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textNormalized => $composableBuilder(
    column: $table.textNormalized,
    builder: (column) => ColumnFilters(column),
  );

  $$SurahsTableFilterComposer get surahId {
    final $$SurahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahId,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableFilterComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> wordsRefs(
    Expression<bool> Function($$WordsTableFilterComposer f) f,
  ) {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> translationsRefs(
    Expression<bool> Function($$TranslationsTableFilterComposer f) f,
  ) {
    final $$TranslationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableFilterComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tafsirsRefs(
    Expression<bool> Function($$TafsirsTableFilterComposer f) f,
  ) {
    final $$TafsirsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tafsirs,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TafsirsTableFilterComposer(
            $db: $db,
            $table: $db.tafsirs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notesRefs(
    Expression<bool> Function($$NotesTableFilterComposer f) f,
  ) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AyahsTableOrderingComposer
    extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get juz => $composableBuilder(
    column: $table.juz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hizb => $composableBuilder(
    column: $table.hizb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textNormalized => $composableBuilder(
    column: $table.textNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  $$SurahsTableOrderingComposer get surahId {
    final $$SurahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahId,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableOrderingComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AyahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get juz =>
      $composableBuilder(column: $table.juz, builder: (column) => column);

  GeneratedColumn<int> get hizb =>
      $composableBuilder(column: $table.hizb, builder: (column) => column);

  GeneratedColumn<String> get textUthmani => $composableBuilder(
    column: $table.textUthmani,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textNormalized => $composableBuilder(
    column: $table.textNormalized,
    builder: (column) => column,
  );

  $$SurahsTableAnnotationComposer get surahId {
    final $$SurahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahId,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableAnnotationComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> wordsRefs<T extends Object>(
    Expression<T> Function($$WordsTableAnnotationComposer a) f,
  ) {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> translationsRefs<T extends Object>(
    Expression<T> Function($$TranslationsTableAnnotationComposer a) f,
  ) {
    final $$TranslationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableAnnotationComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tafsirsRefs<T extends Object>(
    Expression<T> Function($$TafsirsTableAnnotationComposer a) f,
  ) {
    final $$TafsirsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tafsirs,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TafsirsTableAnnotationComposer(
            $db: $db,
            $table: $db.tafsirs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notesRefs<T extends Object>(
    Expression<T> Function($$NotesTableAnnotationComposer a) f,
  ) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.ayahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AyahsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AyahsTable,
          Ayah,
          $$AyahsTableFilterComposer,
          $$AyahsTableOrderingComposer,
          $$AyahsTableAnnotationComposer,
          $$AyahsTableCreateCompanionBuilder,
          $$AyahsTableUpdateCompanionBuilder,
          (Ayah, $$AyahsTableReferences),
          Ayah,
          PrefetchHooks Function({
            bool surahId,
            bool wordsRefs,
            bool translationsRefs,
            bool tafsirsRefs,
            bool bookmarksRefs,
            bool notesRefs,
          })
        > {
  $$AyahsTableTableManager(_$AppDatabase db, $AyahsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surahId = const Value.absent(),
                Value<int> ayahNumber = const Value.absent(),
                Value<int?> page = const Value.absent(),
                Value<int?> juz = const Value.absent(),
                Value<int?> hizb = const Value.absent(),
                Value<String> textUthmani = const Value.absent(),
                Value<String> textNormalized = const Value.absent(),
              }) => AyahsCompanion(
                id: id,
                surahId: surahId,
                ayahNumber: ayahNumber,
                page: page,
                juz: juz,
                hizb: hizb,
                textUthmani: textUthmani,
                textNormalized: textNormalized,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surahId,
                required int ayahNumber,
                Value<int?> page = const Value.absent(),
                Value<int?> juz = const Value.absent(),
                Value<int?> hizb = const Value.absent(),
                required String textUthmani,
                required String textNormalized,
              }) => AyahsCompanion.insert(
                id: id,
                surahId: surahId,
                ayahNumber: ayahNumber,
                page: page,
                juz: juz,
                hizb: hizb,
                textUthmani: textUthmani,
                textNormalized: textNormalized,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AyahsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                surahId = false,
                wordsRefs = false,
                translationsRefs = false,
                tafsirsRefs = false,
                bookmarksRefs = false,
                notesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wordsRefs) db.words,
                    if (translationsRefs) db.translations,
                    if (tafsirsRefs) db.tafsirs,
                    if (bookmarksRefs) db.bookmarks,
                    if (notesRefs) db.notes,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (surahId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.surahId,
                                    referencedTable: $$AyahsTableReferences
                                        ._surahIdTable(db),
                                    referencedColumn: $$AyahsTableReferences
                                        ._surahIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wordsRefs)
                        await $_getPrefetchedData<Ayah, $AyahsTable, Word>(
                          currentTable: table,
                          referencedTable: $$AyahsTableReferences
                              ._wordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AyahsTableReferences(db, table, p0).wordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ayahId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (translationsRefs)
                        await $_getPrefetchedData<
                          Ayah,
                          $AyahsTable,
                          Translation
                        >(
                          currentTable: table,
                          referencedTable: $$AyahsTableReferences
                              ._translationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AyahsTableReferences(
                                db,
                                table,
                                p0,
                              ).translationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ayahId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tafsirsRefs)
                        await $_getPrefetchedData<Ayah, $AyahsTable, Tafsir>(
                          currentTable: table,
                          referencedTable: $$AyahsTableReferences
                              ._tafsirsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AyahsTableReferences(db, table, p0).tafsirsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ayahId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<Ayah, $AyahsTable, Bookmark>(
                          currentTable: table,
                          referencedTable: $$AyahsTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AyahsTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ayahId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notesRefs)
                        await $_getPrefetchedData<Ayah, $AyahsTable, Note>(
                          currentTable: table,
                          referencedTable: $$AyahsTableReferences
                              ._notesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AyahsTableReferences(db, table, p0).notesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ayahId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AyahsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AyahsTable,
      Ayah,
      $$AyahsTableFilterComposer,
      $$AyahsTableOrderingComposer,
      $$AyahsTableAnnotationComposer,
      $$AyahsTableCreateCompanionBuilder,
      $$AyahsTableUpdateCompanionBuilder,
      (Ayah, $$AyahsTableReferences),
      Ayah,
      PrefetchHooks Function({
        bool surahId,
        bool wordsRefs,
        bool translationsRefs,
        bool tafsirsRefs,
        bool bookmarksRefs,
        bool notesRefs,
      })
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      required int ayahId,
      required int position,
      required String arabic,
      required String normalized,
      Value<String?> translation,
      Value<String?> lemma,
      Value<String?> root,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      Value<int> ayahId,
      Value<int> position,
      Value<String> arabic,
      Value<String> normalized,
      Value<String?> translation,
      Value<String?> lemma,
      Value<String?> root,
    });

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AyahsTable _ayahIdTable(_$AppDatabase db) =>
      db.ayahs.createAlias($_aliasNameGenerator(db.words.ayahId, db.ayahs.id));

  $$AyahsTableProcessedTableManager get ayahId {
    final $_column = $_itemColumn<int>('ayah_id')!;

    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ayahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WordTimingsTable, List<WordTiming>>
  _wordTimingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordTimings,
    aliasName: $_aliasNameGenerator(db.words.id, db.wordTimings.wordId),
  );

  $$WordTimingsTableProcessedTableManager get wordTimingsRefs {
    final manager = $$WordTimingsTableTableManager(
      $_db,
      $_db.wordTimings,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordTimingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LearningWordsTable, List<LearningWord>>
  _learningWordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.learningWords,
    aliasName: $_aliasNameGenerator(db.words.id, db.learningWords.wordId),
  );

  $$LearningWordsTableProcessedTableManager get learningWordsRefs {
    final manager = $$LearningWordsTableTableManager(
      $_db,
      $_db.learningWords,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_learningWordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => ColumnFilters(column),
  );

  $$AyahsTableFilterComposer get ayahId {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> wordTimingsRefs(
    Expression<bool> Function($$WordTimingsTableFilterComposer f) f,
  ) {
    final $$WordTimingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordTimings,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordTimingsTableFilterComposer(
            $db: $db,
            $table: $db.wordTimings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> learningWordsRefs(
    Expression<bool> Function($$LearningWordsTableFilterComposer f) f,
  ) {
    final $$LearningWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.learningWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningWordsTableFilterComposer(
            $db: $db,
            $table: $db.learningWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arabic => $composableBuilder(
    column: $table.arabic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => ColumnOrderings(column),
  );

  $$AyahsTableOrderingComposer get ayahId {
    final $$AyahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableOrderingComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get arabic =>
      $composableBuilder(column: $table.arabic, builder: (column) => column);

  GeneratedColumn<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<String> get root =>
      $composableBuilder(column: $table.root, builder: (column) => column);

  $$AyahsTableAnnotationComposer get ayahId {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> wordTimingsRefs<T extends Object>(
    Expression<T> Function($$WordTimingsTableAnnotationComposer a) f,
  ) {
    final $$WordTimingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordTimings,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordTimingsTableAnnotationComposer(
            $db: $db,
            $table: $db.wordTimings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> learningWordsRefs<T extends Object>(
    Expression<T> Function($$LearningWordsTableAnnotationComposer a) f,
  ) {
    final $$LearningWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.learningWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearningWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.learningWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({
            bool ayahId,
            bool wordTimingsRefs,
            bool learningWordsRefs,
          })
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> arabic = const Value.absent(),
                Value<String> normalized = const Value.absent(),
                Value<String?> translation = const Value.absent(),
                Value<String?> lemma = const Value.absent(),
                Value<String?> root = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                ayahId: ayahId,
                position: position,
                arabic: arabic,
                normalized: normalized,
                translation: translation,
                lemma: lemma,
                root: root,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ayahId,
                required int position,
                required String arabic,
                required String normalized,
                Value<String?> translation = const Value.absent(),
                Value<String?> lemma = const Value.absent(),
                Value<String?> root = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                ayahId: ayahId,
                position: position,
                arabic: arabic,
                normalized: normalized,
                translation: translation,
                lemma: lemma,
                root: root,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WordsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ayahId = false,
                wordTimingsRefs = false,
                learningWordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wordTimingsRefs) db.wordTimings,
                    if (learningWordsRefs) db.learningWords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ayahId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ayahId,
                                    referencedTable: $$WordsTableReferences
                                        ._ayahIdTable(db),
                                    referencedColumn: $$WordsTableReferences
                                        ._ayahIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wordTimingsRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          WordTiming
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._wordTimingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).wordTimingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (learningWordsRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          LearningWord
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._learningWordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).learningWordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({
        bool ayahId,
        bool wordTimingsRefs,
        bool learningWordsRefs,
      })
    >;
typedef $$WordTimingsTableCreateCompanionBuilder =
    WordTimingsCompanion Function({
      Value<int> id,
      required int wordId,
      required String reciterId,
      required int startMs,
      required int endMs,
    });
typedef $$WordTimingsTableUpdateCompanionBuilder =
    WordTimingsCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<String> reciterId,
      Value<int> startMs,
      Value<int> endMs,
    });

final class $$WordTimingsTableReferences
    extends BaseReferences<_$AppDatabase, $WordTimingsTable, WordTiming> {
  $$WordTimingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) => db.words.createAlias(
    $_aliasNameGenerator(db.wordTimings.wordId, db.words.id),
  );

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordTimingsTableFilterComposer
    extends Composer<_$AppDatabase, $WordTimingsTable> {
  $$WordTimingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reciterId => $composableBuilder(
    column: $table.reciterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordTimingsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordTimingsTable> {
  $$WordTimingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reciterId => $composableBuilder(
    column: $table.reciterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordTimingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordTimingsTable> {
  $$WordTimingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reciterId =>
      $composableBuilder(column: $table.reciterId, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordTimingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordTimingsTable,
          WordTiming,
          $$WordTimingsTableFilterComposer,
          $$WordTimingsTableOrderingComposer,
          $$WordTimingsTableAnnotationComposer,
          $$WordTimingsTableCreateCompanionBuilder,
          $$WordTimingsTableUpdateCompanionBuilder,
          (WordTiming, $$WordTimingsTableReferences),
          WordTiming,
          PrefetchHooks Function({bool wordId})
        > {
  $$WordTimingsTableTableManager(_$AppDatabase db, $WordTimingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordTimingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordTimingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordTimingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String> reciterId = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
              }) => WordTimingsCompanion(
                id: id,
                wordId: wordId,
                reciterId: reciterId,
                startMs: startMs,
                endMs: endMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required String reciterId,
                required int startMs,
                required int endMs,
              }) => WordTimingsCompanion.insert(
                id: id,
                wordId: wordId,
                reciterId: reciterId,
                startMs: startMs,
                endMs: endMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordTimingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$WordTimingsTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$WordTimingsTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordTimingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordTimingsTable,
      WordTiming,
      $$WordTimingsTableFilterComposer,
      $$WordTimingsTableOrderingComposer,
      $$WordTimingsTableAnnotationComposer,
      $$WordTimingsTableCreateCompanionBuilder,
      $$WordTimingsTableUpdateCompanionBuilder,
      (WordTiming, $$WordTimingsTableReferences),
      WordTiming,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$RecitersTableCreateCompanionBuilder =
    RecitersCompanion Function({
      required String id,
      required String slug,
      required String nameAr,
      required String nameEn,
      required String style,
      Value<bool> isDownloaded,
      Value<int> rowid,
    });
typedef $$RecitersTableUpdateCompanionBuilder =
    RecitersCompanion Function({
      Value<String> id,
      Value<String> slug,
      Value<String> nameAr,
      Value<String> nameEn,
      Value<String> style,
      Value<bool> isDownloaded,
      Value<int> rowid,
    });

class $$RecitersTableFilterComposer
    extends Composer<_$AppDatabase, $RecitersTable> {
  $$RecitersTableFilterComposer({
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

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecitersTableOrderingComposer
    extends Composer<_$AppDatabase, $RecitersTable> {
  $$RecitersTableOrderingComposer({
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

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecitersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecitersTable> {
  $$RecitersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => column,
  );
}

class $$RecitersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecitersTable,
          Reciter,
          $$RecitersTableFilterComposer,
          $$RecitersTableOrderingComposer,
          $$RecitersTableAnnotationComposer,
          $$RecitersTableCreateCompanionBuilder,
          $$RecitersTableUpdateCompanionBuilder,
          (Reciter, BaseReferences<_$AppDatabase, $RecitersTable, Reciter>),
          Reciter,
          PrefetchHooks Function()
        > {
  $$RecitersTableTableManager(_$AppDatabase db, $RecitersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecitersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecitersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecitersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecitersCompanion(
                id: id,
                slug: slug,
                nameAr: nameAr,
                nameEn: nameEn,
                style: style,
                isDownloaded: isDownloaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String slug,
                required String nameAr,
                required String nameEn,
                required String style,
                Value<bool> isDownloaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecitersCompanion.insert(
                id: id,
                slug: slug,
                nameAr: nameAr,
                nameEn: nameEn,
                style: style,
                isDownloaded: isDownloaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecitersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecitersTable,
      Reciter,
      $$RecitersTableFilterComposer,
      $$RecitersTableOrderingComposer,
      $$RecitersTableAnnotationComposer,
      $$RecitersTableCreateCompanionBuilder,
      $$RecitersTableUpdateCompanionBuilder,
      (Reciter, BaseReferences<_$AppDatabase, $RecitersTable, Reciter>),
      Reciter,
      PrefetchHooks Function()
    >;
typedef $$TranslatorsTableCreateCompanionBuilder =
    TranslatorsCompanion Function({
      required int id,
      required String name,
      required String languageCode,
      required String source,
      Value<int> rowid,
    });
typedef $$TranslatorsTableUpdateCompanionBuilder =
    TranslatorsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> languageCode,
      Value<String> source,
      Value<int> rowid,
    });

final class $$TranslatorsTableReferences
    extends BaseReferences<_$AppDatabase, $TranslatorsTable, Translator> {
  $$TranslatorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TranslationsTable, List<Translation>>
  _translationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.translations,
    aliasName: $_aliasNameGenerator(
      db.translators.id,
      db.translations.translatorId,
    ),
  );

  $$TranslationsTableProcessedTableManager get translationsRefs {
    final manager = $$TranslationsTableTableManager(
      $_db,
      $_db.translations,
    ).filter((f) => f.translatorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_translationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TranslatorsTableFilterComposer
    extends Composer<_$AppDatabase, $TranslatorsTable> {
  $$TranslatorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> translationsRefs(
    Expression<bool> Function($$TranslationsTableFilterComposer f) f,
  ) {
    final $$TranslationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.translatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableFilterComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TranslatorsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranslatorsTable> {
  $$TranslatorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranslatorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranslatorsTable> {
  $$TranslatorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  Expression<T> translationsRefs<T extends Object>(
    Expression<T> Function($$TranslationsTableAnnotationComposer a) f,
  ) {
    final $$TranslationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.translations,
      getReferencedColumn: (t) => t.translatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslationsTableAnnotationComposer(
            $db: $db,
            $table: $db.translations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TranslatorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranslatorsTable,
          Translator,
          $$TranslatorsTableFilterComposer,
          $$TranslatorsTableOrderingComposer,
          $$TranslatorsTableAnnotationComposer,
          $$TranslatorsTableCreateCompanionBuilder,
          $$TranslatorsTableUpdateCompanionBuilder,
          (Translator, $$TranslatorsTableReferences),
          Translator,
          PrefetchHooks Function({bool translationsRefs})
        > {
  $$TranslatorsTableTableManager(_$AppDatabase db, $TranslatorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslatorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslatorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslatorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranslatorsCompanion(
                id: id,
                name: name,
                languageCode: languageCode,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                required String name,
                required String languageCode,
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => TranslatorsCompanion.insert(
                id: id,
                name: name,
                languageCode: languageCode,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TranslatorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({translationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (translationsRefs) db.translations],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (translationsRefs)
                    await $_getPrefetchedData<
                      Translator,
                      $TranslatorsTable,
                      Translation
                    >(
                      currentTable: table,
                      referencedTable: $$TranslatorsTableReferences
                          ._translationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TranslatorsTableReferences(
                            db,
                            table,
                            p0,
                          ).translationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.translatorId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TranslatorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranslatorsTable,
      Translator,
      $$TranslatorsTableFilterComposer,
      $$TranslatorsTableOrderingComposer,
      $$TranslatorsTableAnnotationComposer,
      $$TranslatorsTableCreateCompanionBuilder,
      $$TranslatorsTableUpdateCompanionBuilder,
      (Translator, $$TranslatorsTableReferences),
      Translator,
      PrefetchHooks Function({bool translationsRefs})
    >;
typedef $$TranslationsTableCreateCompanionBuilder =
    TranslationsCompanion Function({
      Value<int> id,
      required int ayahId,
      required int translatorId,
      required String languageCode,
      required String textValue,
    });
typedef $$TranslationsTableUpdateCompanionBuilder =
    TranslationsCompanion Function({
      Value<int> id,
      Value<int> ayahId,
      Value<int> translatorId,
      Value<String> languageCode,
      Value<String> textValue,
    });

final class $$TranslationsTableReferences
    extends BaseReferences<_$AppDatabase, $TranslationsTable, Translation> {
  $$TranslationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AyahsTable _ayahIdTable(_$AppDatabase db) => db.ayahs.createAlias(
    $_aliasNameGenerator(db.translations.ayahId, db.ayahs.id),
  );

  $$AyahsTableProcessedTableManager get ayahId {
    final $_column = $_itemColumn<int>('ayah_id')!;

    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ayahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TranslatorsTable _translatorIdTable(_$AppDatabase db) =>
      db.translators.createAlias(
        $_aliasNameGenerator(db.translations.translatorId, db.translators.id),
      );

  $$TranslatorsTableProcessedTableManager get translatorId {
    final $_column = $_itemColumn<int>('translator_id')!;

    final manager = $$TranslatorsTableTableManager(
      $_db,
      $_db.translators,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_translatorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TranslationsTableFilterComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textValue => $composableBuilder(
    column: $table.textValue,
    builder: (column) => ColumnFilters(column),
  );

  $$AyahsTableFilterComposer get ayahId {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TranslatorsTableFilterComposer get translatorId {
    final $$TranslatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translatorId,
      referencedTable: $db.translators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslatorsTableFilterComposer(
            $db: $db,
            $table: $db.translators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranslationsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textValue => $composableBuilder(
    column: $table.textValue,
    builder: (column) => ColumnOrderings(column),
  );

  $$AyahsTableOrderingComposer get ayahId {
    final $$AyahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableOrderingComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TranslatorsTableOrderingComposer get translatorId {
    final $$TranslatorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translatorId,
      referencedTable: $db.translators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslatorsTableOrderingComposer(
            $db: $db,
            $table: $db.translators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranslationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textValue =>
      $composableBuilder(column: $table.textValue, builder: (column) => column);

  $$AyahsTableAnnotationComposer get ayahId {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TranslatorsTableAnnotationComposer get translatorId {
    final $$TranslatorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.translatorId,
      referencedTable: $db.translators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranslatorsTableAnnotationComposer(
            $db: $db,
            $table: $db.translators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranslationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranslationsTable,
          Translation,
          $$TranslationsTableFilterComposer,
          $$TranslationsTableOrderingComposer,
          $$TranslationsTableAnnotationComposer,
          $$TranslationsTableCreateCompanionBuilder,
          $$TranslationsTableUpdateCompanionBuilder,
          (Translation, $$TranslationsTableReferences),
          Translation,
          PrefetchHooks Function({bool ayahId, bool translatorId})
        > {
  $$TranslationsTableTableManager(_$AppDatabase db, $TranslationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<int> translatorId = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String> textValue = const Value.absent(),
              }) => TranslationsCompanion(
                id: id,
                ayahId: ayahId,
                translatorId: translatorId,
                languageCode: languageCode,
                textValue: textValue,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ayahId,
                required int translatorId,
                required String languageCode,
                required String textValue,
              }) => TranslationsCompanion.insert(
                id: id,
                ayahId: ayahId,
                translatorId: translatorId,
                languageCode: languageCode,
                textValue: textValue,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TranslationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ayahId = false, translatorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ayahId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ayahId,
                                referencedTable: $$TranslationsTableReferences
                                    ._ayahIdTable(db),
                                referencedColumn: $$TranslationsTableReferences
                                    ._ayahIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (translatorId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.translatorId,
                                referencedTable: $$TranslationsTableReferences
                                    ._translatorIdTable(db),
                                referencedColumn: $$TranslationsTableReferences
                                    ._translatorIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TranslationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranslationsTable,
      Translation,
      $$TranslationsTableFilterComposer,
      $$TranslationsTableOrderingComposer,
      $$TranslationsTableAnnotationComposer,
      $$TranslationsTableCreateCompanionBuilder,
      $$TranslationsTableUpdateCompanionBuilder,
      (Translation, $$TranslationsTableReferences),
      Translation,
      PrefetchHooks Function({bool ayahId, bool translatorId})
    >;
typedef $$TafsirSourcesTableCreateCompanionBuilder =
    TafsirSourcesCompanion Function({
      required int id,
      required String slug,
      required String nameAr,
      required String nameEn,
      required String languageCode,
      Value<int> rowid,
    });
typedef $$TafsirSourcesTableUpdateCompanionBuilder =
    TafsirSourcesCompanion Function({
      Value<int> id,
      Value<String> slug,
      Value<String> nameAr,
      Value<String> nameEn,
      Value<String> languageCode,
      Value<int> rowid,
    });

final class $$TafsirSourcesTableReferences
    extends BaseReferences<_$AppDatabase, $TafsirSourcesTable, TafsirSource> {
  $$TafsirSourcesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TafsirsTable, List<Tafsir>> _tafsirsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tafsirs,
    aliasName: $_aliasNameGenerator(
      db.tafsirSources.id,
      db.tafsirs.tafsirSourceId,
    ),
  );

  $$TafsirsTableProcessedTableManager get tafsirsRefs {
    final manager = $$TafsirsTableTableManager(
      $_db,
      $_db.tafsirs,
    ).filter((f) => f.tafsirSourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tafsirsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TafsirSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $TafsirSourcesTable> {
  $$TafsirSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tafsirsRefs(
    Expression<bool> Function($$TafsirsTableFilterComposer f) f,
  ) {
    final $$TafsirsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tafsirs,
      getReferencedColumn: (t) => t.tafsirSourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TafsirsTableFilterComposer(
            $db: $db,
            $table: $db.tafsirs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TafsirSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $TafsirSourcesTable> {
  $$TafsirSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TafsirSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TafsirSourcesTable> {
  $$TafsirSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  Expression<T> tafsirsRefs<T extends Object>(
    Expression<T> Function($$TafsirsTableAnnotationComposer a) f,
  ) {
    final $$TafsirsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tafsirs,
      getReferencedColumn: (t) => t.tafsirSourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TafsirsTableAnnotationComposer(
            $db: $db,
            $table: $db.tafsirs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TafsirSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TafsirSourcesTable,
          TafsirSource,
          $$TafsirSourcesTableFilterComposer,
          $$TafsirSourcesTableOrderingComposer,
          $$TafsirSourcesTableAnnotationComposer,
          $$TafsirSourcesTableCreateCompanionBuilder,
          $$TafsirSourcesTableUpdateCompanionBuilder,
          (TafsirSource, $$TafsirSourcesTableReferences),
          TafsirSource,
          PrefetchHooks Function({bool tafsirsRefs})
        > {
  $$TafsirSourcesTableTableManager(_$AppDatabase db, $TafsirSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TafsirSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TafsirSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TafsirSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TafsirSourcesCompanion(
                id: id,
                slug: slug,
                nameAr: nameAr,
                nameEn: nameEn,
                languageCode: languageCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                required String slug,
                required String nameAr,
                required String nameEn,
                required String languageCode,
                Value<int> rowid = const Value.absent(),
              }) => TafsirSourcesCompanion.insert(
                id: id,
                slug: slug,
                nameAr: nameAr,
                nameEn: nameEn,
                languageCode: languageCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TafsirSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tafsirsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tafsirsRefs) db.tafsirs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tafsirsRefs)
                    await $_getPrefetchedData<
                      TafsirSource,
                      $TafsirSourcesTable,
                      Tafsir
                    >(
                      currentTable: table,
                      referencedTable: $$TafsirSourcesTableReferences
                          ._tafsirsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TafsirSourcesTableReferences(
                            db,
                            table,
                            p0,
                          ).tafsirsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.tafsirSourceId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TafsirSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TafsirSourcesTable,
      TafsirSource,
      $$TafsirSourcesTableFilterComposer,
      $$TafsirSourcesTableOrderingComposer,
      $$TafsirSourcesTableAnnotationComposer,
      $$TafsirSourcesTableCreateCompanionBuilder,
      $$TafsirSourcesTableUpdateCompanionBuilder,
      (TafsirSource, $$TafsirSourcesTableReferences),
      TafsirSource,
      PrefetchHooks Function({bool tafsirsRefs})
    >;
typedef $$TafsirsTableCreateCompanionBuilder =
    TafsirsCompanion Function({
      Value<int> id,
      required int ayahId,
      required int tafsirSourceId,
      required String textValue,
    });
typedef $$TafsirsTableUpdateCompanionBuilder =
    TafsirsCompanion Function({
      Value<int> id,
      Value<int> ayahId,
      Value<int> tafsirSourceId,
      Value<String> textValue,
    });

final class $$TafsirsTableReferences
    extends BaseReferences<_$AppDatabase, $TafsirsTable, Tafsir> {
  $$TafsirsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AyahsTable _ayahIdTable(_$AppDatabase db) => db.ayahs.createAlias(
    $_aliasNameGenerator(db.tafsirs.ayahId, db.ayahs.id),
  );

  $$AyahsTableProcessedTableManager get ayahId {
    final $_column = $_itemColumn<int>('ayah_id')!;

    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ayahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TafsirSourcesTable _tafsirSourceIdTable(_$AppDatabase db) =>
      db.tafsirSources.createAlias(
        $_aliasNameGenerator(db.tafsirs.tafsirSourceId, db.tafsirSources.id),
      );

  $$TafsirSourcesTableProcessedTableManager get tafsirSourceId {
    final $_column = $_itemColumn<int>('tafsir_source_id')!;

    final manager = $$TafsirSourcesTableTableManager(
      $_db,
      $_db.tafsirSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tafsirSourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TafsirsTableFilterComposer
    extends Composer<_$AppDatabase, $TafsirsTable> {
  $$TafsirsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textValue => $composableBuilder(
    column: $table.textValue,
    builder: (column) => ColumnFilters(column),
  );

  $$AyahsTableFilterComposer get ayahId {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TafsirSourcesTableFilterComposer get tafsirSourceId {
    final $$TafsirSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tafsirSourceId,
      referencedTable: $db.tafsirSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TafsirSourcesTableFilterComposer(
            $db: $db,
            $table: $db.tafsirSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TafsirsTableOrderingComposer
    extends Composer<_$AppDatabase, $TafsirsTable> {
  $$TafsirsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textValue => $composableBuilder(
    column: $table.textValue,
    builder: (column) => ColumnOrderings(column),
  );

  $$AyahsTableOrderingComposer get ayahId {
    final $$AyahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableOrderingComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TafsirSourcesTableOrderingComposer get tafsirSourceId {
    final $$TafsirSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tafsirSourceId,
      referencedTable: $db.tafsirSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TafsirSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.tafsirSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TafsirsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TafsirsTable> {
  $$TafsirsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get textValue =>
      $composableBuilder(column: $table.textValue, builder: (column) => column);

  $$AyahsTableAnnotationComposer get ayahId {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TafsirSourcesTableAnnotationComposer get tafsirSourceId {
    final $$TafsirSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tafsirSourceId,
      referencedTable: $db.tafsirSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TafsirSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.tafsirSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TafsirsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TafsirsTable,
          Tafsir,
          $$TafsirsTableFilterComposer,
          $$TafsirsTableOrderingComposer,
          $$TafsirsTableAnnotationComposer,
          $$TafsirsTableCreateCompanionBuilder,
          $$TafsirsTableUpdateCompanionBuilder,
          (Tafsir, $$TafsirsTableReferences),
          Tafsir,
          PrefetchHooks Function({bool ayahId, bool tafsirSourceId})
        > {
  $$TafsirsTableTableManager(_$AppDatabase db, $TafsirsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TafsirsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TafsirsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TafsirsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<int> tafsirSourceId = const Value.absent(),
                Value<String> textValue = const Value.absent(),
              }) => TafsirsCompanion(
                id: id,
                ayahId: ayahId,
                tafsirSourceId: tafsirSourceId,
                textValue: textValue,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ayahId,
                required int tafsirSourceId,
                required String textValue,
              }) => TafsirsCompanion.insert(
                id: id,
                ayahId: ayahId,
                tafsirSourceId: tafsirSourceId,
                textValue: textValue,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TafsirsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ayahId = false, tafsirSourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ayahId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ayahId,
                                referencedTable: $$TafsirsTableReferences
                                    ._ayahIdTable(db),
                                referencedColumn: $$TafsirsTableReferences
                                    ._ayahIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tafsirSourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tafsirSourceId,
                                referencedTable: $$TafsirsTableReferences
                                    ._tafsirSourceIdTable(db),
                                referencedColumn: $$TafsirsTableReferences
                                    ._tafsirSourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TafsirsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TafsirsTable,
      Tafsir,
      $$TafsirsTableFilterComposer,
      $$TafsirsTableOrderingComposer,
      $$TafsirsTableAnnotationComposer,
      $$TafsirsTableCreateCompanionBuilder,
      $$TafsirsTableUpdateCompanionBuilder,
      (Tafsir, $$TafsirsTableReferences),
      Tafsir,
      PrefetchHooks Function({bool ayahId, bool tafsirSourceId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      required int surahId,
      required int ayahId,
      required int ayahNumber,
      Value<String?> label,
      Value<int?> color,
      Value<DateTime> createdAt,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      Value<int> surahId,
      Value<int> ayahId,
      Value<int> ayahNumber,
      Value<String?> label,
      Value<int?> color,
      Value<DateTime> createdAt,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SurahsTable _surahIdTable(_$AppDatabase db) => db.surahs.createAlias(
    $_aliasNameGenerator(db.bookmarks.surahId, db.surahs.id),
  );

  $$SurahsTableProcessedTableManager get surahId {
    final $_column = $_itemColumn<int>('surah_id')!;

    final manager = $$SurahsTableTableManager(
      $_db,
      $_db.surahs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AyahsTable _ayahIdTable(_$AppDatabase db) => db.ayahs.createAlias(
    $_aliasNameGenerator(db.bookmarks.ayahId, db.ayahs.id),
  );

  $$AyahsTableProcessedTableManager get ayahId {
    final $_column = $_itemColumn<int>('ayah_id')!;

    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ayahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SurahsTableFilterComposer get surahId {
    final $$SurahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahId,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableFilterComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AyahsTableFilterComposer get ayahId {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SurahsTableOrderingComposer get surahId {
    final $$SurahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahId,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableOrderingComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AyahsTableOrderingComposer get ayahId {
    final $$AyahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableOrderingComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ayahNumber => $composableBuilder(
    column: $table.ayahNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SurahsTableAnnotationComposer get surahId {
    final $$SurahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahId,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurahsTableAnnotationComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AyahsTableAnnotationComposer get ayahId {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, $$BookmarksTableReferences),
          Bookmark,
          PrefetchHooks Function({bool surahId, bool ayahId})
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surahId = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<int> ayahNumber = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                surahId: surahId,
                ayahId: ayahId,
                ayahNumber: ayahNumber,
                label: label,
                color: color,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surahId,
                required int ayahId,
                required int ayahNumber,
                Value<String?> label = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                surahId: surahId,
                ayahId: ayahId,
                ayahNumber: ayahNumber,
                label: label,
                color: color,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({surahId = false, ayahId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (surahId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.surahId,
                                referencedTable: $$BookmarksTableReferences
                                    ._surahIdTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._surahIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (ayahId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ayahId,
                                referencedTable: $$BookmarksTableReferences
                                    ._ayahIdTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._ayahIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, $$BookmarksTableReferences),
      Bookmark,
      PrefetchHooks Function({bool surahId, bool ayahId})
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      required int ayahId,
      required String textValue,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      Value<int> ayahId,
      Value<String> textValue,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, Note> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AyahsTable _ayahIdTable(_$AppDatabase db) =>
      db.ayahs.createAlias($_aliasNameGenerator(db.notes.ayahId, db.ayahs.id));

  $$AyahsTableProcessedTableManager get ayahId {
    final $_column = $_itemColumn<int>('ayah_id')!;

    final manager = $$AyahsTableTableManager(
      $_db,
      $_db.ayahs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ayahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textValue => $composableBuilder(
    column: $table.textValue,
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

  $$AyahsTableFilterComposer get ayahId {
    final $$AyahsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableFilterComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textValue => $composableBuilder(
    column: $table.textValue,
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

  $$AyahsTableOrderingComposer get ayahId {
    final $$AyahsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableOrderingComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get textValue =>
      $composableBuilder(column: $table.textValue, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AyahsTableAnnotationComposer get ayahId {
    final $$AyahsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ayahId,
      referencedTable: $db.ayahs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AyahsTableAnnotationComposer(
            $db: $db,
            $table: $db.ayahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, $$NotesTableReferences),
          Note,
          PrefetchHooks Function({bool ayahId})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<String> textValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                ayahId: ayahId,
                textValue: textValue,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ayahId,
                required String textValue,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                ayahId: ayahId,
                textValue: textValue,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NotesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({ayahId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ayahId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ayahId,
                                referencedTable: $$NotesTableReferences
                                    ._ayahIdTable(db),
                                referencedColumn: $$NotesTableReferences
                                    ._ayahIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, $$NotesTableReferences),
      Note,
      PrefetchHooks Function({bool ayahId})
    >;
typedef $$LastPositionTableCreateCompanionBuilder =
    LastPositionCompanion Function({
      Value<int> id,
      required int surahId,
      required int ayahId,
      Value<int?> page,
      Value<DateTime> updatedAt,
    });
typedef $$LastPositionTableUpdateCompanionBuilder =
    LastPositionCompanion Function({
      Value<int> id,
      Value<int> surahId,
      Value<int> ayahId,
      Value<int?> page,
      Value<DateTime> updatedAt,
    });

class $$LastPositionTableFilterComposer
    extends Composer<_$AppDatabase, $LastPositionTable> {
  $$LastPositionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LastPositionTableOrderingComposer
    extends Composer<_$AppDatabase, $LastPositionTable> {
  $$LastPositionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahId => $composableBuilder(
    column: $table.ayahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LastPositionTableAnnotationComposer
    extends Composer<_$AppDatabase, $LastPositionTable> {
  $$LastPositionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LastPositionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LastPositionTable,
          LastPositionData,
          $$LastPositionTableFilterComposer,
          $$LastPositionTableOrderingComposer,
          $$LastPositionTableAnnotationComposer,
          $$LastPositionTableCreateCompanionBuilder,
          $$LastPositionTableUpdateCompanionBuilder,
          (
            LastPositionData,
            BaseReferences<_$AppDatabase, $LastPositionTable, LastPositionData>,
          ),
          LastPositionData,
          PrefetchHooks Function()
        > {
  $$LastPositionTableTableManager(_$AppDatabase db, $LastPositionTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LastPositionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LastPositionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LastPositionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> surahId = const Value.absent(),
                Value<int> ayahId = const Value.absent(),
                Value<int?> page = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LastPositionCompanion(
                id: id,
                surahId: surahId,
                ayahId: ayahId,
                page: page,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int surahId,
                required int ayahId,
                Value<int?> page = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LastPositionCompanion.insert(
                id: id,
                surahId: surahId,
                ayahId: ayahId,
                page: page,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LastPositionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LastPositionTable,
      LastPositionData,
      $$LastPositionTableFilterComposer,
      $$LastPositionTableOrderingComposer,
      $$LastPositionTableAnnotationComposer,
      $$LastPositionTableCreateCompanionBuilder,
      $$LastPositionTableUpdateCompanionBuilder,
      (
        LastPositionData,
        BaseReferences<_$AppDatabase, $LastPositionTable, LastPositionData>,
      ),
      LastPositionData,
      PrefetchHooks Function()
    >;
typedef $$ReadingHistoryTableCreateCompanionBuilder =
    ReadingHistoryCompanion Function({
      Value<int> id,
      required String date,
      required int surahId,
      Value<int> ayahsRead,
    });
typedef $$ReadingHistoryTableUpdateCompanionBuilder =
    ReadingHistoryCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<int> surahId,
      Value<int> ayahsRead,
    });

class $$ReadingHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayahsRead => $composableBuilder(
    column: $table.ayahsRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayahsRead => $composableBuilder(
    column: $table.ayahsRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingHistoryTable> {
  $$ReadingHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<int> get ayahsRead =>
      $composableBuilder(column: $table.ayahsRead, builder: (column) => column);
}

class $$ReadingHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingHistoryTable,
          ReadingHistoryData,
          $$ReadingHistoryTableFilterComposer,
          $$ReadingHistoryTableOrderingComposer,
          $$ReadingHistoryTableAnnotationComposer,
          $$ReadingHistoryTableCreateCompanionBuilder,
          $$ReadingHistoryTableUpdateCompanionBuilder,
          (
            ReadingHistoryData,
            BaseReferences<
              _$AppDatabase,
              $ReadingHistoryTable,
              ReadingHistoryData
            >,
          ),
          ReadingHistoryData,
          PrefetchHooks Function()
        > {
  $$ReadingHistoryTableTableManager(
    _$AppDatabase db,
    $ReadingHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> surahId = const Value.absent(),
                Value<int> ayahsRead = const Value.absent(),
              }) => ReadingHistoryCompanion(
                id: id,
                date: date,
                surahId: surahId,
                ayahsRead: ayahsRead,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required int surahId,
                Value<int> ayahsRead = const Value.absent(),
              }) => ReadingHistoryCompanion.insert(
                id: id,
                date: date,
                surahId: surahId,
                ayahsRead: ayahsRead,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingHistoryTable,
      ReadingHistoryData,
      $$ReadingHistoryTableFilterComposer,
      $$ReadingHistoryTableOrderingComposer,
      $$ReadingHistoryTableAnnotationComposer,
      $$ReadingHistoryTableCreateCompanionBuilder,
      $$ReadingHistoryTableUpdateCompanionBuilder,
      (
        ReadingHistoryData,
        BaseReferences<_$AppDatabase, $ReadingHistoryTable, ReadingHistoryData>,
      ),
      ReadingHistoryData,
      PrefetchHooks Function()
    >;
typedef $$LearningWordsTableCreateCompanionBuilder =
    LearningWordsCompanion Function({
      Value<int> id,
      required int wordId,
      required String status,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      required DateTime nextReviewAt,
      Value<DateTime?> lastReviewAt,
    });
typedef $$LearningWordsTableUpdateCompanionBuilder =
    LearningWordsCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<String> status,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<DateTime> nextReviewAt,
      Value<DateTime?> lastReviewAt,
    });

final class $$LearningWordsTableReferences
    extends BaseReferences<_$AppDatabase, $LearningWordsTable, LearningWord> {
  $$LearningWordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordsTable _wordIdTable(_$AppDatabase db) => db.words.createAlias(
    $_aliasNameGenerator(db.learningWords.wordId, db.words.id),
  );

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LearningWordsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningWordsTable> {
  $$LearningWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearningWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningWordsTable> {
  $$LearningWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearningWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningWordsTable> {
  $$LearningWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => column,
  );

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearningWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningWordsTable,
          LearningWord,
          $$LearningWordsTableFilterComposer,
          $$LearningWordsTableOrderingComposer,
          $$LearningWordsTableAnnotationComposer,
          $$LearningWordsTableCreateCompanionBuilder,
          $$LearningWordsTableUpdateCompanionBuilder,
          (LearningWord, $$LearningWordsTableReferences),
          LearningWord,
          PrefetchHooks Function({bool wordId})
        > {
  $$LearningWordsTableTableManager(_$AppDatabase db, $LearningWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<DateTime> nextReviewAt = const Value.absent(),
                Value<DateTime?> lastReviewAt = const Value.absent(),
              }) => LearningWordsCompanion(
                id: id,
                wordId: wordId,
                status: status,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                nextReviewAt: nextReviewAt,
                lastReviewAt: lastReviewAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required String status,
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                required DateTime nextReviewAt,
                Value<DateTime?> lastReviewAt = const Value.absent(),
              }) => LearningWordsCompanion.insert(
                id: id,
                wordId: wordId,
                status: status,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                nextReviewAt: nextReviewAt,
                lastReviewAt: lastReviewAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LearningWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$LearningWordsTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$LearningWordsTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LearningWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningWordsTable,
      LearningWord,
      $$LearningWordsTableFilterComposer,
      $$LearningWordsTableOrderingComposer,
      $$LearningWordsTableAnnotationComposer,
      $$LearningWordsTableCreateCompanionBuilder,
      $$LearningWordsTableUpdateCompanionBuilder,
      (LearningWord, $$LearningWordsTableReferences),
      LearningWord,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$AudioCacheMetadataTableCreateCompanionBuilder =
    AudioCacheMetadataCompanion Function({
      Value<int> id,
      required String reciterId,
      required int surahId,
      required String filePath,
      required int fileSizeBytes,
      Value<DateTime> downloadedAt,
      Value<DateTime?> lastPlayedAt,
    });
typedef $$AudioCacheMetadataTableUpdateCompanionBuilder =
    AudioCacheMetadataCompanion Function({
      Value<int> id,
      Value<String> reciterId,
      Value<int> surahId,
      Value<String> filePath,
      Value<int> fileSizeBytes,
      Value<DateTime> downloadedAt,
      Value<DateTime?> lastPlayedAt,
    });

class $$AudioCacheMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $AudioCacheMetadataTable> {
  $$AudioCacheMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reciterId => $composableBuilder(
    column: $table.reciterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AudioCacheMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioCacheMetadataTable> {
  $$AudioCacheMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reciterId => $composableBuilder(
    column: $table.reciterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surahId => $composableBuilder(
    column: $table.surahId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AudioCacheMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioCacheMetadataTable> {
  $$AudioCacheMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reciterId =>
      $composableBuilder(column: $table.reciterId, builder: (column) => column);

  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );
}

class $$AudioCacheMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudioCacheMetadataTable,
          AudioCacheMetadatum,
          $$AudioCacheMetadataTableFilterComposer,
          $$AudioCacheMetadataTableOrderingComposer,
          $$AudioCacheMetadataTableAnnotationComposer,
          $$AudioCacheMetadataTableCreateCompanionBuilder,
          $$AudioCacheMetadataTableUpdateCompanionBuilder,
          (
            AudioCacheMetadatum,
            BaseReferences<
              _$AppDatabase,
              $AudioCacheMetadataTable,
              AudioCacheMetadatum
            >,
          ),
          AudioCacheMetadatum,
          PrefetchHooks Function()
        > {
  $$AudioCacheMetadataTableTableManager(
    _$AppDatabase db,
    $AudioCacheMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioCacheMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioCacheMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioCacheMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reciterId = const Value.absent(),
                Value<int> surahId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
              }) => AudioCacheMetadataCompanion(
                id: id,
                reciterId: reciterId,
                surahId: surahId,
                filePath: filePath,
                fileSizeBytes: fileSizeBytes,
                downloadedAt: downloadedAt,
                lastPlayedAt: lastPlayedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String reciterId,
                required int surahId,
                required String filePath,
                required int fileSizeBytes,
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
              }) => AudioCacheMetadataCompanion.insert(
                id: id,
                reciterId: reciterId,
                surahId: surahId,
                filePath: filePath,
                fileSizeBytes: fileSizeBytes,
                downloadedAt: downloadedAt,
                lastPlayedAt: lastPlayedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AudioCacheMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudioCacheMetadataTable,
      AudioCacheMetadatum,
      $$AudioCacheMetadataTableFilterComposer,
      $$AudioCacheMetadataTableOrderingComposer,
      $$AudioCacheMetadataTableAnnotationComposer,
      $$AudioCacheMetadataTableCreateCompanionBuilder,
      $$AudioCacheMetadataTableUpdateCompanionBuilder,
      (
        AudioCacheMetadatum,
        BaseReferences<
          _$AppDatabase,
          $AudioCacheMetadataTable,
          AudioCacheMetadatum
        >,
      ),
      AudioCacheMetadatum,
      PrefetchHooks Function()
    >;
typedef $$SettingsEntriesTableCreateCompanionBuilder =
    SettingsEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsEntriesTableUpdateCompanionBuilder =
    SettingsEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsEntriesTable,
          SettingsEntry,
          $$SettingsEntriesTableFilterComposer,
          $$SettingsEntriesTableOrderingComposer,
          $$SettingsEntriesTableAnnotationComposer,
          $$SettingsEntriesTableCreateCompanionBuilder,
          $$SettingsEntriesTableUpdateCompanionBuilder,
          (
            SettingsEntry,
            BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
          ),
          SettingsEntry,
          PrefetchHooks Function()
        > {
  $$SettingsEntriesTableTableManager(
    _$AppDatabase db,
    $SettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsEntriesTable,
      SettingsEntry,
      $$SettingsEntriesTableFilterComposer,
      $$SettingsEntriesTableOrderingComposer,
      $$SettingsEntriesTableAnnotationComposer,
      $$SettingsEntriesTableCreateCompanionBuilder,
      $$SettingsEntriesTableUpdateCompanionBuilder,
      (
        SettingsEntry,
        BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
      ),
      SettingsEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db, _db.ayahs);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$WordTimingsTableTableManager get wordTimings =>
      $$WordTimingsTableTableManager(_db, _db.wordTimings);
  $$RecitersTableTableManager get reciters =>
      $$RecitersTableTableManager(_db, _db.reciters);
  $$TranslatorsTableTableManager get translators =>
      $$TranslatorsTableTableManager(_db, _db.translators);
  $$TranslationsTableTableManager get translations =>
      $$TranslationsTableTableManager(_db, _db.translations);
  $$TafsirSourcesTableTableManager get tafsirSources =>
      $$TafsirSourcesTableTableManager(_db, _db.tafsirSources);
  $$TafsirsTableTableManager get tafsirs =>
      $$TafsirsTableTableManager(_db, _db.tafsirs);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$LastPositionTableTableManager get lastPosition =>
      $$LastPositionTableTableManager(_db, _db.lastPosition);
  $$ReadingHistoryTableTableManager get readingHistory =>
      $$ReadingHistoryTableTableManager(_db, _db.readingHistory);
  $$LearningWordsTableTableManager get learningWords =>
      $$LearningWordsTableTableManager(_db, _db.learningWords);
  $$AudioCacheMetadataTableTableManager get audioCacheMetadata =>
      $$AudioCacheMetadataTableTableManager(_db, _db.audioCacheMetadata);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
}
