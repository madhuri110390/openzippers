class SupportState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  SupportState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  SupportState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return SupportState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}