class FollowResponse {

  final bool success;
  final FollowData data;

  FollowResponse({
    required this.success,
    required this.data,
  });

  factory FollowResponse.fromJson(
      Map<String, dynamic> json) {

    return FollowResponse(

      success: json['success'] ?? false,

      data: FollowData.fromJson(
        json['data'],
      ),
    );
  }
}

class FollowData {

  final int userId;

  final String username;

  final bool isFollowing;

  FollowData({
    required this.userId,
    required this.username,
    required this.isFollowing,
  });

  factory FollowData.fromJson(
      Map<String, dynamic> json) {

    return FollowData(

      userId: json['user_id'] ?? 0,

      username: json['username'] ?? '',

      isFollowing:
      json['is_following'] ?? false,
    );
  }
}