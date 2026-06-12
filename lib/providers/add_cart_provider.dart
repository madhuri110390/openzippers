import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_state.dart';
import '../repositories/add_cart_repository.dart';
import '../viewmodels/cart_viewmodel.dart';

final cartViewModelProvider =
StateNotifierProvider<CartViewModel, CartState>((ref) {
  return CartViewModel(
    ref.read(addCartRepositoryProvider),
  );
});