class PresenceModel {
  final int userId;
  final String? username;
  final bool isOnline;
  final int? lastActivityUnix;
  final String lastSeenAt;

  PresenceModel({
    required this.userId,
    this.username,
    required this.isOnline,
    this.lastActivityUnix,
    required this.lastSeenAt,
  });

  factory PresenceModel.fromJson(Map<String, dynamic> json) {
    return PresenceModel(
      userId: json['user_id'],
      username: json['username'],
      isOnline: json['online'] ?? false,
      lastActivityUnix: json['last_activity_unix'],
      lastSeenAt: json['last_seen_at'],
    );
  }
}