class CommentUserData {
  final String name;
  final String? avatar;

  CommentUserData({required this.name, this.avatar});

  factory CommentUserData.fromJson(Map<String, dynamic> json) {
    return CommentUserData(
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
    );
  }
}

class CommentData {
  final int id;
  final int postId;
  final int? parentId;
  final CommentUserData user;
  final String text;
  final String time;
  final List<CommentData> replies;          // ← was List<dynamic>

  CommentData({
    required this.id,
    required this.postId,
    this.parentId,
    required this.user,
    required this.text,
    required this.time,
    this.replies = const <CommentData>[],   // ← typed const
  });

  factory CommentData.fromJson(Map<String, dynamic> json) {
    return CommentData(
      // id: json['id'] ?? 0,
      // postId: json['post_id'] ?? 0,
      // parentId: json['parent_id'],
      id: int.tryParse(json['id'].toString()) ?? 0,

      postId: int.tryParse(
        json['post_id'].toString(),
      ) ?? 0,

      parentId: json['parent_id'] == null
          ? null
          : int.tryParse(
        json['parent_id'].toString(),
      ),
      user: json['user'] is Map
          ? CommentUserData.fromJson(
        Map<String, dynamic>.from(json['user']),
      )
          : CommentUserData(
        name: 'Unknown User',
        avatar: null,
      ),
      text: json['text'] ?? '',
      time: json['time'] ?? '',

      replies: (json['replies'] as List? ?? [])
          .where((e) => e != null)
          .whereType<Map>()
          .map(
            (e) => CommentData.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),
    );
  }

  Map<String, dynamic> toAppMap() => {
    'id': id,
    'author': user.name,
    'avatar': user.avatar ?? '',
    'text': text,
    'time': time,
    'parentId': parentId,
    'likes': [],
    // 'timestamp': DateTime.now(),
    'timestamp': DateTime.tryParse(time) ??
        DateTime.now(),
    'replies': replies.map((r) => r.toAppMap()).toList(),  // ← now works, r is CommentData
  };
}

class CommentResponse {
  final bool success;
  final CommentData? data;
  final String? message;

  CommentResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? CommentData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'],
    );
  }
}