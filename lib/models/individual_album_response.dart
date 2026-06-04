// features/albums/data/models/albums_response.dart
// features/albums/data/models/individual_album_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'individual_album_model.dart';
part 'individual_album_response.g.dart';

@JsonSerializable()
class IndividualAlbumResponse {
  @JsonKey(name: 'my_albums')
  final List<IndividualAlbumModel> myAlbums;
  @JsonKey(name: 'public_albums')
  final List<IndividualAlbumModel> publicAlbums;
  @JsonKey(name: 'purchased_albums')
  final List<IndividualAlbumModel> purchasedAlbums;

  const IndividualAlbumResponse({
    required this.myAlbums,
    required this.publicAlbums,
    required this.purchasedAlbums,
  });

  factory IndividualAlbumResponse.fromJson(Map<String, dynamic> json) =>
      _$IndividualAlbumResponseFromJson(json);

  Map<String, dynamic> toJson() => _$IndividualAlbumResponseToJson(this);
}