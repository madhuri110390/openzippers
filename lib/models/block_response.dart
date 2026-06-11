class BlockResponse {
  final bool success;
  final String message;
  final BlockData data;

  BlockResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BlockResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    return BlockResponse(
      success: json['success'] == true || json['status'] == true,
      message: (json['message'] ?? (json['data'] != null
          ? (_parseBool((json['data'] as Map)['is_blocked'] ??
          (json['data'] as Map)['blocked'])
          ? 'Blocked successfully'
          : 'Unblocked successfully')
          : 'Done')).toString(),
      data: rawData != null
          ? BlockData.fromJson(rawData as Map<String, dynamic>)
          : BlockData.fromJson(json),
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

class BlockData {
  final int userId;
  final String username;
  bool isBlocked;

  BlockData({
    required this.userId,
    required this.username,
    required this.isBlocked,
  });

  factory BlockData.fromJson(Map<String, dynamic> json) {
    return BlockData(
      userId: (json['user_id'] ?? json['id'] ?? 0) as int,
      username: (json['username'] ?? '').toString(),
      isBlocked: _parseBool(json['is_blocked'] ?? json['blocked']),
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