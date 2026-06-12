import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/remove_cart_response.dart';
import '../repositories/remove_cart_repository.dart';
import 'api_client_provider.dart';

final removeCartRepositoryProvider = Provider<RemoveCartRepository>((ref) {
  return RemoveCartRepository(ref.read(apiClientProvider));
});

class RemoveCartState {
  final bool isLoading;
  final bool success;
  final String? error;

  const RemoveCartState({
    this.isLoading = false,
    this.success = false,
    this.error,
  });

  RemoveCartState copyWith({bool? isLoading, bool? success, String? error}) =>
      RemoveCartState(
        isLoading: isLoading ?? this.isLoading,
        success: success ?? this.success,
        error: error ?? this.error,
      );
}

class RemoveCartNotifier extends StateNotifier<RemoveCartState> {
  final RemoveCartRepository _repository;

  RemoveCartNotifier(this._repository) : super(const RemoveCartState());

  Future<void> remove({required int cartId}) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repository.removeItem(cartId: cartId);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const RemoveCartState();
}

final removeCartProvider =
StateNotifierProvider<RemoveCartNotifier, RemoveCartState>((ref) {
  return RemoveCartNotifier(ref.read(removeCartRepositoryProvider));
});