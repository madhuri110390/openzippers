class FollowResponse {
  final bool success;
  final FollowData data;

  FollowResponse({
    required this.success,
    required this.data,
  });

  factory FollowResponse.fromJson(Map<String, dynamic> json) {
    // API might wrap data under 'data' key or return flat
    final rawData = json['data'];

    return FollowResponse(
      success: json['success'] == true || json['status'] == true,
      data: rawData != null
          ? FollowData.fromJson(rawData as Map<String, dynamic>)
          : FollowData.fromJson(json), // fallback: parse flat response
    );
  }
}

class FollowData {
  final int userId;
  final String username;
  bool isFollowing;

  FollowData({
    required this.userId,
    required this.username,
    required this.isFollowing,
  });

  factory FollowData.fromJson(Map<String, dynamic> json) {
    return FollowData(
      userId: (json['user_id'] ?? json['id'] ?? 0) as int,
      username: (json['username'] ?? '').toString(),
      // API may return int 1/0 or bool true/false
      isFollowing: _parseBool(json['is_following'] ?? json['following']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value == 'true';
    return false;
  }
}