class PresenceModel {
  final int userId;
  final String? username;           // nullable — not returned by API
  final bool isOnline;
  final int? lastActivityUnix;      // nullable — not returned by API
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
      username: json['username'],           // null-safe now
      isOnline: json['online'] ?? false,    // ← was 'is_online', API sends 'online'
      lastActivityUnix: json['last_activity_unix'],  // null-safe now
      lastSeenAt: json['last_seen_at'],
    );
  }
}