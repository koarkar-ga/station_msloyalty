// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'OfflineTransaction.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOfflineTransactionCollection on Isar {
  IsarCollection<OfflineTransaction> get offlineTransactions =>
      this.collection();
}

const OfflineTransactionSchema = CollectionSchema(
  name: r'OfflineTransaction',
  id: 3947851151834405329,
  properties: {
    r'actionType': PropertySchema(
      id: 0,
      name: r'actionType',
      type: IsarType.string,
      enumMap: _OfflineTransactionactionTypeEnumValueMap,
    ),
    r'amountMmk': PropertySchema(
      id: 1,
      name: r'amountMmk',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dynamicTokenId': PropertySchema(
      id: 3,
      name: r'dynamicTokenId',
      type: IsarType.string,
    ),
    r'fuelType': PropertySchema(
      id: 4,
      name: r'fuelType',
      type: IsarType.string,
    ),
    r'isSynced': PropertySchema(
      id: 5,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'paymentType': PropertySchema(
      id: 6,
      name: r'paymentType',
      type: IsarType.string,
    ),
    r'requiredPoints': PropertySchema(
      id: 7,
      name: r'requiredPoints',
      type: IsarType.long,
    ),
    r'rewardId': PropertySchema(
      id: 8,
      name: r'rewardId',
      type: IsarType.long,
    ),
    r'saleLiter': PropertySchema(
      id: 9,
      name: r'saleLiter',
      type: IsarType.double,
    ),
    r'saleType': PropertySchema(
      id: 10,
      name: r'saleType',
      type: IsarType.string,
    ),
    r'stationId': PropertySchema(
      id: 11,
      name: r'stationId',
      type: IsarType.string,
    ),
    r'syncError': PropertySchema(
      id: 12,
      name: r'syncError',
      type: IsarType.string,
    ),
    r'targetUid': PropertySchema(
      id: 13,
      name: r'targetUid',
      type: IsarType.string,
    ),
    r'unitPrice': PropertySchema(
      id: 14,
      name: r'unitPrice',
      type: IsarType.double,
    ),
    r'vehicleNo': PropertySchema(
      id: 15,
      name: r'vehicleNo',
      type: IsarType.string,
    ),
    r'vocNo': PropertySchema(
      id: 16,
      name: r'vocNo',
      type: IsarType.string,
    )
  },
  estimateSize: _offlineTransactionEstimateSize,
  serialize: _offlineTransactionSerialize,
  deserialize: _offlineTransactionDeserialize,
  deserializeProp: _offlineTransactionDeserializeProp,
  idName: r'id',
  indexes: {
    r'actionType': IndexSchema(
      id: -3643111368705296474,
      name: r'actionType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'actionType',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'vocNo': IndexSchema(
      id: 175085456242309576,
      name: r'vocNo',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'vocNo',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isSynced': IndexSchema(
      id: -39763503327887510,
      name: r'isSynced',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isSynced',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _offlineTransactionGetId,
  getLinks: _offlineTransactionGetLinks,
  attach: _offlineTransactionAttach,
  version: '3.1.0+1',
);

int _offlineTransactionEstimateSize(
  OfflineTransaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.actionType.name.length * 3;
  {
    final value = object.dynamicTokenId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fuelType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.saleType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.stationId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.syncError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.targetUid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.vehicleNo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.vocNo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _offlineTransactionSerialize(
  OfflineTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionType.name);
  writer.writeDouble(offsets[1], object.amountMmk);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.dynamicTokenId);
  writer.writeString(offsets[4], object.fuelType);
  writer.writeBool(offsets[5], object.isSynced);
  writer.writeString(offsets[6], object.paymentType);
  writer.writeLong(offsets[7], object.requiredPoints);
  writer.writeLong(offsets[8], object.rewardId);
  writer.writeDouble(offsets[9], object.saleLiter);
  writer.writeString(offsets[10], object.saleType);
  writer.writeString(offsets[11], object.stationId);
  writer.writeString(offsets[12], object.syncError);
  writer.writeString(offsets[13], object.targetUid);
  writer.writeDouble(offsets[14], object.unitPrice);
  writer.writeString(offsets[15], object.vehicleNo);
  writer.writeString(offsets[16], object.vocNo);
}

OfflineTransaction _offlineTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OfflineTransaction();
  object.actionType = _OfflineTransactionactionTypeValueEnumMap[
          reader.readStringOrNull(offsets[0])] ??
      OfflineActionType.earn;
  object.amountMmk = reader.readDoubleOrNull(offsets[1]);
  object.createdAt = reader.readDateTimeOrNull(offsets[2]);
  object.dynamicTokenId = reader.readStringOrNull(offsets[3]);
  object.fuelType = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[5]);
  object.paymentType = reader.readStringOrNull(offsets[6]);
  object.requiredPoints = reader.readLongOrNull(offsets[7]);
  object.rewardId = reader.readLongOrNull(offsets[8]);
  object.saleLiter = reader.readDoubleOrNull(offsets[9]);
  object.saleType = reader.readStringOrNull(offsets[10]);
  object.stationId = reader.readStringOrNull(offsets[11]);
  object.syncError = reader.readStringOrNull(offsets[12]);
  object.targetUid = reader.readStringOrNull(offsets[13]);
  object.unitPrice = reader.readDoubleOrNull(offsets[14]);
  object.vehicleNo = reader.readStringOrNull(offsets[15]);
  object.vocNo = reader.readStringOrNull(offsets[16]);
  return object;
}

P _offlineTransactionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_OfflineTransactionactionTypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          OfflineActionType.earn) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _OfflineTransactionactionTypeEnumValueMap = {
  r'earn': r'earn',
  r'redeem': r'redeem',
};
const _OfflineTransactionactionTypeValueEnumMap = {
  r'earn': OfflineActionType.earn,
  r'redeem': OfflineActionType.redeem,
};

Id _offlineTransactionGetId(OfflineTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _offlineTransactionGetLinks(
    OfflineTransaction object) {
  return [];
}

void _offlineTransactionAttach(
    IsarCollection<dynamic> col, Id id, OfflineTransaction object) {
  object.id = id;
}

extension OfflineTransactionQueryWhereSort
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QWhere> {
  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhere>
      anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhere>
      anyIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isSynced'),
      );
    });
  }
}

extension OfflineTransactionQueryWhere
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QWhereClause> {
  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      actionTypeEqualTo(OfflineActionType actionType) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'actionType',
        value: [actionType],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      actionTypeNotEqualTo(OfflineActionType actionType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'actionType',
              lower: [],
              upper: [actionType],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'actionType',
              lower: [actionType],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'actionType',
              lower: [actionType],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'actionType',
              lower: [],
              upper: [actionType],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      vocNoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'vocNo',
        value: [null],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      vocNoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'vocNo',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      vocNoEqualTo(String? vocNo) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'vocNo',
        value: [vocNo],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      vocNoNotEqualTo(String? vocNo) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'vocNo',
              lower: [],
              upper: [vocNo],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'vocNo',
              lower: [vocNo],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'vocNo',
              lower: [vocNo],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'vocNo',
              lower: [],
              upper: [vocNo],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      createdAtEqualTo(DateTime? createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      createdAtNotEqualTo(DateTime? createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      createdAtGreaterThan(
    DateTime? createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      createdAtLessThan(
    DateTime? createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      createdAtBetween(
    DateTime? lowerCreatedAt,
    DateTime? upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      isSyncedEqualTo(bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isSynced',
        value: [isSynced],
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterWhereClause>
      isSyncedNotEqualTo(bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [],
              upper: [isSynced],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [isSynced],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [isSynced],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [],
              upper: [isSynced],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OfflineTransactionQueryFilter
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QFilterCondition> {
  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeEqualTo(
    OfflineActionType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeGreaterThan(
    OfflineActionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeLessThan(
    OfflineActionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeBetween(
    OfflineActionType lower,
    OfflineActionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'actionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'actionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'actionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'actionType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      actionTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'actionType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      amountMmkIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amountMmk',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      amountMmkIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amountMmk',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      amountMmkEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountMmk',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      amountMmkGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountMmk',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      amountMmkLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountMmk',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      amountMmkBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountMmk',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dynamicTokenId',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dynamicTokenId',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dynamicTokenId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dynamicTokenId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dynamicTokenId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dynamicTokenId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dynamicTokenId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dynamicTokenId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dynamicTokenId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dynamicTokenId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dynamicTokenId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      dynamicTokenIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dynamicTokenId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fuelType',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fuelType',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fuelType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fuelType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fuelType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fuelType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      fuelTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fuelType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentType',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentType',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      paymentTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      requiredPointsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'requiredPoints',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      requiredPointsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'requiredPoints',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      requiredPointsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'requiredPoints',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      requiredPointsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'requiredPoints',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      requiredPointsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'requiredPoints',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      requiredPointsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'requiredPoints',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      rewardIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rewardId',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      rewardIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rewardId',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      rewardIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      rewardIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      rewardIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      rewardIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleLiterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'saleLiter',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleLiterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'saleLiter',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleLiterEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'saleLiter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleLiterGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'saleLiter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleLiterLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'saleLiter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleLiterBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'saleLiter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'saleType',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'saleType',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'saleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'saleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'saleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'saleType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'saleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'saleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'saleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'saleType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'saleType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      saleTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'saleType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stationId',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stationId',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stationId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      stationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stationId',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'syncError',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'syncError',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncError',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      syncErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncError',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetUid',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetUid',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetUid',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      targetUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetUid',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      unitPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'unitPrice',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      unitPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'unitPrice',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      unitPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      unitPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      unitPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      unitPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unitPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vehicleNo',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vehicleNo',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vehicleNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vehicleNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vehicleNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vehicleNo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'vehicleNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'vehicleNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'vehicleNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'vehicleNo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vehicleNo',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vehicleNoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'vehicleNo',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vocNo',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vocNo',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vocNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vocNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vocNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vocNo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'vocNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'vocNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'vocNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'vocNo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vocNo',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterFilterCondition>
      vocNoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'vocNo',
        value: '',
      ));
    });
  }
}

extension OfflineTransactionQueryObject
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QFilterCondition> {}

extension OfflineTransactionQueryLinks
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QFilterCondition> {}

extension OfflineTransactionQuerySortBy
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QSortBy> {
  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByActionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionType', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByActionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionType', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByAmountMmk() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountMmk', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByAmountMmkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountMmk', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByDynamicTokenId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dynamicTokenId', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByDynamicTokenIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dynamicTokenId', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByFuelType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuelType', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByFuelTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuelType', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByPaymentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentType', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByPaymentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentType', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByRequiredPoints() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requiredPoints', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByRequiredPointsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requiredPoints', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByRewardId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardId', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByRewardIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardId', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortBySaleLiter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleLiter', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortBySaleLiterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleLiter', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortBySaleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleType', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortBySaleTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleType', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByStationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stationId', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByStationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stationId', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortBySyncError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncError', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortBySyncErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncError', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByTargetUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetUid', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByTargetUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetUid', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByUnitPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByVehicleNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vehicleNo', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByVehicleNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vehicleNo', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByVocNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vocNo', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      sortByVocNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vocNo', Sort.desc);
    });
  }
}

extension OfflineTransactionQuerySortThenBy
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QSortThenBy> {
  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByActionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionType', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByActionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionType', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByAmountMmk() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountMmk', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByAmountMmkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountMmk', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByDynamicTokenId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dynamicTokenId', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByDynamicTokenIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dynamicTokenId', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByFuelType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuelType', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByFuelTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuelType', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByPaymentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentType', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByPaymentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentType', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByRequiredPoints() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requiredPoints', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByRequiredPointsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requiredPoints', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByRewardId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardId', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByRewardIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardId', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenBySaleLiter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleLiter', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenBySaleLiterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleLiter', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenBySaleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleType', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenBySaleTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'saleType', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByStationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stationId', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByStationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stationId', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenBySyncError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncError', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenBySyncErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncError', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByTargetUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetUid', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByTargetUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetUid', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByUnitPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByVehicleNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vehicleNo', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByVehicleNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vehicleNo', Sort.desc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByVocNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vocNo', Sort.asc);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QAfterSortBy>
      thenByVocNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vocNo', Sort.desc);
    });
  }
}

extension OfflineTransactionQueryWhereDistinct
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct> {
  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByActionType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByAmountMmk() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountMmk');
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByDynamicTokenId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dynamicTokenId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByFuelType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fuelType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByPaymentType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByRequiredPoints() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'requiredPoints');
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByRewardId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardId');
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctBySaleLiter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'saleLiter');
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctBySaleType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'saleType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByStationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stationId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctBySyncError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByTargetUid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitPrice');
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByVehicleNo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vehicleNo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTransaction, OfflineTransaction, QDistinct>
      distinctByVocNo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vocNo', caseSensitive: caseSensitive);
    });
  }
}

extension OfflineTransactionQueryProperty
    on QueryBuilder<OfflineTransaction, OfflineTransaction, QQueryProperty> {
  QueryBuilder<OfflineTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OfflineTransaction, OfflineActionType, QQueryOperations>
      actionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionType');
    });
  }

  QueryBuilder<OfflineTransaction, double?, QQueryOperations>
      amountMmkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountMmk');
    });
  }

  QueryBuilder<OfflineTransaction, DateTime?, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations>
      dynamicTokenIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dynamicTokenId');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations>
      fuelTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fuelType');
    });
  }

  QueryBuilder<OfflineTransaction, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations>
      paymentTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentType');
    });
  }

  QueryBuilder<OfflineTransaction, int?, QQueryOperations>
      requiredPointsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requiredPoints');
    });
  }

  QueryBuilder<OfflineTransaction, int?, QQueryOperations> rewardIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardId');
    });
  }

  QueryBuilder<OfflineTransaction, double?, QQueryOperations>
      saleLiterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'saleLiter');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations>
      saleTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'saleType');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations>
      stationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stationId');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations>
      syncErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncError');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations>
      targetUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetUid');
    });
  }

  QueryBuilder<OfflineTransaction, double?, QQueryOperations>
      unitPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitPrice');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations>
      vehicleNoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vehicleNo');
    });
  }

  QueryBuilder<OfflineTransaction, String?, QQueryOperations> vocNoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vocNo');
    });
  }
}
