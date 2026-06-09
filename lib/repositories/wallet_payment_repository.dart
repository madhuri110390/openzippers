import '../network/api_client.dart';
import '../models/wallet_payment_response.dart';

class WalletPaymentRepository {
  final ApiClient _apiClient;
  WalletPaymentRepository(this._apiClient);

  Future<WalletPaymentResponse> payWithWallet({
    required int postId,
  }) async {
    return await _apiClient.walletPayment({
      'purpose': 'buy_post',
      'related_id': postId,
      'payment_gateway': 'wallet',
    });
  }
}