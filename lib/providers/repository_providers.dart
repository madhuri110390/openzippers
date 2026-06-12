// Add to your lib/providers/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/payment_transaction_repository.dart';
import '../viewmodels/payment_history_viewmodel.dart';
import 'api_client_provider.dart';

final paymentHistoryRepositoryProvider = Provider<PaymentHistoryRepository>((ref) {
  return PaymentHistoryRepository(ref.watch(apiClientProvider));
});

final paymentHistoryViewModelProvider =
StateNotifierProvider<PaymentHistoryViewModel, PaymentHistoryState>((ref) {
  return PaymentHistoryViewModel(ref.watch(paymentHistoryRepositoryProvider));
});