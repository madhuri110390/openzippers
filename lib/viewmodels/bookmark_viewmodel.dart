import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/bookmark_repository.dart';

// State: map of postId -> isBookmarked
class BookmarkState {
  final Map<int, bool> bookmarks; // postId -> isBookmarked
  final int? loadingPostId;       // which post is currently toggling
  final String? error;

  const BookmarkState({
    this.bookmarks = const {},
    this.loadingPostId,
    this.error,
  });

  BookmarkState copyWith({
    Map<int, bool>? bookmarks,
    int? loadingPostId,
    bool clearLoading = false,
    String? error,
    bool clearError = false,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      loadingPostId: clearLoading ? null : (loadingPostId ?? this.loadingPostId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BookmarkViewModel extends StateNotifier<BookmarkState> {
  final BookmarkRepository _repository;

  BookmarkViewModel(this._repository) : super(const BookmarkState());

  Future<void> toggleBookmark(int postId) async {
    // prevent double-tap
    if (state.loadingPostId == postId) return;

    state = state.copyWith(loadingPostId: postId, clearError: true);

    try {
      final response = await _repository.toggleBookmark(postId);

      final updatedBookmarks = Map<int, bool>.from(state.bookmarks);
      updatedBookmarks[postId] = response.isBookmarked;

      state = state.copyWith(
        bookmarks: updatedBookmarks,
        clearLoading: true,
      );
    } catch (e) {
      state = state.copyWith(
        clearLoading: true,
        error: e.toString(),
      );
    }
  }

  bool isBookmarked(int postId) => state.bookmarks[postId] ?? false;
}