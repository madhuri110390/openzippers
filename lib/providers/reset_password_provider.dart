import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client_provider.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum RPStatus { idle, loading, success, error }

class RPState {
  final RPStatus status;
  final String? message;
  final String? error;

  const RPState({this.status = RPStatus.idle, this.message, this.error});

  RPState copyWith({RPStatus? status, String? message, String? error}) =>
      RPState(
        status: status ?? this.status,
        message: message,
        error: error,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ResetPasswordNotifier extends StateNotifier<RPState> {
  final Ref ref;

  ResetPasswordNotifier(this.ref) : super(const RPState());

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(status: RPStatus.loading);
    try {
      final api = ref.read(apiClientProvider);

      // Payload exactly as confirmed working in Postman
      final res = await api.resetPassword({
        "email": email.trim(),
        "token": token.trim(),
        "password": password,
        "password_confirmation": passwordConfirmation,
      });

      // API returns {"success": true/false, "message": "..."}
      final bool isSuccess = res['success'] == true;
      final String message = res['message']?.toString() ?? '';

      if (isSuccess) {
        state = state.copyWith(status: RPStatus.success, message: message);
      } else {
        state = state.copyWith(status: RPStatus.error, error: message);
      }
    } catch (e) {
      state = state.copyWith(
        status: RPStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const RPState();
}

// ── Provider ─────────────────────────────────────────────────────────────────

final resetPasswordProvider =
StateNotifierProvider.autoDispose<ResetPasswordNotifier, RPState>(
      (ref) => ResetPasswordNotifier(ref),
);