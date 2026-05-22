import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/register_view_model.dart'; // To reuse authRepositoryProvider

class LoginState {
  final bool isLoading;
  final Map<String, String> backendErrors;

  LoginState({
    this.isLoading = false,
    this.backendErrors = const {},
  });

  LoginState copyWith({
    bool? isLoading,
    Map<String, String>? backendErrors,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      backendErrors: backendErrors ?? this.backendErrors,
    );
  }
}

class LoginViewModel extends StateNotifier<LoginState> {
  final AuthRepository _repository;

  LoginViewModel(this._repository) : super(LoginState());

  void clearError(String field) {
    if (state.backendErrors.containsKey(field)) {
      final newErrors = Map<String, String>.from(state.backendErrors)..remove(field);
      state = state.copyWith(backendErrors: newErrors);
    }
  }

  void clearAllErrors() {
    state = state.copyWith(backendErrors: {});
  }

  Future<bool> loginUser({
    required String email,
    required String password,
    required Function(String token) onSuccess,
    required Function(String error) onError,
  }) async {
    state = state.copyWith(isLoading: true, backendErrors: {});

    try {
      final response = await _repository.loginUser(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.data!.token ?? '');
        await prefs.setInt('user_id', response.data!.user.id);
        await prefs.setString('current_user_username', response.data!.user.username);
        await prefs.setInt('role_id', response.data!.user.roleId);
        await prefs.setString('user_name', response.data!.user.name);
        await prefs.setString('user_email', response.data!.user.email);
        if (response.data!.user.avatarUrl != null) {
          await prefs.setString('user_avatar', response.data!.user.avatarUrl!);
        }
        
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
          onError(response.message ?? 'Login failed.');
        }
      }
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false);
      onError('Login failed. $errorMsg');
    }
    
    return false;
  }

  /// Calls the /logout-all API endpoint, then clears all locally stored
  /// auth tokens and user data regardless of the API response.
  Future<bool> logoutUser({
    required Function(String? message) onSuccess,
    required Function(String error) onError,
  }) async {
    state = state.copyWith(isLoading: true);
    String? apiMessage;

    try {
      final response = await _repository.logoutUser();
      if (response.success) {
        apiMessage = response.message;
      }
    } catch (_) {
      // Even if the API call fails, proceed with local logout.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user_username');
      await prefs.remove('role_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_avatar');
      await prefs.remove('is_artist'); // Also clear is_artist
    } catch (e) {
      state = state.copyWith(isLoading: false);
      onError('Failed to clear session: ${e.toString()}');
      return false;
    }

    state = state.copyWith(isLoading: false);
    onSuccess(apiMessage);
    return true;
  }
}

final loginViewModelProvider = StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return LoginViewModel(repository);
});
