import 'package:json_annotation/json_annotation.dart';
part 'like_response.g.dart';

@JsonSerializable()
class LikeResponse {
  final bool success;
  final LikeData data;
  LikeResponse({required this.success, required this.data});
  factory LikeResponse.fromJson(Map<String, dynamic> json) => _$LikeResponseFromJson(json);
}

@JsonSerializable()
class LikeData {
  @JsonKey(name: 'post_id')    final int postId;
  @JsonKey(name: 'is_liked')   final bool isLiked;
  @JsonKey(name: 'likes_count') final int likesCount;
  LikeData({required this.postId, required this.isLiked, required this.likesCount});
  factory LikeData.fromJson(Map<String, dynamic> json) => _$LikeDataFromJson(json);
}