class WalletHistoryResponse {
  final List<WalletTransaction> data;

  WalletHistoryResponse({required this.data});

  factory WalletHistoryResponse.fromJson(Map<String, dynamic> json) {
    return WalletHistoryResponse(
      data: (json['data'] as List? ?? [])
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WalletTransaction {
  final int id;
  final int userId;
  final String amount;
  final String type;
  final String? stripeSessionId;
  final String status;
  final String createdAt;
  final String updatedAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.stripeSessionId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      amount: json['amount']?.toString() ?? '0',
      type: json['type']?.toString() ?? '',
      stripeSessionId: json['stripe_session_id']?.toString(),
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}