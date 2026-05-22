import '../network/api_client.dart';
import '../models/support_contact_response.dart';

class SupportRepository {
  final ApiClient apiClient;

  SupportRepository(this.apiClient);

  Future<SupportContactResponse> submitSupport({
    required String subject,
    required String category,
    required String message,
    required String email,
    required String name,
  }) async {

    final response = await apiClient.submitSupportContact({
      "subject": subject,
      "category": category,
      "message": message,
      "email": email,
      "name": name,
    });

    return response;
  }
}