import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/payment_state.dart';
import '../repositories/payment_repository.dart';

class PaymentViewModel
    extends StateNotifier<PaymentState> {
  final PaymentRepository repository;

  PaymentViewModel(this.repository)
      : super(const PaymentState());

  Future<bool> buyPost({
    required int postId,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final response =
      await repository.buyPaidPost(postId);

      state = state.copyWith(isLoading: false);

      if (response.success &&
          response.data != null) {
        final url = response.data!.checkoutUrl;

        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }
}