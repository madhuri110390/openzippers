import 'package:json_annotation/json_annotation.dart';

part 'location_models.g.dart';

@JsonSerializable()
class Country {
  final int id;
  final String name;

  Country({required this.id, required this.name});

  factory Country.fromJson(Map<String, dynamic> json) => _$CountryFromJson(json);
  Map<String, dynamic> toJson() => _$CountryToJson(this);
}

@JsonSerializable()
class StateModel {
  final int id;
  final String name;
  @JsonKey(name: 'state_code')
  final String? stateCode;

  StateModel({required this.id, required this.name, this.stateCode});

  factory StateModel.fromJson(Map<String, dynamic> json) => _$StateModelFromJson(json);
  Map<String, dynamic> toJson() => _$StateModelToJson(this);
}

@JsonSerializable()
class CityModel {
  final int id;
  final String name;

  CityModel({required this.id, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) => _$CityModelFromJson(json);
  Map<String, dynamic> toJson() => _$CityModelToJson(this);
}
