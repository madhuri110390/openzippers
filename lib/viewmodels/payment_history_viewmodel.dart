// lib/viewmodels/payment_history_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_transaction_response.dart';
import '../repositories/payment_transaction_repository.dart';

class PaymentHistoryState {
  final bool isLoading;
  final List<PaymentTransaction> transactions;
  final String? error;

  const PaymentHistoryState({
    this.isLoading = false,
    this.transactions = const [],
    this.error,
  });

  PaymentHistoryState copyWith({
    bool? isLoading,
    List<PaymentTransaction>? transactions,
    String? error,
  }) {
    return PaymentHistoryState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      error: error,
    );
  }
}

class PaymentHistoryViewModel extends StateNotifier<PaymentHistoryState> {
  final PaymentHistoryRepository _repository;

  PaymentHistoryViewModel(this._repository)
      : super(const PaymentHistoryState()) {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getTransactions();
      state = state.copyWith(
        isLoading: false,
        transactions: response.transactions,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}