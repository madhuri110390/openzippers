import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/like_response.dart';
import '../providers/api_client_provider.dart';
import '../viewmodels/register_view_model.dart'; // your existing apiClientProvider

class LikeState {
  final bool isLiked;
  final int likesCount;
  const LikeState({required this.isLiked, required this.likesCount});
  LikeState copyWith({bool? isLiked, int? likesCount}) =>
      LikeState(isLiked: isLiked ?? this.isLiked, likesCount: likesCount ?? this.likesCount);
}

class LikeNotifier extends StateNotifier<LikeState> {
  final Ref _ref;
  final int postId;

  LikeNotifier(this._ref, {required this.postId, required bool isLiked, required int likesCount})
      : super(LikeState(isLiked: isLiked, likesCount: likesCount));

  void init(bool isLiked, int likesCount) {
    state = LikeState(isLiked: isLiked, likesCount: likesCount);
  }

  Future<void> toggleLike() async {
    final prev = state;
    // Optimistic update
    state = state.copyWith(
      isLiked: !state.isLiked,
      likesCount: state.isLiked ? state.likesCount - 1 : state.likesCount + 1,
    );
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.toggleLike({"post_id": postId});
      state = LikeState(isLiked: res.data.isLiked, likesCount: res.data.likesCount);
    } catch (_) {
      state = prev; // revert on error
    }
  }
}

// postId as key = one shared instance across ALL screens
final likeProvider = StateNotifierProvider.family<LikeNotifier, LikeState, int>(
      (ref, postId) => LikeNotifier(ref, postId: postId, isLiked: false, likesCount: 0),
);