

import 'package:dio/dio.dart';

import '../models/delete_post_response.dart';
import '../network/api_client.dart';

class DeletePostRepository {
  final ApiClient _apiClient;

  DeletePostRepository(this._apiClient);

  Future<DeletePostResponse> deletePost(int postId) async {
    try {
      final response = await _apiClient.deletePost(postId);
      return response;
    } on DioException catch (e) {
      // You can extract custom error message from response if needed
      throw Exception(e.response?.data['message'] ?? 'Delete failed');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}