import '../models/remove_cart_response.dart';
import '../network/api_client.dart';

class RemoveCartRepository {
  final ApiClient apiClient;
  RemoveCartRepository(this.apiClient);

  Future<RemoveCartResponse> removeItem({required int cartId}) async {
    return await apiClient.removeCartItem(cartId);
  }
}