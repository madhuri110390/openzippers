import '../models/rating_response.dart';
import '../network/api_client.dart';

class RatingRepository {
  final ApiClient apiClient;

  RatingRepository(this.apiClient);

  Future<RatingResponse> getRatings(int postId) async {
    return await apiClient.getRatings(postId: postId);
  }
  Future<RatingResponse> submitRating({
    required int postId,
    required int rating,
  }) async {
    return await apiClient.submitRating({
      "post_id": postId,
      "rating": rating,
    });
  }
}