import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      headers: {
        'openzippers-skip-browser-warning': 'true',
        'Accept': 'application/json',
      },
    ),
  );


  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  };

  // ✅ Attach auth token to every request
  dio.interceptors.add(
    InterceptorsWrapper(
      // onRequest: (options, handler) async {
      //   final prefs = await SharedPreferences.getInstance();
      //   final token = prefs.getString('auth_token');
      //
      //   if (token != null && token.isNotEmpty) {
      //     options.headers['Authorization'] = 'Bearer $token';
      //   }
      //
      //   return handler.next(options);
      // },
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // ← add this
        debugPrint("REQUEST: ${options.uri}");
        debugPrint("TOKEN SENT: $token");

        return handler.next(options);
      },
    ),
  );

  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRepository(dio);
});