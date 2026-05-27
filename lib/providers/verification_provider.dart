import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../repositories/verification_repository.dart';


final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  dio.options.baseUrl =
  "https://overlearnedly-unfluvial-flynn.ngrok-free.dev/api/v1/";

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {

        final prefs =
        await SharedPreferences.getInstance();

        final token =
        prefs.getString("auth_token");

        options.headers = {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        };

        return handler.next(options);
      },
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

final verificationRepositoryProvider =
Provider<VerificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VerificationRepository(apiClient);
});