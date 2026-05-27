class VerificationResponse {
  final bool success;
  final String message;

  VerificationResponse({
    required this.success,
    required this.message,
  });

  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}