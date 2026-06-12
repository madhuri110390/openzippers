class RemoveCartResponse {
  final String message;
  final int cartCount;

  RemoveCartResponse({required this.message, required this.cartCount});

  factory RemoveCartResponse.fromJson(Map<String, dynamic> json) {
    return RemoveCartResponse(
      message: json['message']?.toString() ?? '',
      cartCount: json['cart_count'] ?? 0,
    );
  }
}