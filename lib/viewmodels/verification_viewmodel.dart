import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/verification_repository.dart';

import '../providers/verification_provider.dart';

class VerificationViewModel extends StateNotifier<bool> {
  final VerificationRepository repository;

  VerificationViewModel(this.repository) : super(false);

  Future<String> uploadVerification({
    required File governmentIdFront,
    required File governmentIdBack,
    required File passportPhoto,
  }) async {
    try {
      state = true;

      final response = await repository.uploadDocuments(
        governmentIdFront: governmentIdFront,
        governmentIdBack: governmentIdBack,
        passportPhoto: passportPhoto,
      );

      return response.message;
    } catch (e) {
      return e.toString();
    } finally {
      state = false;
    }
  }
}

final verificationViewModelProvider =
StateNotifierProvider<VerificationViewModel, bool>((ref) {
  final repository =
  ref.watch(verificationRepositoryProvider);

  return VerificationViewModel(repository);
});