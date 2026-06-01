import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_state.dart';
import '../repositories/payment_repository.dart';
import '../viewmodels/payment_viewmodel.dart';
import 'api_client_provider.dart';

final paymentRepositoryProvider =
Provider<PaymentRepository>((ref) {
  return PaymentRepository(
    ref.read(apiClientProvider),
  );
});
final paymentViewModelProvider =
StateNotifierProvider<
    PaymentViewModel,
    PaymentState>((ref) {
  return PaymentViewModel(
    ref.read(paymentRepositoryProvider),
  );
});