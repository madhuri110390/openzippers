import '../models/email_verfication_response.dart';
import '../network/api_client.dart';

class EmailVerificationRepository {
  final ApiClient apiClient;

  EmailVerificationRepository(this.apiClient);

  Future<EmailVerificationResponse> sendVerificationEmail() async {
    try {
      final response =
      await apiClient.sendVerificationEmail();

      return response;
    } catch (e) {
      rethrow;
    }
  }
}