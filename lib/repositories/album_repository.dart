import '../models/album_create_response.dart';
import '../models/album_purchase_response.dart';
import '../models/album_response.dart';
import '../network/api_client.dart';


import '../models/album_response.dart';
import '../network/api_client.dart';

class AlbumRepository {
  final ApiClient apiClient;

  AlbumRepository(this.apiClient);

  Future<AlbumsResponse> getAlbums() => apiClient.getAlbums();

  Future<AlbumCreateResponse> createAlbum(Map<String, dynamic> body) =>
      apiClient.createAlbum(body);

  Future<AlbumCreateResponse> deleteAlbum(int id) =>
      apiClient.deleteAlbum(id);

  Future<AlbumCreateResponse> updateAlbum(int id, Map<String, dynamic> body) =>
      apiClient.updateAlbum(id, body);

  Future<AlbumPurchaseResponse> purchaseAlbum(Map<String, dynamic> body) =>
      apiClient.purchaseAlbum(body);
}