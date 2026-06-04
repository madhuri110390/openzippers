import 'package:json_annotation/json_annotation.dart';
part 'individual_album_model.g.dart';

@JsonSerializable()
class IndividualAlbumModel {
  final int id;
  final String title;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  final String price;
  final String? image;
  @JsonKey(name: 'is_owner')
  final bool isOwner;
  @JsonKey(name: 'is_purchased')
  final bool isPurchased;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final List<AlbumItem> items;
  final AlbumUser? user;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const IndividualAlbumModel({
    required this.id,
    required this.title,
    required this.userId,
    required this.isPublic,
    required this.price,
    this.image,
    required this.isOwner,
    required this.isPurchased,
    this.imageUrl,
    required this.items,
    this.user,
    required this.createdAt,
  });

  factory IndividualAlbumModel.fromJson(Map<String, dynamic> json) =>
      _$IndividualAlbumModelFromJson(json);

  Map<String, dynamic> toJson() => _$IndividualAlbumModelToJson(this);
}

@JsonSerializable()
class AlbumItem {
  final int id;
  @JsonKey(name: 'album_id')
  final int albumId;
  @JsonKey(name: 'trackable_type')
  final String trackableType;
  @JsonKey(name: 'trackable_id')
  final int trackableId;
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  const AlbumItem({
    required this.id,
    required this.albumId,
    required this.trackableType,
    required this.trackableId,
    required this.sortOrder,
  });

  factory AlbumItem.fromJson(Map<String, dynamic> json) =>
      _$AlbumItemFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumItemToJson(this);
}

@JsonSerializable()
class AlbumUser {
  final int id;
  final String name;
  final String username;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  const AlbumUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  factory AlbumUser.fromJson(Map<String, dynamic> json) =>
      _$AlbumUserFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumUserToJson(this);
}