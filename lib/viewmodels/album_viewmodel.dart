import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album_response.dart';
import '../network/api_client.dart';
import '../repositories/album_repository.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://openzippers.com/api/v1/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json'},
  ));
  return AlbumRepository(ApiClient(dio));
});

class AlbumViewModel extends StateNotifier<AsyncValue<AlbumsResponse>> {
  final AlbumRepository repository;

  AlbumViewModel(this.repository) : super(const AsyncLoading());

  Future<Dio> _authedDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return Dio(BaseOptions(
      baseUrl: 'https://openzippers.com/api/v1/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
  }

  Future<void> loadAlbums() async {
    try {
      state = const AsyncLoading();
      final dio = await _authedDio();
      final response = await AlbumRepository(ApiClient(dio)).getAlbums();
      debugPrint("ALBUMS RESPONSE => ${response.toString()}");
      debugPrint("FIRST ALBUM => ${response.albums.isNotEmpty ? response.albums.first.toString() : 'empty'}");
      state = AsyncData(response);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> createAlbum({
    required String title,
    required bool isPublic,
    required double price,
    required List<Map<String, dynamic>> media,
    String? imageBase64,
  }) async {
    final dio = await _authedDio();
    final body = <String, dynamic>{
      'title': title,
      'is_public': isPublic ? 1 : 0,
      'price': price,
      'media': media,
    };
    if (imageBase64 != null) {
      body['image_base64'] = imageBase64;
    }
    try {
      await AlbumRepository(ApiClient(dio)).createAlbum(body);
    } catch (e) {
      if (e is DioException) {
        debugPrint('CREATE 422 BODY: ${e.response?.data}');
      }
      rethrow;
    }
    await loadAlbums();
  }

  Future<void> updateAlbum({
    required int id,
    required String title,
    required bool isPublic,
    required double price,
    required List<Map<String, dynamic>> media,
  }) async {
    final dio = await _authedDio();
    final body = {
      'title': title,
      'is_public': isPublic,
      'price': price,
      'media': media,
    };
    debugPrint('UPDATE BODY: $body');
    try {
      await AlbumRepository(ApiClient(dio)).updateAlbum(id, body);
    } catch (e) {
      if (e is DioException) {
        debugPrint('UPDATE 422 BODY: ${e.response?.data}');
      }
      rethrow;
    }
    await loadAlbums();
  }

  Future<void> deleteAlbum(int id) async {
    final dio = await _authedDio();
    await AlbumRepository(ApiClient(dio)).deleteAlbum(id);
    state.whenData((response) {
      state = AsyncData(AlbumsResponse(
        success: response.success,
        albums: response.albums.where((a) => a.id != id).toList(),
        publicAlbums: response.publicAlbums,
        purchasedAlbums: response.purchasedAlbums,
        canCreateAlbum: response.canCreateAlbum,
      ));
    });
  }



  Future<void> purchaseAlbum(int albumId) async {
    final dio = await _authedDio();
    await AlbumRepository(ApiClient(dio)).purchaseAlbum({'album_id': albumId});
    await loadAlbums();
  }

  void deleteLocalAlbums(int albumId) {
    state.whenData((response) {
      state = AsyncData(AlbumsResponse(
        success: response.success,
        albums: response.albums.where((a) => a.id != albumId).toList(),
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