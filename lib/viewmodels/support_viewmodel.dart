import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/support_state.dart';
import '../providers/support_provider.dart';


final supportViewModelProvider =
StateNotifierProvider<SupportViewModel, SupportState>((ref) {

  final repository = ref.watch(supportRepositoryProvider);

  return SupportViewModel(repository);
});

class SupportViewModel extends StateNotifier<SupportState> {

  final dynamic repository;

  SupportViewModel(this.repository)
      : super(SupportState());

  Future<void> submitSupport({
    required String subject,
    required String category,
    required String message,
    required String email,
    required String name,
  }) async {

    try {

      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
      );

      final response = await repository.submitSupport(
        subject: subject,
        category: category,
        message: message,
        email: email,
        name: name,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: response.message,
      );

    } on DioException catch (e) {

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data.toString() ??
            "Something went wrong",
      );

    } catch (e) {

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}