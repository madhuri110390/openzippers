import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';

import '../models/location_models.dart';

class RegisterState {
  final bool isLoading;
  final Map<String, String> backendErrors;
  final List<Country> countries;
  final List<StateModel> states;
  final List<CityModel> cities;
  final bool isFetchingLocations;

  RegisterState({
    this.isLoading = false,
    this.backendErrors = const {},
    this.countries = const [],
    this.states = const [],
    this.cities = const [],
    this.isFetchingLocations = false,
  });

  RegisterState copyWith({
    bool? isLoading,
    Map<String, String>? backendErrors,
    List<Country>? countries,
    List<StateModel>? states,
    List<CityModel>? cities,
    bool? isFetchingLocations,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      backendErrors: backendErrors ?? this.backendErrors,
      countries: countries ?? this.countries,
      states: states ?? this.states,
      cities: cities ?? this.cities,
      isFetchingLocations: isFetchingLocations ?? this.isFetchingLocations,
    );
  }
}

class RegisterViewModel extends StateNotifier<RegisterState> {
  final AuthRepository _repository;

  RegisterViewModel(this._repository) : super(RegisterState());

  void clearError(String field) {
    if (state.backendErrors.containsKey(field)) {
      final newErrors = Map<String, String>.from(state.backendErrors)..remove(field);
      state = state.copyWith(backendErrors: newErrors);
    }
  }

  void clearAllErrors() {
    state = state.copyWith(backendErrors: {});
  }

  Future<void> fetchCountries() async {
    state = state.copyWith(isFetchingLocations: true);
    try {
      final countries = await _repository.getCountries();
      state = state.copyWith(countries: countries, isFetchingLocations: false);
    } catch (e) {
      state = state.copyWith(isFetchingLocations: false);
      // Optional: Handle error silently or show a message
    }
  }

  Future<void> fetchStates(String countryId) async {
    state = state.copyWith(isFetchingLocations: true, states: [], cities: []);
    try {
      final states = await _repository.getStates(countryId);
      state = state.copyWith(states: states, isFetchingLocations: false);
    } catch (e) {
      state = state.copyWith(isFetchingLocations: false);
    }
  }

  Future<void> fetchCities(String stateId) async {
    state = state.copyWith(isFetchingLocations: true, cities: []);
    try {
      final cities = await _repository.getCities(stateId);
      state = state.copyWith(cities: cities, isFetchingLocations: false);
    } catch (e) {
      state = state.copyWith(isFetchingLocations: false);
    }
  }

  Future<bool> registerUser({
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
    required Function(String token) onSuccess,
    required Function(String error) onError,
  }) async {
    state = state.copyWith(isLoading: true, backendErrors: {});

    try {
      final response = await _repository.registerUser(
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

      if (response.success && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.data!.token ?? '');
        await prefs.setString('current_user_username', response.data!.user.username);
        
        onSuccess(response.data!.token ?? '');
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        if (response.errors != null) {
          final newErrors = <String, String>{};
          response.errors!.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              newErrors[key] = value[0].toString();
            } else {
              newErrors[key] = value.toString();
            }
          });
          state = state.copyWith(backendErrors: newErrors, isLoading: false);
          onError('Please correct the validation errors below.');
        } else {
          state = state.copyWith(isLoading: false);
          onError(response.message ?? 'Registration failed.');
        }
      }
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false);
      onError('Registration failed. $errorMsg');
    }
    
    return false;
  }
}

/// A shared Dio instance that automatically injects the Bearer token
/// from SharedPreferences into every request header.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
    ),
  );

  // Logging interceptor for debug visibility
  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: false,
    responseBody: true,
    error: true,
    logPrint: (log) => print(log),
  ));

  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRepository(dio);
});

final registerViewModelProvider = StateNotifierProvider<RegisterViewModel, RegisterState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return RegisterViewModel(repository);
});
