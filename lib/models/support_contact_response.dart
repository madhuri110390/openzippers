class SupportContactResponse {
  final bool success;
  final String message;
  final SupportData? data;

  SupportContactResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SupportContactResponse.fromJson(Map<String, dynamic> json) {
    return SupportContactResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? SupportData.fromJson(json['data'])
          : null,
    );
  }
}

class SupportData {
  final String subject;
  final String category;
  final String categoryLabel;
  final String message;
  final String submittedAt;
  final int userId;
  final String username;
  final String name;
  final String email;
  final bool fromAuthenticatedUser;

  SupportData({
    required this.subject,
    required this.category,
    required this.categoryLabel,
    required this.message,
    required this.submittedAt,
    required this.userId,
    required this.username,
    required this.name,
    required this.email,
    required this.fromAuthenticatedUser,
  });

  factory SupportData.fromJson(Map<String, dynamic> json) {
    return SupportData(
      subject: json['subject'] ?? '',
      category: json['category'] ?? '',
      categoryLabel: json['category_label'] ?? '',
      message: json['message'] ?? '',
      submittedAt: json['submitted_at'] ?? '',
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      fromAuthenticatedUser:
      json['from_authenticated_user'] ?? false,
    );
  }
}