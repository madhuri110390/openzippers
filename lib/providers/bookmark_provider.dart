import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookmark_response.dart';
import '../network/api_client.dart';
import '../viewmodels/register_view_model.dart';

class BookmarkState {
  final bool isLoading;
  final String? message;
  final bool? isBookmarked;
  const BookmarkState({this.isLoading = false, this.message, this.isBookmarked});
}

class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final ApiClient _api;

  BookmarkNotifier(this._api) : super(const BookmarkState());

  Future<bool?> toggleBookmark(int postId) async {
    state = const BookmarkState(isLoading: true);
    try {
      final res = await _api.toggleBookmark({'post_id': postId});
      state = BookmarkState(
        isLoading: false,
        isBookmarked: res.isBookmarked,
        message: res.isBookmarked ? 'Post bookmarked' : 'Bookmark removed',
      );
      return res.isBookmarked;
    } catch (e) {
      state = BookmarkState(isLoading: false, message: 'Failed: $e');
      return null;
    }
  }
}

final bookmarkProvider =
StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) {
  final dio = ref.watch(dioProvider);
  return BookmarkNotifier(ApiClient(dio));
});