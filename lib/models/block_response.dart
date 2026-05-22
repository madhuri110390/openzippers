class BlockResponse {
  final bool success;
  final BlockData data;
  final String message;

  BlockResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory BlockResponse.fromJson(Map<String, dynamic> json) {
    return BlockResponse(
      success: json['success'] ?? false,
      data: BlockData.fromJson(json['data']),
      message: json['message'] ?? '',
    );
  }
}

class BlockData {
  final int userId;
  final String username;
  final bool isBlocked;

  BlockData({
    required this.userId,
    required this.username,
    required this.isBlocked,
  });

  factory BlockData.fromJson(Map<String, dynamic> json) {
    return BlockData(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      isBlocked: json['is_blocked'] ?? false,
    );
  }
}