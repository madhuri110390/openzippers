import '../network/api_client.dart';
import '../models/block_response.dart';

class BlockRepository {

  final ApiClient apiClient;

  BlockRepository(this.apiClient);

  Future<BlockResponse> toggleBlock(int userId) async {

    final response = await apiClient.toggleBlock({
      "user_id": userId,
    });

    return response;
  }
}