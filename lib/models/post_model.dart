// lib/features/feed/data/models/post_model.dart

// ─── Enums ───────────────────────────────────────────────────────────────────

enum PostType {
  post,
  audio,
  video,
  literature,
}

// Helper to parse PostType from JSON string
extension PostTypeExtension on PostType {
  String toJson() {
    switch (this) {
      case PostType.post:
        return 'post';
      case PostType.audio:
        return 'audio';
      case PostType.video:
        return 'video';
      case PostType.literature:
        return 'literature';
    }
  }

  static PostType fromJson(String value) {
    switch (value) {
      case 'post':
        return PostType.post;
      case 'audio':
        return PostType.audio;
      case 'video':
        return PostType.video;
      case 'literature':
        return PostType.literature;
      default:
        return PostType.post;
    }
  }
}

// ─── Author ──────────────────────────────────────────────────────────────────

class PostAuthor {
  final int id;
  final String name;
  final String? avatar;
  final bool verified;

  PostAuthor({
    required this.id,
    required this.name,
    this.avatar,
    this.verified = false,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'verified': verified,
    };
  }
}

// ─── Post Model ──────────────────────────────────────────────────────────────

class PostModel {
  final int id;
  final PostAuthor user;
  final String time;
  final String title;
  final String? text;
  final String? image;
  final String? audioUrl;
  final String? videoUrl;
  final String? literatureUrl;
  final String? previewUrl;
  final String? duration;
  final int likesCount;
  final int commentsCount;
  final List<dynamic> comments;
  final bool isLiked;
  final bool isBookmarked;
  final bool isPremium;
  final PostType postType;
  final String price;
  final bool inCart;
  final bool isPurchased;
  final int vatPercent;
  final double averageRating;
  final int totalRatings;
  final dynamic userRating;
  final String? metadata;
  final DateTime createdAt;
  final int views;
  final String fansStatus;

  // Computed properties
  bool get isFree => (double.tryParse(price) ?? 0) == 0;
  bool get isAccessible => !isPremium || isPurchased;
  double get totalPrice {
    final base = double.tryParse(price) ?? 0.0;
    return base + (base * vatPercent / 100);
  }
  bool get hasMedia => audioUrl != null || videoUrl != null || literatureUrl != null;

  PostModel({
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
    this.likesCount = 0,
    this.commentsCount = 0,
    this.comments = const [],
    this.isLiked = false,
    this.isBookmarked = false,
    this.isPremium = false,
    required this.postType,
    this.price = '0.00',
    this.inCart = false,
    this.isPurchased = false,
    this.vatPercent = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.userRating,
    this.metadata,
    required this.createdAt,
    this.views = 0,
    this.fansStatus = '1',
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
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
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      comments: json['comments'] as List<dynamic>? ?? [],
      isLiked: json['is_liked'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      postType: PostTypeExtension.fromJson(json['post_type'] as String? ?? 'post'),
      price: json['price'] as String? ?? '0.00',
      inCart: json['in_cart'] as bool? ?? false,
      isPurchased: json['is_purchased'] as bool? ?? false,
      vatPercent: json['vat_percent'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      userRating: json['user_rating'],
      metadata: json['metadata'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      views: json['views'] as int? ?? 0,
      fansStatus: json['fans_status'] as String? ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'time': time,
      'title': title,
      'text': text,
      'image': image,
      'audio_url': audioUrl,
      'video_url': videoUrl,
      'literature_url': literatureUrl,
      'preview_url': previewUrl,
      'duration': duration,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'comments': comments,
      'is_liked': isLiked,
      'is_bookmarked': isBookmarked,
      'is_premium': isPremium,
      'post_type': postType.toJson(),
      'price': price,
      'in_cart': inCart,
      'is_purchased': isPurchased,
      'vat_percent': vatPercent,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'user_rating': userRating,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'views': views,
      'fans_status': fansStatus,
    };
  }
}

// ─── Pagination Meta ─────────────────────────────────────────────────────────

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;
  final String? nextPageUrl;
  final String? prevPageUrl;

  bool get hasMore => nextPageUrl != null;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
      from: json['from'] as int,
      to: json['to'] as int,
      nextPageUrl: json['next_page_url'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'from': from,
      'to': to,
      'next_page_url': nextPageUrl,
      'prev_page_url': prevPageUrl,
    };
  }
}

// ─── Feed Response ───────────────────────────────────────────────────────────

class FeedResponse {
  final bool success;
  final String tab;
  final List<int> followedUserIds;
  final List<PostModel> data;
  final PaginationMeta pagination;

  FeedResponse({
    required this.success,
    required this.tab,
    required this.followedUserIds,
    required this.data,
    required this.pagination,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      success: json['success'] as bool,
      tab: json['tab'] as String,
      followedUserIds: (json['followed_user_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      data: (json['data'] as List<dynamic>)
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'tab': tab,
      'followed_user_ids': followedUserIds,
      'data': data.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}