import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/comment_response.dart';

class CommentRepository {
  final Dio _dio;

  CommentRepository(this._dio);

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ============ FETCH COMMENTS ============
  Future<List<CommentData>> fetchComments({required int postId}) async {
    final token = await _getToken();

    try {
      final response = await _dio.get(
        // TRY THIS FIRST — RESTful pattern (most likely correct)
        'https://openzippers.com/api/v1/zippfans/posts/$postId/comments',

        // IF 404, comment line above and try this instead:
        // 'https://openzippers.com/api/v1/zippfans/comments/$postId',

        // IF 404, try this:
        // 'https://openzippers.com/api/v1/zippfans/post/$postId/comments',

        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugLog('Fetch comments: ${response.statusCode} ${response.data}');

      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      }
      if (response.statusCode == 404) {
        return [];
      }

      final data = response.data;
      if (data is Map && data['success'] == true) {
      //  final list = (data['data'] as List?) ?? [];
     //  // final list = (data['data']['comments'] as List?) ?? [];
        final list = (data['data']['comments'] as List?) ?? [];

        return list
            .map((e) => CommentData.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception(data?['message'] ?? 'Failed to fetch comments');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] as String?;
      throw Exception(serverMsg ?? e.message ?? 'Network error');
    }
  }

  // ============ POST COMMENT ============
  Future<CommentData> postComment({
    required int postId,
    required String content,
    int? parentId,
  }) async {
    final token = await _getToken();

    final formData = FormData.fromMap({
      'post_id': postId,
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });

    try {
      final response = await _dio.post(
        'https://openzippers.com/api/v1/zippfans/comments',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugLog('Comment API: ${response.statusCode} ${response.data}');

      if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      }
      if (response.statusCode == 422) {
        final errors = response.data?['errors'];
        String msg = 'Validation error';
        if (errors is Map) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            msg = first.first.toString();
          }
        }
        throw Exception(msg);
      }

      final result = CommentResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      if (result.success && result.data != null) {
        return result.data!;
      }
      throw Exception(result.message ?? 'Failed to post comment');
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] as String?;
      throw Exception(serverMsg ?? e.message ?? 'Network error');
    }
  }

  void debugLog(String msg) {
    assert(() {
      // ignore: avoid_print
      print(msg);
      return true;
    }());
  }
}