class ReportResponse {
  final bool status;
  final String message;

  ReportResponse({
    required this.status,
    required this.message,
  });

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
    );
  }

  // Retrofit needs this
  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
  };
}