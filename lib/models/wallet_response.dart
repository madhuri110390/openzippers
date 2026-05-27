class WalletResponse {
  final bool success;
  final WalletData data;

  WalletResponse({
    required this.success,
    required this.data,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      success: json['success'] ?? false,
      data: WalletData.fromJson(json['data'] ?? {}),
    );
  }
}

class WalletData {
  final double balance;
  final double walletAmount;

  WalletData({
    required this.balance,
    required this.walletAmount,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      balance: double.tryParse(json['balance'].toString()) ?? 0,
      walletAmount: double.tryParse(json['wallet_amount'].toString()) ?? 0,
    );
  }
}