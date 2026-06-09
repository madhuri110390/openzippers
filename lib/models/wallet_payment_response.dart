class WalletPaymentResponse {
  final bool success;
  final WalletPaymentData data;

  WalletPaymentResponse({required this.success, required this.data});

  factory WalletPaymentResponse.fromJson(Map<String, dynamic> json) {
    return WalletPaymentResponse(
      success: json['success'] ?? false,
      data: WalletPaymentData.fromJson(json['data'] ?? {}),
    );
  }
}

class WalletPaymentData {
  final bool success;

  WalletPaymentData({required this.success});

  factory WalletPaymentData.fromJson(Map<String, dynamic> json) {
    return WalletPaymentData(success: json['success'] ?? false);
  }
}