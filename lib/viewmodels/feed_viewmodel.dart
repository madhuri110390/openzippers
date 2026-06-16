import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_response.dart';
import '../models/presence_model.dart';
import '../models/register_response.dart';
import '../repositories/feed_repository.dart';

// ══════════════════════════════════════════════════════════════════════════════
// STATUS
// ══════════════════════════════════════════════════════════════════════════════

enum FeedStatus {
  initial,
  loading,
  loaded,
  refreshing,
  loadingMore,
  error,
}

// ══════════════════════════════════════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════════════════════════════════════

class FeedState {
  final FeedStatus status;
  final List<PostModel> posts;
  final PaginationMeta? pagination;
  final String? errorMessage;
  final PresenceModel? userProfile;

  const FeedState({
    required this.status,
    this.posts = const [],
    this.pagination,
    this.errorMessage,
    this.userProfile,
  });

  factory FeedState.initial() {
    return const FeedState(
      status: FeedStatus.initial,
    );
  }

  FeedState copyWith({
    FeedStatus? status,
    List<PostModel>? posts,
    PaginationMeta? pagination,
    String? errorMessage,
    PresenceModel? userProfile,
  }) {
    return FeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      pagination: pagination ?? this.pagination,
      errorMessage: errorMessage,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  bool get isInitial => status == FeedStatus.initial;
  bool get isLoading => status == FeedStatus.loading;
  bool get isRefreshing => status == FeedStatus.refreshing;
  bool get isLoadingMore => status == FeedStatus.loadingMore;
  bool get hasError => status == FeedStatus.error;
  bool get isLoaded => pagination != null;
}

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

final feedViewModelProvider =
StateNotifierProvider<FeedViewModel, FeedState>((ref) {
  return FeedViewModel(
    ref.watch(feedRepositoryProvider),
  );
});

// ══════════════════════════════════════════════════════════════════════════════
// VIEWMODEL
// ══════════════════════════════════════════════════════════════════════════════

class FeedViewModel extends StateNotifier<FeedState> {
  FeedViewModel(this._repository) : super(FeedState.initial()) {
    loadFeed();
  }

  final FeedRepository _repository;

  int _requestId = 0;

  // ───────────────────────────────────────────────────────────────────────────
  // INITIAL LOAD
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> loadFeed({String tab = 'main'}) async {
    state = state.copyWith(status: FeedStatus.loading);

    await Future.wait([
      _fetchPage(1, tab: tab),
      _fetchUser(),
    ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REFRESH
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> refresh({String tab = 'main'}) async {
    state = state.copyWith(
      status: FeedStatus.refreshing,
      errorMessage: null,
    );

    await Future.wait([
      _fetchPage(1, tab: tab),
      _fetchUser(),
    ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LOAD MORE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> loadMore({String tab = 'main'}) async {
    if (state.pagination == null) return;
    if (!state.pagination!.hasMore) return;
    if (state.isLoadingMore) return;

    state = state.copyWith(
      status: FeedStatus.loadingMore,
      errorMessage: null,
    );

    await _fetchPage(
      state.pagination!.currentPage + 1,
      append: true,
      tab: tab,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOGGLE LIKE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> toggleLike(PostModel post) async {
    final previous = post;

    _updatePost(
      post.id,
          (p) => p.copyWith(
        isLiked: !p.isLiked,
        likesCount: p.isLiked ? max(0, p.likesCount - 1) : p.likesCount + 1,
      ),
    );

    final result = await _repository.toggleLike(post);

    result.fold(
          (error) {
        _updatePost(post.id, (_) => previous);
        _setError(error);
      },
          (updated) => _updatePost(updated.id, (_) => updated),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOGGLE BOOKMARK
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> toggleBookmark(PostModel post) async {
    final previous = post;

    _updatePost(
      post.id,
          (p) => p.copyWith(isBookmarked: !p.isBookmarked),
    );

    final result = await _repository.toggleBookmark(post);

    result.fold(
          (error) {
        _updatePost(post.id, (_) => previous);
        _setError(error);
      },
          (updated) => _updatePost(updated.id, (_) => updated),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchPage(
      int page, {
        bool append = false,
        String tab = 'main',
      }) async {
    final requestId = ++_requestId;

    final result = await _repository.getFeed(page: page, tab: tab);

    if (requestId != _requestId) return;

    result.fold(
          (error) {
        state = state.copyWith(
          status: FeedStatus.error,
          errorMessage: error,
        );
      },
          (response) {
        final posts = append
            ? _mergePosts(state.posts, response.data)
            : response.data;

        state = state.copyWith(
          status: FeedStatus.loaded,
          posts: posts,
          pagination: response.pagination,
          errorMessage: null,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH USER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchUser() async {
    final result = await _repository.getPresence();

    result.fold(
          (error) {
        if (state.userProfile == null) {
          state = state.copyWith(
            status: FeedStatus.error,
            errorMessage: error,
          );
        }
      },
          (profile) {
        state = state.copyWith(userProfile: profile);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE POST
  // ═══════════════════════════════════════════════════════════════════════════

  void _updatePost(int postId, PostModel Function(PostModel) updater) {
    state = state.copyWith(
      posts: state.posts
          .map((p) => p.id == postId ? updater(p) : p)
          .toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MERGE POSTS
  // ═══════════════════════════════════════════════════════════════════════════

  List<PostModel> _mergePosts(
      List<PostModel> oldPosts,
      List<PostModel> newPosts,
      ) {
    final merged = [...oldPosts, ...newPosts];
    return {for (final p in merged) p.id: p}.values.toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR
  // ═══════════════════════════════════════════════════════════════════════════

  void _setError(String message) {
    state = state.copyWith(
      status: FeedStatus.error,
      errorMessage: message,
    );
  }
}