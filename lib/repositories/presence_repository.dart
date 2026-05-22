import 'package:dio/dio.dart';
import '../models/presence_model.dart';

class PresenceRepository {
  final Dio _dio;

  PresenceRepository(this._dio);

  Future<PresenceModel> fetchPresence(String token) async {
    try {
      final response = await _dio.get(
        'https://openzippers.com/api/v1/presence',
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }),
      );
      return PresenceModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Presence error: $e');
    }
  }
}