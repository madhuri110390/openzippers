import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../viewmodels/register_view_model.dart';
// lib/providers/api_client_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://openzippers.com/api/v1/',
      headers: {
        'Accept': 'application/json',
        'openzippers-skip-browser-warning': 'true', // ← ADD THIS
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        debugPrint('=== API HIT: ${options.uri}');
        debugPrint('=== TOKEN: $token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('=== API ERROR: ${error.response?.statusCode}');
        debugPrint('=== ERROR BODY: ${error.response?.data}');
        handler.next(error);
      },
    ),
  );

  return ApiClient(dio);
});