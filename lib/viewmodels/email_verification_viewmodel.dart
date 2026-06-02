import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../repositories/email_verification_repository.dart';

final emailVerificationProvider =
StateNotifierProvider<
    EmailVerificationViewModel,
    bool>(
      (ref) {

    final dio = Dio();

    dio.options.baseUrl =
    "https://openzipper.com/api/v1/";

    dio.options.headers = {
      "Accept": "application/json",
    };

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {

          final prefs =
          await SharedPreferences.getInstance();

          final token =
          prefs.getString("auth_token");

          print("TOKEN = $token");

          options.headers["Authorization"] =
          "Bearer $token";

          print("URL = ${options.uri}");
          print("HEADERS = ${options.headers}");

          handler.next(options);
        },
      ),
    );

    final apiClient = ApiClient(dio);

    final repository =
    EmailVerificationRepository(apiClient);

    return EmailVerificationViewModel(
      repository,
    );
  },
);

class EmailVerificationViewModel
    extends StateNotifier<bool> {

  final EmailVerificationRepository repository;

  EmailVerificationViewModel(
      this.repository,
      ) : super(false);

  Future<String> sendVerificationEmail() async {

    try {

      state = true;

      print("EMAIL VERIFY API STARTED");

      final response =
      await repository.sendVerificationEmail();

      print("EMAIL VERIFY API SUCCESS");

      return response.message;

    } on DioException catch (e) {

      print("DIO ERROR = ${e.response?.data}");
      print("STATUS CODE = ${e.response?.statusCode}");

      return e.response?.data["message"] ??
          "Verification failed";

    } catch (e) {

      print("ERROR = $e");

      return e.toString();

    } finally {

      state = false;
    }
  }
}