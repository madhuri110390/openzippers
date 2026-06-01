class PostCheckoutResponse {
  final bool success;
  final CheckoutData? data;

  PostCheckoutResponse({
    required this.success,
    this.data,
  });

  factory PostCheckoutResponse.fromJson(
      Map<String, dynamic> json) {
    return PostCheckoutResponse(
      success: json["success"] ?? false,
      data: json["data"] != null
          ? CheckoutData.fromJson(json["data"])
          : null,
    );
  }
}

class CheckoutData {
  final String checkoutUrl;
  final String sessionId;

  CheckoutData({
    required this.checkoutUrl,
    required this.sessionId,
  });

  factory CheckoutData.fromJson(
      Map<String, dynamic> json) {
    return CheckoutData(
      checkoutUrl: json["checkout_url"] ?? "",
      sessionId: json["session_id"] ?? "",
    );
  }
}