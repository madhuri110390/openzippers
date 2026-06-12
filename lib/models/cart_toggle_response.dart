class CartToggleResponse {
  final String? message;
  final int? cartId;
  final int? cartCount;

  CartToggleResponse({
    this.message,
    this.cartId,
    this.cartCount,
  });

  factory CartToggleResponse.fromJson(Map<String, dynamic> json) {
    return CartToggleResponse(
      message: json['message'],
      cartId: json['cart_id'],
      cartCount: json['cart_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'cart_id': cartId,
      'cart_count': cartCount,
    };
  }
}