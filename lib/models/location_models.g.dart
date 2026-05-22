// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Country _$CountryFromJson(Map<String, dynamic> json) =>
    Country(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$CountryToJson(Country instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

StateModel _$StateModelFromJson(Map<String, dynamic> json) => StateModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  stateCode: json['state_code'] as String?,
);

Map<String, dynamic> _$StateModelToJson(StateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'state_code': instance.stateCode,
    };

CityModel _$CityModelFromJson(Map<String, dynamic> json) =>
    CityModel(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$CityModelToJson(CityModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};
