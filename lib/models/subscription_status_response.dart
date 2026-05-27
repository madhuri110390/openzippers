class SubscriptionStatusResponse {
  final bool success;
  final SubscriptionData data;

  SubscriptionStatusResponse({
    required this.success,
    required this.data,
  });

  factory SubscriptionStatusResponse.fromJson(
      Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      success: json['success'] ?? false,
      data: SubscriptionData.fromJson(json['data']),
    );
  }
}

class SubscriptionData {
  final bool isSubscribed;
  final Subscription? subscription;

  SubscriptionData({
    required this.isSubscribed,
    this.subscription,
  });

  factory SubscriptionData.fromJson(
      Map<String, dynamic> json) {
    return SubscriptionData(
      isSubscribed: json['isSubscribed'] ?? false,
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
    );
  }
}

class Subscription {
  final int id;
  final String status;
  final String amount;
  final String expiresAt;

  Subscription({
    required this.id,
    required this.status,
    required this.amount,
    required this.expiresAt,
  });

  factory Subscription.fromJson(
      Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      amount: json['amount'] ?? '',
      expiresAt: json['expires_at'] ?? '',
    );
  }
}