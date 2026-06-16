import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed_response.dart';
import '../models/presence_model.dart';
import '../models/register_response.dart';
import '../network/api_client.dart';
import '../providers/api_client_provider.dart';
import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// ABSTRACT REPOSITORY
// ═══════════════════════════════════════════════════════════

abstract class FeedRepository {
  Future<Either<String, FeedResponse>> getFeed({
    int page,
    String tab,
  });

  Future<Either<String, PostModel>> toggleLike(PostModel post);

  Future<Either<String, PostModel>> toggleBookmark(PostModel post);

  Future<Either<String, PresenceModel>> getPresence();

  /// Create a new post (Song / Video / Literature / Image) via multipart upload.
  Future<Either<String, Map<String, dynamic>>> createPost({
    required String postType,
    required String title,
    required String body,
    required String languageId,
    required String price,
    required String fansStatus,
    String? genreId,
    File? coverImage,
    File? image,
    File? video,
    File? song,
    File? literature,
  });
}

// ═══════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════

// No change needed here — dioProvider is now authenticated
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final dio = ref.watch(dioProvider); // ← now has token interceptor
  return FeedRepositoryImpl(api, dio);
});

// ═══════════════════════════════════════════════════════════
// IMPLEMENTATION
// ═══════════════════════════════════════════════════════════

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._api, this._dio);

  final ApiClient _api;
  final Dio _dio;

  // ── Feed ────────────────────────────────────────────────

  @override
  Future<Either<String, FeedResponse>> getFeed({
    int page = 1,
    String tab = 'main',
  }) async {
    try {
      final response = await _api.getFeed(page: page, tab: tab);
      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left('Unexpected error: $e');
    }
  }

  // ── Like ────────────────────────────────────────────────

  @override
  Future<Either<String, PostModel>> toggleLike(PostModel post) async {
    try {
      final updatedPost = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked
            ? (post.likesCount - 1).clamp(0, 999999)
            : post.likesCount + 1,
      );

      return Right(updatedPost);
    } catch (e) {
      return Left('Unexpected error: $e');
    }
  }

  // ── Bookmark ───────────────────────────────────────────

  @override
  Future<Either<String, PostModel>> toggleBookmark(PostModel post) async {
    try {
      final updatedPost = post.copyWith(
        isBookmarked: !post.isBookmarked,
      );

      return Right(updatedPost);
    } catch (e) {
      return Left('Unexpected error: $e');
    }
  }

  // ── Presence ───────────────────────────────────────────

  @override
  Future<Either<String, PresenceModel>> getPresence() async {
    try {
      final response = await _api.getPresence();
      return Right(response);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left('Unexpected error: $e');
    }
  }

  // ── Create Post (merged from PostRepository) ──────────

  @override
  Future<Either<String, Map<String, dynamic>>> createPost({
    required String postType,
    required String title,
    required String body,
    required String languageId,
    required String price,
    required String fansStatus,
    String? genreId,
    File? coverImage,
    File? image,
    File? video,
    File? song,
    File? literature,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('post_type', postType));
    formData.fields.add(MapEntry('title', title));
    formData.fields.add(MapEntry('body', body));
    formData.fields.add(MapEntry('language_id', languageId));
    formData.fields.add(MapEntry('price', price));
    formData.fields.add(MapEntry('fans_status', fansStatus));

    if (genreId != null) {
      formData.fields.add(MapEntry('genre_id', genreId));
    }
    if (coverImage != null) {
      formData.files.add(MapEntry(
        'image',
        MultipartFile.fromFileSync(
          coverImage.path,
          filename: coverImage.path.split('/').last,
        ),
      ));
    }
    if (image != null) {
      formData.files.add(MapEntry(
        'image',
        MultipartFile.fromFileSync(
          image.path,
          filename: image.path.split('/').last,
        ),
      ));
    }
    if (video != null) {
      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromFileSync(
          video.path,
          filename: video.path.split('/').last,
        ),
      ));
    }
    if (song != null) {
      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromFileSync(
          song.path,
          filename: song.path.split('/').last,
        ),
      ));
    }
    if (literature != null) {
      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromFileSync(
          literature.path,
          filename: literature.path.split('/').last,
        ),
      ));
    }

    debugPrint('=== HITTING API (createPost) ===');
    debugPrint(
      'Fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join(', ')}',
    );
    debugPrint(
      'Files: ${formData.files.map((e) => '${e.key}=${e.value.filename}').join(', ')}',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      debugPrint('=== TOKEN: $token ===');

      final response = await _dio.post(
        'https://openzippers.com/api/v1/zippfans/feed',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'openzippers-skip-browser-warning': 'true',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint('=== RESPONSE STATUS: ${response.statusCode} ===');
      debugPrint('=== RESPONSE DATA: ${response.data} ===');

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('=== DIO ERROR (createPost) ===');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      return Left(_handleDioError(e));
    } catch (e) {
      debugPrint('=== UNKNOWN ERROR TYPE: ${e.runtimeType} ===');
      debugPrint('=== UNKNOWN ERROR: $e ===');
      return Left('Unexpected error: $e');
    }
  }

  // ── Error Handler ──────────────────────────────────────

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';

      case DioExceptionType.connectionError:
        return 'No internet connection.';

      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final msg = e.response?.data?['message'];

        if (code == 401) return 'Session expired. Please log in again.';
        if (code == 403) return 'Access denied.';
        if (code == 404) return 'Content not found.';
        if (code == 422) return msg ?? 'Validation error.';
        if (code != null && code >= 500) {
          return 'Server error. Try again later.';
        }

        return msg ?? 'Something went wrong (code: $code).';

      default:
        return e.message ?? 'Unknown error.';
    }
  }
}