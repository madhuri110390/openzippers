// lib/models/payment_transactions_response.dart

class PaymentTransactionsResponse {
  final List<PaymentTransaction> transactions;

  PaymentTransactionsResponse({required this.transactions});

  factory PaymentTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionsResponse(
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => PaymentTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PaymentTransaction {
  final int id;
  final String amount;
  final String taxAmount;
  final String vatPercent;
  final String status;
  final String currency;
  final String createdAt;
  final String updatedAt;
  final int senderUserId;
  final int recipientUserId;
  final int transactableId;
  final String transactableType;
  final String transactableVariant;
  final String? paymentReferenceId;
  final String? paymentGateway;
  final TransactionRecipient? recipient;

  PaymentTransaction({
    required this.id,
    required this.amount,
    required this.taxAmount,
    required this.vatPercent,
    required this.status,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    required this.senderUserId,
    required this.recipientUserId,
    required this.transactableId,
    required this.transactableType,
    required this.transactableVariant,
    this.paymentReferenceId,
    this.paymentGateway,
    this.recipient,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? 0,
      amount: json['amount']?.toString() ?? '0',
      taxAmount: json['tax_amount']?.toString() ?? '0',
      vatPercent: json['vat_percent']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      senderUserId: json['sender_user_id'] ?? 0,
      recipientUserId: json['recipient_user_id'] ?? 0,
      transactableId: json['transactable_id'] ?? 0,
      transactableType: json['transactable_type']?.toString() ?? '',
      transactableVariant: json['transactable_variant']?.toString() ?? '',
      paymentReferenceId: json['payment_reference_id']?.toString(),
      paymentGateway: json['payment_gateway']?.toString(),
      recipient: json['recipient'] != null
          ? TransactionRecipient.fromJson(json['recipient'])
          : null,
    );
  }

  // Derive incoming/outgoing from logged-in user context
  bool isIncoming(int currentUserId) => recipientUserId == currentUserId;

  // Clean label from transactable_type e.g. "App\\Models\\Subscription" → "Subscription"
  String get transactableLabel {
    final parts = transactableType.split('\\');
    return parts.last;
  }

  // Format date from ISO to readable
  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return "${dt.day}-${_month(dt.month)}-${dt.year}";
    } catch (_) {
      return createdAt;
    }
  }

  static String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}

class TransactionRecipient {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;

  TransactionRecipient({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  factory TransactionRecipient.fromJson(Map<String, dynamic> json) {
    return TransactionRecipient(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}