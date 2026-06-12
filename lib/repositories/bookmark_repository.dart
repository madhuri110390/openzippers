import '../network/api_client.dart';
import '../models/bookmark_response.dart';

class BookmarkRepository {
  final ApiClient _apiClient;

  BookmarkRepository(this._apiClient);

  Future<BookmarkResponse> toggleBookmark(int postId) async {
    return await _apiClient.toggleBookmark({'post_id': postId});
  }
}