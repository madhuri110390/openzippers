import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_history_response.dart';
import '../repositories/wallet_history_repository.dart';
import 'api_client_provider.dart';

final walletHistoryRepositoryProvider = Provider<WalletHistoryRepository>((ref) {
  return WalletHistoryRepository(ref.read(apiClientProvider));
});

final walletHistoryProvider =
FutureProvider.autoDispose<WalletHistoryResponse>((ref) async {
  return await ref.read(walletHistoryRepositoryProvider).getHistory();
});