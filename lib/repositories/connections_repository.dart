import '../models/connection_response.dart';
import '../network/api_client.dart';

class ConnectionsRepository {
  final ApiClient apiClient;

  ConnectionsRepository(this.apiClient);

  Future<ConnectionsResponse> getConnections(String username) async {
    return await apiClient.getConnections(username: username);
  }
}