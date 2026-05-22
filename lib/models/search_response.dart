class SearchResponse {
  final bool success;
  final String query;
  final List<SearchUser> users;

  SearchResponse({
    required this.success,
    required this.query,
    required this.users,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      success: json['success'] ?? false,
      query: json['query'] ?? '',
      users: (json['users'] as List<dynamic>? ?? [])
          .map((e) => SearchUser.fromJson(e))
          .toList(),
    );
  }
}

class SearchUser {
  final int id;
  final String name;
  final String username;
  final String avatar;
  final String artistVerifyStatus;
  final String type;
  final int postsCount;

  SearchUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.artistVerifyStatus,
    required this.type,
    required this.postsCount,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      artistVerifyStatus: json['artist_verify_status'] ?? '',
      type: json['type'] ?? '',
      postsCount: json['posts_count'] ?? 0,
    );
  }
}