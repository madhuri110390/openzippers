import '../models/wallet_history_response.dart';
import '../network/api_client.dart';

class WalletHistoryRepository {
  final ApiClient apiClient;
  WalletHistoryRepository(this.apiClient);

  Future<WalletHistoryResponse> getHistory() async {
    return await apiClient.getWalletHistory();
  }
}