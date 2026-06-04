import 'album_model.dart';

class AlbumsResponse {
  final bool success;
  final List<Album> albums;
  final List<Album> publicAlbums;
  final List<Album> purchasedAlbums;
  final bool canCreateAlbum;

  AlbumsResponse({
    required this.success,
    required this.albums,
    required this.publicAlbums,
    required this.purchasedAlbums,
    required this.canCreateAlbum,
  });

  factory AlbumsResponse.fromJson(Map<String, dynamic> json) {
    return AlbumsResponse(
      success: json['success'] ?? false,
      albums: (json['albums'] as List? ?? [])
          .map((e) => Album.fromJson(e))
          .toList(),
      publicAlbums: (json['public_albums'] as List? ?? [])
          .map((e) => Album.fromJson(e))
          .toList(),
      purchasedAlbums: (json['purchased_albums'] as List? ?? [])
          .map((e) => Album.fromJson(e))
          .toList(),
      canCreateAlbum: json['can_create_album'] ?? false,
    );
  }

  @override
  String toString() =>
      'AlbumsResponse{success: $success, albums: $albums, publicAlbums: $publicAlbums, purchasedAlbums: $purchasedAlbums}';
}