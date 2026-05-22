import '../models/search_response.dart';
import '../network/api_client.dart';

class SearchRepository {
  final ApiClient apiClient;

  SearchRepository(this.apiClient);

  Future<SearchResponse> globalSearch(String query) async {
    try {
      return await apiClient.globalSearch(query: query);
    } catch (e) {
      rethrow;
    }
  }
}