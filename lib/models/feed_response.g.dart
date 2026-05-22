// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAuthor _$PostAuthorFromJson(Map<String, dynamic> json) => PostAuthor(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  avatar: json['avatar'] as String?,
  verified: json['verified'] as bool,
);

Map<String, dynamic> _$PostAuthorToJson(PostAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'verified': instance.verified,
    };

PostModel _$PostModelFromJson(Map<String, dynamic> json) => PostModel(
  id: (json['id'] as num).toInt(),
  user: PostAuthor.fromJson(json['user'] as Map<String, dynamic>),
  time: json['time'] as String,
  title: json['title'] as String,
  text: json['text'] as String?,
  image: json['image'] as String?,
  audioUrl: json['audio_url'] as String?,
  videoUrl: json['video_url'] as String?,
  literatureUrl: json['literature_url'] as String?,
  previewUrl: json['preview_url'] as String?,
  duration: json['duration'] as String?,
  likesCount: (json['likesCount'] as num).toInt(),
  commentsCount: (json['commentsCount'] as num).toInt(),
  comments: json['comments'] as List<dynamic>,
  isLiked: json['is_liked'] as bool,
  isBookmarked: json['is_bookmarked'] as bool,
  isPremium: json['is_premium'] as bool,
  postType: $enumDecode(
    _$PostTypeEnumMap,
    json['post_type'],
    unknownValue: PostType.post,
  ),
  price: json['price'] as String,
  inCart: json['in_cart'] as bool,
  isPurchased: json['is_purchased'] as bool,
  vatPercent: (json['vat_percent'] as num).toInt(),
  averageRating: PostModel._doubleFromJson(json['average_rating']),
  totalRatings: (json['total_ratings'] as num).toInt(),
  userRating: json['user_rating'],
  metadata: json['metadata'] as String?,
  createdAt: PostModel._dateFromJson(json['created_at'] as String),
  views: (json['views'] as num).toInt(),
  fansStatus: json['fans_status'] as String,
);

Map<String, dynamic> _$PostModelToJson(PostModel instance) => <String, dynamic>{
  'id': instance.id,
  'user': instance.user,
  'time': instance.time,
  'title': instance.title,
  'text': instance.text,
  'image': instance.image,
  'audio_url': instance.audioUrl,
  'video_url': instance.videoUrl,
  'literature_url': instance.literatureUrl,
  'preview_url': instance.previewUrl,
  'duration': instance.duration,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'comments': instance.comments,
  'is_liked': instance.isLiked,
  'is_bookmarked': instance.isBookmarked,
  'is_premium': instance.isPremium,
  'post_type': _$PostTypeEnumMap[instance.postType]!,
  'price': instance.price,
  'in_cart': instance.inCart,
  'is_purchased': instance.isPurchased,
  'vat_percent': instance.vatPercent,
  'average_rating': instance.averageRating,
  'total_ratings': instance.totalRatings,
  'user_rating': instance.userRating,
  'metadata': instance.metadata,
  'created_at': PostModel._dateToJson(instance.createdAt),
  'views': instance.views,
  'fans_status': instance.fansStatus,
};

const _$PostTypeEnumMap = {
  PostType.post: 'post',
  PostType.audio: 'audio',
  PostType.video: 'video',
  PostType.literature: 'literature',
};

PaginationMeta _$PaginationMetaFromJson(Map<String, dynamic> json) =>
    PaginationMeta(
      currentPage: (json['current_page'] as num).toInt(),
      lastPage: (json['last_page'] as num).toInt(),
      perPage: (json['per_page'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      from: (json['from'] as num).toInt(),
      to: (json['to'] as num).toInt(),
      nextPageUrl: json['next_page_url'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
    );

Map<String, dynamic> _$PaginationMetaToJson(PaginationMeta instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'last_page': instance.lastPage,
      'per_page': instance.perPage,
      'total': instance.total,
      'from': instance.from,
      'to': instance.to,
      'next_page_url': instance.nextPageUrl,
      'prev_page_url': instance.prevPageUrl,
    };

FeedResponse _$FeedResponseFromJson(Map<String, dynamic> json) => FeedResponse(
  success: json['success'] as bool,
  tab: json['tab'] as String,
  followedUserIds: (json['followed_user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  data: (json['data'] as List<dynamic>)
      .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: PaginationMeta.fromJson(
    json['pagination'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$FeedResponseToJson(FeedResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'tab': instance.tab,
      'followed_user_ids': instance.followedUserIds,
      'data': instance.data,
      'pagination': instance.pagination,
    };
