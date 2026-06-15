class AlbumCreateResponse {
  final bool success;
  final String? message;

  AlbumCreateResponse({required this.success, this.message});

  factory AlbumCreateResponse.fromJson(Map<String, dynamic> json) {
    return AlbumCreateResponse(
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}