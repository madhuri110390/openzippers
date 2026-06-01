import '../network/api_client.dart';
import '../models/post_checkout_response.dart';

class PaymentRepository {
  final ApiClient apiClient;

  PaymentRepository(this.apiClient);

  Future<PostCheckoutResponse> buyPaidPost(
      int postId) async {
    return await apiClient.createPostCheckout({
      "post_id": postId,
    });
  }
}