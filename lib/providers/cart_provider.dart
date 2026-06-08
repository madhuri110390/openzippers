import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_response.dart';
import '../repositories/cart_repository.dart';
import 'api_client_provider.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.read(apiClientProvider));
});

final cartProvider =
FutureProvider.autoDispose<CartResponse>((ref) async {
  return await ref.read(cartRepositoryProvider).getCart();
});