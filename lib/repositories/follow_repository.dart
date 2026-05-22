import '../models/follow_response.dart';
import '../network/api_client.dart';

class FollowRepository {

  final ApiClient apiClient;

  FollowRepository(this.apiClient);

  Future<FollowResponse> toggleFollow(
      int userId,
      ) async {

    final response =
    await apiClient.toggleFollow({

      "user_id": userId,
    });

    return response;
  }
}