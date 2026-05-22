import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/comment_response.dart';
import '../repositories/comment_repository.dart';

// ── State ──────────────────────────────────────────────────────────────────

class PostCommentState {
  final bool isPosting;
  final CommentData? postedComment;
  final String? error;

  const PostCommentState({
    this.isPosting = false,
    this.postedComment,
    this.error,
  });

  PostCommentState copyWith({
    bool? isPosting,
    CommentData? postedComment,
    String? error,
    bool clearError = false,
    bool clearComment = false,
  }) {
    return PostCommentState(
      isPosting: isPosting ?? this.isPosting,
      postedComment: clearComment ? null : (postedComment ?? this.postedComment),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  return CommentRepository(dio);
});

// One notifier per post (keyed by postId)
final postCommentProvider =
StateNotifierProvider.family<PostCommentNotifier, PostCommentState, int>(
      (ref, postId) {
    final repo = ref.read(commentRepositoryProvider);
    return PostCommentNotifier(repo, postId);
  },
);

// ── Notifier ───────────────────────────────────────────────────────────────

class PostCommentNotifier extends StateNotifier<PostCommentState> {
  final CommentRepository _repo;
  final int postId;

  PostCommentNotifier(this._repo, this.postId)
      : super(const PostCommentState());

  Future<CommentData?> postComment({
    required String content,
    int? parentId,
  }) async {
    if (content.trim().isEmpty) {
      state = state.copyWith(error: 'Comment cannot be empty');
      return null;
    }

    state = state.copyWith(
      isPosting: true,
      clearError: true,
      clearComment: true,
    );

    try {
      final comment = await _repo.postComment(
        postId: postId,
        content: content.trim(),
        parentId: parentId,
      );
      state = state.copyWith(isPosting: false, postedComment: comment);
      return comment;
    } catch (e) {
      state = state.copyWith(
        isPosting: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  void clearState() {
    state = state.copyWith(clearError: true, clearComment: true);
  }
}