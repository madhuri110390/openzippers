import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/post_repository.dart';
import '../models/post_models.dart';

// ─── State ───────────────────────────────────────────────────────────────────
enum PostType { post, video, song, literature }
const Object _sentinel = Object();
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

// Special wrapper to distinguish "not passed" from "explicitly null"
  CreatePostState copyWith({
    bool? isLoading,
    String? error,
    String? title,
    String? body,
    String? languageId,
    String? price,
    String? fansStatus,
    String? genreId,
    File? coverImage,
    File? image,
    PostType? postType,
    Object? selectedImage  = _sentinel,   // ← use sentinel
    Object? selectedVideo  = _sentinel,
    Object? selectedSong   = _sentinel,
    Object? selectedLiterature = _sentinel,
    Object? selectedCoverImage = _sentinel,
    bool clearError = false,
  }) {
    return CreatePostState(
      isLoading:          isLoading   ?? this.isLoading,
      error:              clearError  ? null : (error ?? this.error),
      title:              title       ?? this.title,
      body:               body        ?? this.body,
      languageId:         languageId  ?? this.languageId,
      price:              price       ?? this.price,
      fansStatus:         fansStatus  ?? this.fansStatus,
      genreId: genreId ?? this.genreId,
      postType:           postType    ?? this.postType,
      selectedImage:      selectedImage      == _sentinel ? this.selectedImage      : selectedImage as File?,
      selectedVideo:      selectedVideo      == _sentinel ? this.selectedVideo      : selectedVideo as File?,
      selectedSong:       selectedSong       == _sentinel ? this.selectedSong       : selectedSong as File?,
      selectedLiterature: selectedLiterature == _sentinel ? this.selectedLiterature : selectedLiterature as File?,
      selectedCoverImage: selectedCoverImage == _sentinel ? this.selectedCoverImage : selectedCoverImage as File?,
    );
  }
}

// ─── ViewModel ───────────────────────────────────────────────────────────────
class CreatePostViewModel extends StateNotifier<CreatePostState> {
  final PostRepository _repository;

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
    state = state.copyWith(isLoading: true, error: null);
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
          error: 'You must be verified to create paid content. Please complete your verification process first.',
        );
        return false;
      }
      final postTypeStr = _postTypeToApi(state.postType);

      final response = await _repository.createPost(
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

      final success = response['success'] == true ||
          response['success'] == 1 ||
          response['success'] == '1';

      if (success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message']?.toString() ?? 'Failed to create post',
        );
        return false;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String errorMsg;
      if (data is Map) {
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          errorMsg = errors.entries
              .map((e) => '${e.key}: ${e.value is List ? (e.value as List).join(', ') : e.value}')
              .join('\n');
        } else {
          errorMsg = data['message']?.toString() ?? e.toString();
        }
      } else {
        errorMsg = data?.toString() ?? e.toString();
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  void resetState() => state = const CreatePostState();
}
String _postTypeToApi(PostType type) {
  switch (type) {
    case PostType.post:       return 'post';
    case PostType.song:       return 'audio';
    case PostType.video:      return 'video';
    case PostType.literature: return 'literature';
  }
}
// ─── Provider ────────────────────────────────────────────────────────────────
final createPostViewModelProvider =
StateNotifierProvider<CreatePostViewModel, CreatePostState>((ref) {
  return CreatePostViewModel(ref.watch(postRepositoryProvider));
});