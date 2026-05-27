import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet_response.dart';

import '../repositories/wallet_repositry.dart';
import 'api_client_provider.dart';

final walletRepositoryProvider =
Provider<WalletRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return WalletRepository(apiClient);
});

final walletProvider =
FutureProvider<WalletResponse>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.getWalletBalance();
});