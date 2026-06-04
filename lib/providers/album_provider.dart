import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/album_response.dart';
import '../repositories/album_repository.dart';
import '../viewmodels/album_viewmodel.dart';
import 'api_client_provider.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepository(
    ref.read(apiClientProvider),
  );
});
final albumViewModelProvider =
StateNotifierProvider<AlbumViewModel,
    AsyncValue<AlbumsResponse>>((ref) {
  return AlbumViewModel(
    ref.read(albumRepositoryProvider),
  );
});