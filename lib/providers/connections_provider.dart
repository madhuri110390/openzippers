import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection_response.dart';
import '../network/api_client.dart';
import '../repositories/connections_repository.dart';
import 'package:dio/dio.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.baseUrl = 'https://openzippers.com/api/v1/';
  dio.options.headers = {
    'Accept': 'application/json',
  };

  // Inject auth token on every request
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  dio.interceptors.add(LogInterceptor(
    request: true,
    requestBody: true,
    responseBody: true,
    requestHeader: true,
    error: true,
  ));

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider));
});

final connectionsRepositoryProvider =
Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepository(ref.read(apiClientProvider));
});

final connectionsProvider =
FutureProvider.family<ConnectionsResponse, String>((ref, username) async {
  return await ref
      .read(connectionsRepositoryProvider)
      .getConnections(username);
});