// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'individual_album_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndividualAlbumResponse _$IndividualAlbumResponseFromJson(
  Map<String, dynamic> json,
) => IndividualAlbumResponse(
  myAlbums: (json['my_albums'] as List<dynamic>)
      .map((e) => IndividualAlbumModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  publicAlbums: (json['public_albums'] as List<dynamic>)
      .map((e) => IndividualAlbumModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  purchasedAlbums: (json['purchased_albums'] as List<dynamic>)
      .map((e) => IndividualAlbumModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$IndividualAlbumResponseToJson(
  IndividualAlbumResponse instance,
) => <String, dynamic>{
  'my_albums': instance.myAlbums,
  'public_albums': instance.publicAlbums,
  'purchased_albums': instance.purchasedAlbums,
};
