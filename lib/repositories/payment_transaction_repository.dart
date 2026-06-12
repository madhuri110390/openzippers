// lib/repositories/payment_history_repository.dart
import 'package:dio/dio.dart';
import '../models/payment_transaction_response.dart';
import '../network/api_client.dart';

class PaymentHistoryRepository {
  final ApiClient _apiClient;
  PaymentHistoryRepository(this._apiClient);

  Future<PaymentTransactionsResponse> getTransactions() async {
    final response = await _apiClient.getPaymentTransactions();
    return PaymentTransactionsResponse.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }
}