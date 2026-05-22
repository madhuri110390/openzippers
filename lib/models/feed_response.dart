// lib/models/feed_response.dart

import 'package:json_annotation/json_annotation.dart';

part 'feed_response.g.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum PostType {
  @JsonValue('post') post,
  @JsonValue('audio') audio,
  @JsonValue('video') video,
  @JsonValue('literature') literature,
}

// ─── Author ───────────────────────────────────────────────────────────────────

@JsonSerializable()
class PostAuthor {
  final int id;
  final String name;
  final String? avatar;
  final bool verified;

  const PostAuthor({
    required this.id,
    required this.name,
    this.avatar,
    required this.verified,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) =>
      _$PostAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$PostAuthorToJson(this);
}

// ─── Post ─────────────────────────────────────────────────────────────────────

@JsonSerializable()
class PostModel {
  final int id;
  final PostAuthor user;
  final String time;
  final String title;
  final String? text;
  final String? image;

  @JsonKey(name: 'audio_url')
  final String? audioUrl;

  @JsonKey(name: 'video_url')
  final String? videoUrl;

  @JsonKey(name: 'literature_url')
  final String? literatureUrl;

  @JsonKey(name: 'preview_url')
  final String? previewUrl;

  final String? duration;

  @JsonKey(name: 'likesCount')
  final int likesCount;

  @JsonKey(name: 'commentsCount')
  final int commentsCount;

  final List<dynamic> comments;

  @JsonKey(name: 'is_liked')
  final bool isLiked;

  @JsonKey(name: 'is_bookmarked')
  final bool isBookmarked;

  @JsonKey(name: 'is_premium')
  final bool isPremium;

  @JsonKey(name: 'post_type', unknownEnumValue: PostType.post)
  final PostType postType;

  final String price;

  @JsonKey(name: 'in_cart')
  final bool inCart;

  @JsonKey(name: 'is_purchased')
  final bool isPurchased;

  @JsonKey(name: 'vat_percent')
  final int vatPercent;

  @JsonKey(name: 'average_rating', fromJson: _doubleFromJson)
  final double averageRating;

  @JsonKey(name: 'total_ratings')
  final int totalRatings;

  @JsonKey(name: 'user_rating')
  final dynamic userRating;

  final String? metadata;

  @JsonKey(
    name: 'created_at',
    fromJson: _dateFromJson,
    toJson: _dateToJson,
  )
  final DateTime createdAt;

  final int views;

  @JsonKey(name: 'fans_status')
  final String fansStatus;

  const PostModel({
    required this.id,
    required this.user,
    required this.time,
    required this.title,
    this.text,
    this.image,
    this.audioUrl,
    this.videoUrl,
    this.literatureUrl,
    this.previewUrl,
    this.duration,
    required this.likesCount,
    required this.commentsCount,
    required this.comments,
    required this.isLiked,
    required this.isBookmarked,
    required this.isPremium,
    required this.postType,
    required this.price,
    required this.inCart,
    required this.isPurchased,
    required this.vatPercent,
    required this.averageRating,
    required this.totalRatings,
    this.userRating,
    this.metadata,
    required this.createdAt,
    required this.views,
    required this.fansStatus,
  });

  // ─── Custom Converters ──────────────────────────────────────────────────────

  static double _doubleFromJson(dynamic value) {
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }

  static DateTime _dateFromJson(String date) {
    return DateTime.parse(date);
  }

  static String _dateToJson(DateTime date) {
    return date.toIso8601String();
  }

  // ─── Convenience Getters ────────────────────────────────────────────────────

  bool get isFree => (double.tryParse(price) ?? 0) == 0;

  bool get isAccessible => !isPremium || isPurchased;

  bool get hasMedia =>
      audioUrl != null || videoUrl != null || literatureUrl != null;

  double get totalPrice {
    final base = double.tryParse(price) ?? 0.0;
    return base + (base * vatPercent / 100);
  }

  // ─── CopyWith ───────────────────────────────────────────────────────────────

  PostModel copyWith({
    bool? isLiked,
    bool? isBookmarked,
    int? likesCount,
  }) {
    return PostModel(
      id: id,
      user: user,
      time: time,
      title: title,
      text: text,
      image: image,
      audioUrl: audioUrl,
      videoUrl: videoUrl,
      literatureUrl: literatureUrl,
      previewUrl: previewUrl,
      duration: duration,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      comments: comments,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isPremium: isPremium,
      postType: postType,
      price: price,
      inCart: inCart,
      isPurchased: isPurchased,
      vatPercent: vatPercent,
      averageRating: averageRating,
      totalRatings: totalRatings,
      userRating: userRating,
      metadata: metadata,
      createdAt: createdAt,
      views: views,
      fansStatus: fansStatus,
    );
  }

  // ─── JSON ───────────────────────────────────────────────────────────────────

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);
}

// ─── Pagination ───────────────────────────────────────────────────────────────

@JsonSerializable()
class PaginationMeta {
  @JsonKey(name: 'current_page')
  final int currentPage;

  @JsonKey(name: 'last_page')
  final int lastPage;

  @JsonKey(name: 'per_page')
  final int perPage;

  final int total;
  final int from;
  final int to;

  @JsonKey(name: 'next_page_url')
  final String? nextPageUrl;

  @JsonKey(name: 'prev_page_url')
  final String? prevPageUrl;

  bool get hasMore => nextPageUrl != null;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaToJson(this);
}

// ─── Feed Response ────────────────────────────────────────────────────────────

@JsonSerializable()
class FeedResponse {
  final bool success;
  final String tab;

  @JsonKey(name: 'followed_user_ids')
  final List<int> followedUserIds;

  final List<PostModel> data;
  final PaginationMeta pagination;

  const FeedResponse({
    required this.success,
    required this.tab,
    required this.followedUserIds,
    required this.data,
    required this.pagination,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FeedResponseToJson(this);
}