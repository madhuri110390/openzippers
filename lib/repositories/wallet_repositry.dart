import '../models/wallet_response.dart';
import '../network/api_client.dart';

class WalletRepository {
  final ApiClient apiClient;

  WalletRepository(this.apiClient);

  Future<WalletResponse> getWalletBalance() {
    return apiClient.getWalletBalance();
  }
}