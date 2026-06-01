class PaymentState {
  final bool isLoading;
  final String? error;

  const PaymentState({
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}