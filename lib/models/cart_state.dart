class CartState {
  final bool isLoading;
  final String? message;
  final int cartCount;

  const CartState({
    this.isLoading = false,
    this.message,
    this.cartCount = 0,
  });

  CartState copyWith({
    bool? isLoading,
    String? message,
    int? cartCount,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      cartCount: cartCount ?? this.cartCount,
    );
  }
}