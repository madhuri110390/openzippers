class AlbumPurchaseResponse {
  final bool success;
  final String? message;

  AlbumPurchaseResponse({required this.success, this.message});

  factory AlbumPurchaseResponse.fromJson(Map<String, dynamic> json) {
    return AlbumPurchaseResponse(
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}