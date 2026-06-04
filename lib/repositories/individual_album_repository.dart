import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/individual_album_model.dart';
import '../models/individual_album_response.dart';
import '../network/api_client.dart';

sealed class AlbumResult<T> {}

class AlbumSuccess<T> extends AlbumResult<T> {
  final T data;
  AlbumSuccess(this.data);
}

class AlbumFailure<T> extends AlbumResult<T> {
  final String message;
  AlbumFailure(this.message);
}

abstract class IndividualAlbumRepository {
  Future<AlbumResult<List<IndividualAlbumModel>>> getMyAlbums(int id);
  Future<AlbumResult<List<IndividualAlbumModel>>> getPublicAlbums(int id);
  Future<AlbumResult<List<IndividualAlbumModel>>> getPurchasedAlbums(int id);
}

class AlbumRepository implements IndividualAlbumRepository {
  AlbumRepository();

  Future<ApiClient> _client() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://openzippers.com/api/v1/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    return ApiClient(dio);
  }

  @override
  Future<AlbumResult<List<IndividualAlbumModel>>> getMyAlbums(int id) =>
      _fetchAlbums((r) => r.myAlbums, id);

  @override
  Future<AlbumResult<List<IndividualAlbumModel>>> getPublicAlbums(int id) =>
      _fetchAlbums((r) => r.publicAlbums, id);

  @override
  Future<AlbumResult<List<IndividualAlbumModel>>> getPurchasedAlbums(int id) =>
      _fetchAlbums((r) => r.purchasedAlbums, id);

  Future<AlbumResult<List<IndividualAlbumModel>>> _fetchAlbums(
      List<IndividualAlbumModel> Function(IndividualAlbumResponse response) extractor,
      int id,
      ) async {
    try {
      final client = await _client();
      final response = await client.getIndividualAlbums(id: id);
      return AlbumSuccess(extractor(response));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          'Network error (${e.response?.statusCode})';
      return AlbumFailure(msg.toString());
    } catch (e) {
      return AlbumFailure('Unexpected error: $e');
    }
  }
}