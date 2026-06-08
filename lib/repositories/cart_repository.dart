import '../models/cart_response.dart';
import '../network/api_client.dart';

class CartRepository {
  final ApiClient apiClient;

  CartRepository(this.apiClient);

  Future<CartResponse> getCart() async {
    return await apiClient.getCart();
  }
}