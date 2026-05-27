import '../models/subscription_status_response.dart';
import '../network/api_client.dart';

class SubscriptionRepository {
  final ApiClient apiClient;

  SubscriptionRepository(this.apiClient);

  Future<SubscriptionStatusResponse> getSubscriptionStatus(
      int artistId) {
    return apiClient.getSubscriptionStatus(
      artistId: artistId,
    );
  }
}