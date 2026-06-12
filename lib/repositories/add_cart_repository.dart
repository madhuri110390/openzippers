import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_toggle_response.dart';
import '../network/api_client.dart';
import '../providers/api_client_provider.dart';

class AddCartRepository {
  final ApiClient apiClient;

  AddCartRepository(this.apiClient);

  Future<CartToggleResponse> toggleCart(int postId) async {
    return await apiClient.toggleCart({
      "post_id": postId,
    });
  }
}

final addCartRepositoryProvider =
Provider<AddCartRepository>((ref) {
  return AddCartRepository(
    ref.read(apiClientProvider),
  );
});