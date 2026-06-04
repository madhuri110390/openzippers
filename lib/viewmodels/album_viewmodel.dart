import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album_model.dart';
import '../models/album_response.dart';
import '../network/api_client.dart';
import '../repositories/album_repository.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://openzippers.com/api/v1/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
  return AlbumRepository(ApiClient(dio));
});

class AlbumViewModel extends StateNotifier<AsyncValue<AlbumsResponse>> {
  final AlbumRepository repository;

  AlbumViewModel(this.repository) : super(const AsyncLoading());

  Future<void> loadAlbums() async {
    try {
      state = const AsyncLoading();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://openzippers.com/api/v1/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token', // ✅ token injected here
          },
        ),
      );
      final response = await AlbumRepository(ApiClient(dio)).getAlbums();
      print("ALBUMS RESPONSE => ${response.toString()}");
// or better:
      print("FIRST ALBUM => ${response.albums.isNotEmpty ? response.albums.first.toString() : 'empty'}");
      state = AsyncData(response);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ✅ delete album locally from state
  void deleteLocalAlbums(int albumId) {
    state.whenData((response) {
      state = AsyncData(AlbumsResponse(
        success: response.success,
        albums: response.albums
            .where((a) => a.id != albumId)
            .toList(),
        publicAlbums: response.publicAlbums,
        purchasedAlbums: response.purchasedAlbums,
        canCreateAlbum: response.canCreateAlbum,
      ));
    });
  }
}

final albumViewModelProvider =
StateNotifierProvider<AlbumViewModel, AsyncValue<AlbumsResponse>>(
      (ref) => AlbumViewModel(ref.read(albumRepositoryProvider)),
);