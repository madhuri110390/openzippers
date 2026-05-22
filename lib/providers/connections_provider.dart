import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_response.dart';
import '../network/api_client.dart';
import '../repositories/connections_repository.dart';
import 'package:dio/dio.dart';

final dioProvider = Provider<Dio>((ref) {

  final dio = Dio();

  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      error: true,
    ),
  );

  dio.options.headers = {
    "Accept": "application/json",
  };

  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider));
});

final connectionsRepositoryProvider =
Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepository(
    ref.read(apiClientProvider),
  );
});

final connectionsProvider =
FutureProvider.family<ConnectionsResponse, String>((ref, username) async {
  return await ref
      .read(connectionsRepositoryProvider)
      .getConnections(username);
});