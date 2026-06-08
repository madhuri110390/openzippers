class CartResponse {
  final bool success;
  final CartData data;

  CartResponse({
    required this.success,
    required this.data,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      success: json['success'] ?? false,
      data: CartData.fromJson(json['data']),
    );
  }
}

class CartData {
  final bool success;
  final CartSummary data;

  CartData({
    required this.success,
    required this.data,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    return CartData(
      success: json['success'] ?? false,
      data: CartSummary.fromJson(json['data']),
    );
  }
}

class CartSummary {
  final double subtotal;
  final double taxAmount;
  final double total;
  final String walletBalance;
  final int itemCount;
  final List<CartItem> items;

  CartSummary({
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.walletBalance,
    required this.itemCount,
    required this.items,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      subtotal: double.parse(json['subtotal'].toString()),
      taxAmount: double.parse(json['tax_amount'].toString()),
      total: double.parse(json['total'].toString()),
      walletBalance: json['wallet_balance'].toString(),
      itemCount: json['item_count'] ?? 0,
      items: (json['items'] as List)
          .map((e) => CartItem.fromJson(e))
          .toList(),
    );
  }
}

class CartItem {
  final int id;
  final int postId;
  final String title;
  final String price;

  CartItem({
    required this.id,
    required this.postId,
    required this.title,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      postId: json['post_id'],
      title: json['title'] ?? '',
      price: json['price'] ?? '',
    );
  }
}