import 'dart:ffi';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/register_response.dart';
import '../models/location_models.dart';
import '../network/api_client.dart';

class AuthRepository {
  late final ApiClient _apiClient;

  /// Accepts a [Dio] instance (injected via Riverpod's dioProvider)
  /// which already has the auth token interceptor configured.
  AuthRepository(Dio dio) {
    _apiClient = ApiClient(dio);
  }

  Future<RegisterResponse> registerUser({
    required String name,
    required String username,
    required String mobileNumber,
    required String countryId,
    required String stateId,
    required String cityId,
    required String gender,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String agree,
    File? avatar,
    File? coverImage,
  }) async {
    try {
      final response = await _apiClient.register(
        name: name,
        username: username,
        mobileNumber: mobileNumber,
        countryId: countryId,
        stateId: stateId,
        cityId: cityId,
        gender: gender,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        agree: agree,
        avatar: avatar,
        coverImage: coverImage,
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final rawSuccess = errorData['success'];
          final bool isSuccess = rawSuccess == true || rawSuccess == 1 ||
              rawSuccess == '1';
          if (!isSuccess && errorData['errors'] != null) {
            return RegisterResponse.fromJson(errorData);
          }
          if (!isSuccess) {
            return RegisterResponse(
              success: false,
              message: errorData['message']?.toString() ??
                  'Registration failed.',
              errors: null,
            );
          }
        }
      }
      rethrow;
    }
  }

  Future<RegisterResponse> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.login({
        'email': email,
        'password': password,
      });
      return response;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final rawSuccess = errorData['success'];
          final bool isSuccess = rawSuccess == true || rawSuccess == 1 ||
              rawSuccess == '1';
          if (!isSuccess && errorData['errors'] != null) {
            return RegisterResponse.fromJson(errorData);
          }
          if (!isSuccess) {
            return RegisterResponse(
              success: false,
              message: errorData['message']?.toString() ?? 'Login failed.',
              errors: null,
            );
          }
        }
      }
      rethrow;
    }
  }

  Future<RegisterResponse> getUserByUsername(String username) async {
    try {
      final response = await _apiClient.getUserByUsername(username: username);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches the currently authenticated user's details using the Bearer token.
  /// Works for both regular users and artists — no username required.
  Future<RegisterResponse> getUserDetails() async {
    try {
      final response = await _apiClient.getUserDetails();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<RegisterResponse> getUserById(int id) async {
    try {
      final response = await _apiClient.getUserById(id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Logs out the user from all devices by calling the /logout-all endpoint.
  /// The Bearer token is injected automatically by the Dio interceptor.
  Future<RegisterResponse> logoutUser() async {
    try {
      final response = await _apiClient.logoutAll();
      return response;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          return RegisterResponse(
            success: false,
            message: errorData['message']?.toString() ?? 'Logout failed.',
            errors: null,
          );
        }
      }
      rethrow;
    }
  }

  Future<List<Country>> getCountries() async {
    try {
      return await _apiClient.getCountries();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StateModel>> getStates(String countryId) async {
    try {
      return await _apiClient.getStates(countryId: countryId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CityModel>> getCities(String stateId) async {
    try {
      return await _apiClient.getCities(stateId: stateId);
    } catch (e) {
      rethrow;
    }
  }


  Future<RegisterResponse> changePasswordUser({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.changePassword({
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      return response;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final rawSuccess = errorData['success'];
          final bool isSuccess = rawSuccess == true || rawSuccess == 1 ||
              rawSuccess == '1';
          if (!isSuccess && errorData['errors'] != null) {
            return RegisterResponse.fromJson(errorData);
          }
          if (!isSuccess) {
            return RegisterResponse(
              success: false,
              message: errorData['message']?.toString() ??
                  'Password change failed.',
              errors: null,
            );
          }
        }
      }
      rethrow;
    }
  }

  Future<RegisterResponse> updateProfile(
  {
   required String name,
   required String username,
    required String mobileNumber,
    required int countryId,
    required int stateId,
    required int cityId,
    required String gender,
    String? bio,

  }) async{
    return await _apiClient.updateProfile(
    {
        "name": name,
        "username": username,
        "mobile_number": mobileNumber,
        "country_id": countryId,
        "state_id": stateId,
        "city_id": cityId,
        "gender": gender.toLowerCase(),
        "bio": bio ?? "",
      });
}
}
