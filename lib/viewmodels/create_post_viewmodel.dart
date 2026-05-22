import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_models.dart';
import '../repositories/feed_repository.dart'; // ← merged: was post_repository.dart

// ─── Types ───────────────────────────────────────────────────────────────────

enum PostType { post, video, song, literature }

/// Sentinel so `copyWith` can tell "field omitted" from "field set to null".
const Object _sentinel = Object();

// ─── State ───────────────────────────────────────────────────────────────────

class CreatePostState {
  final bool isLoading;
  final String? error;
  final PostData? createdPost;

  // Form fields
  final String title;
  final String body;
  final String languageId;
  final String price;
  final String fansStatus;
  final String? genreId;
  final PostType postType;

  // Selected media files
  final File? selectedImage;
  final File? selectedVideo;
  final File? selectedSong;
  final File? selectedLiterature;
  final File? selectedCoverImage;

  const CreatePostState({
    this.isLoading = false,
    this.error,
    this.createdPost,
    this.title = '',
    this.body = '',
    this.languageId = '1',
    this.price = '0',
    this.fansStatus = '1',
    this.genreId,
    this.postType = PostType.post,
    this.selectedImage,
    this.selectedVideo,
    this.selectedSong,
    this.selectedLiterature,
    this.selectedCoverImage,
  });

  CreatePostState copyWith({
    bool? isLoading,
    String? error,
    String? title,
    String? body,
    String? languageId,
    String? price,
    String? fansStatus,
    String? genreId,
    PostType? postType,
    Object? selectedImage = _sentinel,
    Object? selectedVideo = _sentinel,
    Object? selectedSong = _sentinel,
    Object? selectedLiterature = _sentinel,
    Object? selectedCoverImage = _sentinel,
    bool clearError = false,
  }) {
    return CreatePostState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      title: title ?? this.title,
      body: body ?? this.body,
      languageId: languageId ?? this.languageId,
      price: price ?? this.price,
      fansStatus: fansStatus ?? this.fansStatus,
      genreId: genreId ?? this.genreId,
      postType: postType ?? this.postType,
      selectedImage: identical(selectedImage, _sentinel)
          ? this.selectedImage
          : selectedImage as File?,
      selectedVideo: identical(selectedVideo, _sentinel)
          ? this.selectedVideo
          : selectedVideo as File?,
      selectedSong: identical(selectedSong, _sentinel)
          ? this.selectedSong
          : selectedSong as File?,
      selectedLiterature: identical(selectedLiterature, _sentinel)
          ? this.selectedLiterature
          : selectedLiterature as File?,
      selectedCoverImage: identical(selectedCoverImage, _sentinel)
          ? this.selectedCoverImage
          : selectedCoverImage as File?,
    );
  }
}

// ─── ViewModel ───────────────────────────────────────────────────────────────

class CreatePostViewModel extends StateNotifier<CreatePostState> {
  final FeedRepository _repository;

  CreatePostViewModel(this._repository) : super(const CreatePostState());

  // ── Setters ──────────────────────────────────────────────────────────────

  void setTitle(String v) => state = state.copyWith(title: v);
  void setBody(String v) => state = state.copyWith(body: v);
  void setLanguageId(String v) => state = state.copyWith(languageId: v);
  void setPrice(String v) => state = state.copyWith(price: v);
  void setFansStatus(String v) => state = state.copyWith(fansStatus: v);
  void setGenreId(String v) => state = state.copyWith(genreId: v);
  void setPostType(PostType type) => state = state.copyWith(postType: type);

  void setSelectedImage(File? file) =>
      state = state.copyWith(selectedImage: file);

  void setSelectedVideo(File? file) =>
      state = state.copyWith(selectedVideo: file);

  void setSelectedSong(File? file) =>
      state = state.copyWith(selectedSong: file);

  void setSelectedLiterature(File? file) =>
      state = state.copyWith(selectedLiterature: file);

  void setSelectedCoverImage(File? file) =>
      state = state.copyWith(selectedCoverImage: file);

  // ── Create Post ──────────────────────────────────────────────────────────

  Future<bool> createPost() async {
    state = state.copyWith(isLoading: true, clearError: true);

    debugPrint('=== createPost called ===');
    debugPrint('postType: ${state.postType}');
    debugPrint('title: ${state.title}');
    debugPrint('languageId: ${state.languageId}');
    debugPrint('image: ${state.selectedImage?.path}');

    try {
      final double priceValue = double.tryParse(state.price) ?? 0;
      if (priceValue > 0) {
        state = state.copyWith(
          isLoading: false,
          error:
          'You must be verified to create paid content. Please complete your verification process first.',
        );
        return false;
      }

      final postTypeStr = _postTypeToApi(state.postType);

      // FeedRepository.createPost returns Either<String, Map<String, dynamic>>
      final result = await _repository.createPost(
        postType: postTypeStr,
        title: state.title,
        body: state.body,
        languageId: state.languageId,
        price: state.price,
        fansStatus: state.fansStatus,
        genreId: state.genreId,
        coverImage: state.selectedCoverImage,
        image: state.postType == PostType.post ? state.selectedImage : null,
        video: state.postType == PostType.video ? state.selectedVideo : null,
        song: state.postType == PostType.song ? state.selectedSong : null,
        literature: state.postType == PostType.literature
            ? state.selectedLiterature
            : null,
      );

      return result.fold(
        // ── Left: error string from the repository ─────────────────────────
            (errorMsg) {
          debugPrint('createPost failed: $errorMsg');
          state = state.copyWith(isLoading: false, error: errorMsg);
          return false;
        },
        // ── Right: response map from the API ───────────────────────────────
            (response) {
          final success = response['success'] == true ||
              response['success'] == 1 ||
              response['success'] == '1';

          if (success) {
            debugPrint('createPost success: ${response['message'] ?? ''}');
            state = state.copyWith(isLoading: false, clearError: true);
            return true;
          } else {
            // API returned 200 but with success=false — surface the message.
            final msg = _extractErrorMessage(response) ??
                'Failed to create post';
            debugPrint('createPost server-rejected: $msg');
            state = state.copyWith(isLoading: false, error: msg);
            return false;
          }
        },
      );
    } on DioException catch (e) {
      // FeedRepository normally converts DioExceptions to Left(...) strings,
      // but keep this branch defensively in case something rethrows.
      final errorMsg = _extractDioError(e);
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    } catch (e, st) {
      debugPrint('createPost unexpected error: $e\n$st');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void resetState() => state = const CreatePostState();

  // ── Helpers ──────────────────────────────────────────────────────────────

  String? _extractErrorMessage(Map<String, dynamic> response) {
    // Common shapes: { message: "..." } or { errors: { field: ["msg"] } }
    final msg = response['message'];
    if (msg is String && msg.isNotEmpty) return msg;

    final errors = response['errors'];
    if (errors is Map && errors.isNotEmpty) {
      return errors.entries
          .map((e) =>
      '${e.key}: ${e.value is List ? (e.value as List).join(', ') : e.value}')
          .join('\n');
    }
    return null;
  }

  String _extractDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.entries
            .map((e) =>
        '${e.key}: ${e.value is List ? (e.value as List).join(', ') : e.value}')
            .join('\n');
      }
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return e.message ?? e.toString();
  }
}

// ─── Post-type → API mapping ─────────────────────────────────────────────────

String _postTypeToApi(PostType type) {
  switch (type) {
    case PostType.post:
      return 'post';
    case PostType.song:
      return 'audio';
    case PostType.video:
      return 'video';
    case PostType.literature:
      return 'literature';
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final createPostViewModelProvider =
StateNotifierProvider<CreatePostViewModel, CreatePostState>((ref) {
  // Uses the merged feedRepositoryProvider (postRepositoryProvider is gone).
  return CreatePostViewModel(ref.watch(feedRepositoryProvider));
});