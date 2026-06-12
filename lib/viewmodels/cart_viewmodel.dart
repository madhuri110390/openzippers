import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_state.dart';
import '../repositories/add_cart_repository.dart';

class CartViewModel extends StateNotifier<CartState> {
  final AddCartRepository repository;

  CartViewModel(this.repository)
      : super(const CartState());

  Future<void> toggleCart(int postId) async {
    try {
      state = state.copyWith(isLoading: true);

      final response =
      await repository.toggleCart(postId);

      state = state.copyWith(
        isLoading: false,
        message: response.message,
        cartCount: response.cartCount ?? 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        message: e.toString(),
      );
    }
  }
}