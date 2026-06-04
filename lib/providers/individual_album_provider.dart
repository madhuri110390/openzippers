import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/individual_album_model.dart';
import '../repositories/individual_album_repository.dart';

// ── Repository provider ──────────────────────────────────────────
final individualAlbumRepositoryProvider = Provider<IndividualAlbumRepository>(
      (ref) => AlbumRepository(),
);

// ── State class ──────────────────────────────────────────────────
class IndividualAlbumState {
  final List<IndividualAlbumModel> myAlbums;
  final List<IndividualAlbumModel> publicAlbums;
  final List<IndividualAlbumModel> purchasedAlbums;
  final bool isLoadingMy;
  final bool isLoadingPublic;
  final bool isLoadingPurchased;
  final String? error;

  const IndividualAlbumState({
    this.myAlbums = const [],
    this.publicAlbums = const [],
    this.purchasedAlbums = const [],
    this.isLoadingMy = false,
    this.isLoadingPublic = false,
    this.isLoadingPurchased = false,
    this.error,
  });

  IndividualAlbumState copyWith({
    List<IndividualAlbumModel>? myAlbums,
    List<IndividualAlbumModel>? publicAlbums,
    List<IndividualAlbumModel>? purchasedAlbums,
    bool? isLoadingMy,
    bool? isLoadingPublic,
    bool? isLoadingPurchased,
    String? error,
  }) =>
      IndividualAlbumState(
        myAlbums: myAlbums ?? this.myAlbums,
        publicAlbums: publicAlbums ?? this.publicAlbums,
        purchasedAlbums: purchasedAlbums ?? this.purchasedAlbums,
        isLoadingMy: isLoadingMy ?? this.isLoadingMy,
        isLoadingPublic: isLoadingPublic ?? this.isLoadingPublic,
        isLoadingPurchased: isLoadingPurchased ?? this.isLoadingPurchased,
        error: error,
      );
}

// ── ViewModel ────────────────────────────────────────────────────
class IndividualAlbumViewModel extends StateNotifier<IndividualAlbumState> {
  final IndividualAlbumRepository _repository;

  IndividualAlbumViewModel(this._repository) : super(const IndividualAlbumState());

  Future<void> loadMyAlbums(int id) async {
    state = state.copyWith(isLoadingMy: true, error: null);
    final result = await _repository.getMyAlbums(id);
    switch (result) {
      case AlbumSuccess<List<IndividualAlbumModel>>():
        state = state.copyWith(myAlbums: result.data, isLoadingMy: false);
      case AlbumFailure<List<IndividualAlbumModel>>():
        state = state.copyWith(isLoadingMy: false, error: result.message);
    }
  }

  Future<void> loadPublicAlbums(int id) async {
    state = state.copyWith(isLoadingPublic: true, error: null);
    final result = await _repository.getPublicAlbums(id);
    switch (result) {
      case AlbumSuccess<List<IndividualAlbumModel>>():
        state = state.copyWith(publicAlbums: result.data, isLoadingPublic: false);
      case AlbumFailure<List<IndividualAlbumModel>>():
        state = state.copyWith(isLoadingPublic: false, error: result.message);
    }
  }

  Future<void> loadPurchasedAlbums(int id) async {
    state = state.copyWith(isLoadingPurchased: true, error: null);
    final result = await _repository.getPurchasedAlbums(id);
    switch (result) {
      case AlbumSuccess<List<IndividualAlbumModel>>():
        state = state.copyWith(purchasedAlbums: result.data, isLoadingPurchased: false);
      case AlbumFailure<List<IndividualAlbumModel>>():
        state = state.copyWith(isLoadingPurchased: false, error: result.message);
    }
  }

  Future<void> loadAll(int id) async {
    await Future.wait([
      loadMyAlbums(id),
      loadPublicAlbums(id),
      loadPurchasedAlbums(id),
    ]);
  }

  void deleteLocalAlbum(int albumId) {
    state = state.copyWith(
      myAlbums: state.myAlbums.where((a) => a.id != albumId).toList(),
    );
  }
}

// ── Exposed provider ─────────────────────────────────────────────
final individualAlbumViewModelProvider =
StateNotifierProvider<IndividualAlbumViewModel, IndividualAlbumState>(
      (ref) => IndividualAlbumViewModel(ref.read(individualAlbumRepositoryProvider)),
);