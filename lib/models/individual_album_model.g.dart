// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'individual_album_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndividualAlbumModel _$IndividualAlbumModelFromJson(
  Map<String, dynamic> json,
) => IndividualAlbumModel(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  userId: (json['user_id'] as num).toInt(),
  isPublic: json['is_public'] as bool,
  price: json['price'] as String,
  image: json['image'] as String?,
  isOwner: json['is_owner'] as bool,
  isPurchased: json['is_purchased'] as bool,
  imageUrl: json['image_url'] as String?,
  items: (json['items'] as List<dynamic>)
      .map((e) => AlbumItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  user: json['user'] == null
      ? null
      : AlbumUser.fromJson(json['user'] as Map<String, dynamic>),
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$IndividualAlbumModelToJson(
  IndividualAlbumModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'user_id': instance.userId,
  'is_public': instance.isPublic,
  'price': instance.price,
  'image': instance.image,
  'is_owner': instance.isOwner,
  'is_purchased': instance.isPurchased,
  'image_url': instance.imageUrl,
  'items': instance.items,
  'user': instance.user,
  'created_at': instance.createdAt,
};

AlbumItem _$AlbumItemFromJson(Map<String, dynamic> json) => AlbumItem(
  id: (json['id'] as num).toInt(),
  albumId: (json['album_id'] as num).toInt(),
  trackableType: json['trackable_type'] as String,
  trackableId: (json['trackable_id'] as num).toInt(),
  sortOrder: (json['sort_order'] as num).toInt(),
);

Map<String, dynamic> _$AlbumItemToJson(AlbumItem instance) => <String, dynamic>{
  'id': instance.id,
  'album_id': instance.albumId,
  'trackable_type': instance.trackableType,
  'trackable_id': instance.trackableId,
  'sort_order': instance.sortOrder,
};

AlbumUser _$AlbumUserFromJson(Map<String, dynamic> json) => AlbumUser(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  username: json['username'] as String,
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$AlbumUserToJson(AlbumUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'username': instance.username,
  'avatar_url': instance.avatarUrl,
};
