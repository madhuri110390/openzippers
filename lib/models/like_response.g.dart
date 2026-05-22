// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'like_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LikeResponse _$LikeResponseFromJson(Map<String, dynamic> json) => LikeResponse(
  success: json['success'] as bool,
  data: LikeData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LikeResponseToJson(LikeResponse instance) =>
    <String, dynamic>{'success': instance.success, 'data': instance.data};

LikeData _$LikeDataFromJson(Map<String, dynamic> json) => LikeData(
  postId: (json['post_id'] as num).toInt(),
  isLiked: json['is_liked'] as bool,
  likesCount: (json['likes_count'] as num).toInt(),
);

Map<String, dynamic> _$LikeDataToJson(LikeData instance) => <String, dynamic>{
  'post_id': instance.postId,
  'is_liked': instance.isLiked,
  'likes_count': instance.likesCount,
};
