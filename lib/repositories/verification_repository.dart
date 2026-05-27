import 'dart:io';

import '../models/verification_response.dart';
import '../network/api_client.dart';

class VerificationRepository {
  final ApiClient apiClient;

  VerificationRepository(this.apiClient);

  Future<VerificationResponse> uploadDocuments({
    required File governmentIdFront,
    required File governmentIdBack,
    required File passportPhoto,
  }) async {
    return await apiClient.uploadVerificationDocuments(
      governmentIdFront: governmentIdFront,
      governmentIdBack: governmentIdBack,
      passportPhoto: passportPhoto,
    );
  }
}