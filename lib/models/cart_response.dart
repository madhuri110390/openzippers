class CartResponse {
  final List<CartItem> cartItems;
  final double walletAmount;
  final double vatPercent;

  CartResponse({
    required this.cartItems,
    required this.walletAmount,
    required this.vatPercent,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      cartItems: (json['cartItems'] as List? ?? [])
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      walletAmount: _toDouble(json['walletAmount']),
      vatPercent: _toDouble(json['vat_percent']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  // Computed helpers used by CartScreen
  double get subtotal => cartItems.fold(0.0, (s, i) => s + _toDouble(i.price));
  double get taxAmount => subtotal * (vatPercent / 100);
  double get total => subtotal + taxAmount;
  int get itemCount => cartItems.length;
}

class CartItem {
  final int id;
  final int postId;
  final String title;
  final String image;
  final String price;
  final String type;
  final String authorName;
  final String authorAvatar;

  CartItem({
    required this.id,
    required this.postId,
    required this.title,
    required this.image,
    required this.price,
    required this.type,
    required this.authorName,
    required this.authorAvatar,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return CartItem(
      id: json['id'] ?? 0,
      postId: json['post_id'] ?? 0,
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      type: json['type']?.toString() ?? '',
      authorName: user['name']?.toString() ?? '',
      authorAvatar: user['avatar']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}