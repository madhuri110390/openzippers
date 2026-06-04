import '../models/album_response.dart';
import '../network/api_client.dart';


class AlbumRepository {
  final ApiClient apiClient;

  AlbumRepository(this.apiClient);

  Future<AlbumsResponse> getAlbums() {
    return apiClient.getAlbums();
  }
}