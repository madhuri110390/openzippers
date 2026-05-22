import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client_provider.dart';

enum FPStatus { idle, loading, success, error }

class FPState {
  final FPStatus status;
  final String? message;
  final String? error;

  const FPState({this.status = FPStatus.idle, this.message, this.error});

  FPState copyWith({FPStatus? status, String? message, String? error}) =>
      FPState(status: status ?? this.status, message: message, error: error);
}

class ForgotPasswordNotifier extends StateNotifier<FPState> {
  final Ref ref;

  ForgotPasswordNotifier(this.ref) : super(const FPState());

  Future<void> sendResetLink(String email) async {
    state = state.copyWith(status: FPStatus.loading);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.forgotPassword({"email": email.trim()});

      // FIX 1: API returns {"success": true/false, "message": "..."}
      // Must check success flag — server can return 200 with success: false
      final bool isSuccess = res['success'] == true;
      final String message = res['message']?.toString() ?? '';

      if (isSuccess) {
        state = state.copyWith(status: FPStatus.success, message: message);
      } else {
        state = state.copyWith(status: FPStatus.error, error: message);
      }
    } on DioException catch (e) {
      // FIX 2: Extract clean message — never show raw Dio dump to user
      String message = 'Something went wrong. Please try again.';
      final data = e.response?.data;
      if (data is Map) {
        message = data['message']?.toString() ?? message;
      }
      state = state.copyWith(status: FPStatus.error, error: message);
    } catch (e) {
      state = state.copyWith(
        status: FPStatus.error,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() => state = const FPState();
}

final forgotPasswordProvider =
StateNotifierProvider.autoDispose<ForgotPasswordNotifier, FPState>(
      (ref) => ForgotPasswordNotifier(ref),
);