import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/wallet_payment_repository.dart';
import 'api_client_provider.dart';

final walletPaymentRepositoryProvider = Provider<WalletPaymentRepository>((ref) {
  return WalletPaymentRepository(ref.read(apiClientProvider));
});

class WalletPaymentState {
  final bool isLoading;
  final bool success;
  final String? error;

  const WalletPaymentState({
    this.isLoading = false,
    this.success = false,
    this.error,
  });

  WalletPaymentState copyWith({
    bool? isLoading,
    bool? success,
    String? error,
  }) =>
      WalletPaymentState(
        isLoading: isLoading ?? this.isLoading,
        success: success ?? this.success,
        error: error ?? this.error,
      );
}

class WalletPaymentNotifier extends StateNotifier<WalletPaymentState> {
  final WalletPaymentRepository _repository;

  WalletPaymentNotifier(this._repository) : super(const WalletPaymentState());

  Future<void> pay({required int postId}) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      final response = await _repository.payWithWallet(postId: postId);
      if (response.success && response.data.success) {
        state = state.copyWith(isLoading: false, success: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Payment failed');
      }
    } on DioException catch (e) {
      // Extract readable server error message
      String errorMsg = 'Payment failed';
      try {
        final data = e.response?.data;
        if (data is Map) {
          errorMsg = data['message']?.toString() ??
              data['error']?.toString() ??
              'Payment failed (${e.response?.statusCode})';
        }
      } catch (_) {
        errorMsg = 'Payment failed (${e.response?.statusCode ?? 'network error'})';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const WalletPaymentState();
}

final walletPaymentProvider =
StateNotifierProvider<WalletPaymentNotifier, WalletPaymentState>((ref) {
  return WalletPaymentNotifier(ref.read(walletPaymentRepositoryProvider));
});