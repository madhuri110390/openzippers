class ConnectionsResponse {
  final bool success;
  final ConnectionsData data;

  ConnectionsResponse({required this.success, required this.data});

  factory ConnectionsResponse.fromJson(Map<String, dynamic> json) {
    return ConnectionsResponse(
      success: json['success'] ?? false,
      data: ConnectionsData.fromJson(json['data']),
    );
  }
}

class ConnectionsData {
  final UserModel user;
  final List<FollowUser> followers;
  final List<FollowUser> following;
  final List<FollowUser> blocked;
  final Counts counts;

  ConnectionsData({
    required this.user,
    required this.followers,
    required this.following,
    required this.blocked,
    required this.counts,
  });

  factory ConnectionsData.fromJson(Map<String, dynamic> json) {
    return ConnectionsData(
      user: UserModel.fromJson(json['user']),
      followers: (json['followers'] as List? ?? [])
          .map((e) => FollowUser.fromJson(e))
          .toList(),
      following: (json['following'] as List? ?? [])
          .map((e) => FollowUser.fromJson(e))
          .toList(),
      blocked: (json['blocked'] as List? ?? [])
          .map((e) => FollowUser.fromJson(e))
          .toList(),
      counts: Counts.fromJson(json['counts'] ?? {}),
    );
  }
}

class UserModel {
  final int id;
  final String name;
  final String username;
  final int roleId;
  final String roleName;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.roleId,
    required this.roleName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      roleId: json['role_id'] ?? 0,
      roleName: json['role_name'] ?? '',
    );
  }
}

class FollowUser {
  final int id;
  final String name;
  final String username;
  final String avatarUrl;
  final String bio;
  bool isFollowing;
  bool? isBlocked;

  FollowUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.isFollowing,
    this.isBlocked,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    return FollowUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      bio: json['bio'] ?? '',
      isFollowing: json['is_following'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
    );
  }
}

class Counts {
  final int followers;
  final int following;
  final int blocked;

  Counts({
    required this.followers,
    required this.following,
    required this.blocked,
  });

  factory Counts.fromJson(Map<String, dynamic> json) {
    return Counts(
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      blocked: json['blocked'] ?? 0,
    );
  }
}