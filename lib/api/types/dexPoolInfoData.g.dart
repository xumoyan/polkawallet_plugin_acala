// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dexPoolInfoData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DexPoolData _$DexPoolDataFromJson(Map<String, dynamic> json) {
  return DexPoolData()
    ..decimals = json['decimals'] as int
    ..tokens = json['tokens'] as List;
}

Map<String, dynamic> _$DexPoolDataToJson(DexPoolData instance) =>
    <String, dynamic>{
      'decimals': instance.decimals,
      'tokens': instance.tokens,
    };
