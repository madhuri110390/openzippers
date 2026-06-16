// models/subscription_list_response.dart

class SubscriptionListResponse {
  final bool success;
  final String message;
  final SubscriptionListData data;

  SubscriptionListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SubscriptionListResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionListResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: SubscriptionListData.fromJson(
        json['subscriptions'] ?? json['data'] ?? json,
      ),
    );
  }
}

class SubscriptionListData {
  final List<SubscriptionItem> asSubscriber; // I subscribed to artists
  final List<SubscriptionItem> asArtist;    // fans who subscribed to me
  final double totalEarnings;

  SubscriptionListData({
    required this.asSubscriber,
    required this.asArtist,
    required this.totalEarnings,
  });

  factory SubscriptionListData.fromJson(Map<String, dynamic> json) {
    final sub = json['asSubscriber'] as List? ?? [];
    final art = json['asArtist'] as List? ?? [];
    return SubscriptionListData(
      asSubscriber: sub
          .map((e) => SubscriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      asArtist: art
          .map((e) => SubscriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalEarnings:
      double.tryParse(json['totalEarnings']?.toString() ?? '0') ?? 0,
    );
  }

  // active = status == 'active'
  List<SubscriptionItem> get activeAsArtist =>
      asArtist.where((s) => s.status.toLowerCase() == 'active').toList();

  List<SubscriptionItem> get activeAsSubscriber =>
      asSubscriber.where((s) => s.status.toLowerCase() == 'active').toList();

  int get activeSubscribersCount => activeAsArtist.length;
  int get myActiveSubscriptionsCount => activeAsSubscriber.length;
}

class SubscriptionItem {
  final int id;
  final int subscriberId;
  final int artistId;
  final String type;
  final String provider;
  final String providerSubscriptionId;
  final String status;
  final String? expiresAt;
  final String? canceledAt;
  final String amount;
  final String createdAt;
  final String updatedAt;
  final SubscriptionUser? subscriber; // populated in asArtist list
  final SubscriptionUser? artist;     // populated in asSubscriber list (if API returns it)

  SubscriptionItem({
    required this.id,
    required this.subscriberId,
    required this.artistId,
    required this.type,
    required this.provider,
    required this.providerSubscriptionId,
    required this.status,
    this.expiresAt,
    this.canceledAt,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.subscriber,
    this.artist,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      id: json['id'] ?? 0,
      subscriberId: json['subscriber_id'] ?? 0,
      artistId: json['artist_id'] ?? 0,
      type: json['type'] ?? '',
      provider: json['provider'] ?? '',
      providerSubscriptionId: json['provider_subscription_id'] ?? '',
      status: json['status'] ?? '',
      expiresAt: json['expires_at'],
      canceledAt: json['canceled_at'],
      amount: json['amount']?.toString() ?? '0',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      subscriber: json['subscriber'] != null
          ? SubscriptionUser.fromJson(json['subscriber'])
          : null,
      artist: json['artist'] != null
          ? SubscriptionUser.fromJson(json['artist'])
          : null,
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  /// formatted expiry date e.g. "2025-12-26"
  String get expiresAtFormatted =>
      expiresAt?.split('T').first ?? '';

  String get createdAtFormatted =>
      createdAt.split('T').first;
}

class SubscriptionUser {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final String? coverImageUrl;
  final int postsCount;

  SubscriptionUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.coverImageUrl,
    required this.postsCount,
  });

  factory SubscriptionUser.fromJson(Map<String, dynamic> json) {
    return SubscriptionUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      coverImageUrl: json['cover_image_url'],
      postsCount: json['posts_count'] ?? 0,
    );
  }
}