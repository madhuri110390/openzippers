import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

class PostRepository {
  final Dio _dio;

  PostRepository(this._dio);

  Future<Map<String, dynamic>> createPost({
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
      formData.files.add(MapEntry('image',
          MultipartFile.fromFileSync(coverImage.path,
              filename: coverImage.path.split('/').last)));
    }
    if (image != null) {
      formData.files.add(MapEntry('image',
          MultipartFile.fromFileSync(image.path,
              filename: image.path
                  .split('/')
                  .last)));
    }
    if (video != null) {
      formData.files.add(MapEntry('file',
          MultipartFile.fromFileSync(video.path,
              filename: video.path
                  .split('/')
                  .last)));
    }
    if (song != null) {
      formData.files.add(MapEntry('file',
          MultipartFile.fromFileSync(song.path,
              filename: song.path
                  .split('/')
                  .last)));
    }
    if (literature != null) {
      formData.files.add(MapEntry('file',
          MultipartFile.fromFileSync(literature.path,
              filename: literature.path
                  .split('/')
                  .last)));
    }

    debugPrint('=== HITTING API ===');
    debugPrint('Fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join(', ')}');
    debugPrint('Files: ${formData.files.map((e) => '${e.key}=${e.value.filename}').join(', ')}');
    debugPrint('=== SENDING REQUEST NOW ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      debugPrint('=== TOKEN: $token ===');

      final response = await _dio.post(
       //'https://openzippers.com/api/v1/zippfans/feed',
        'https://openzippers.com/api/v1/zippfans/posts',
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
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('=== DIO ERROR ===');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('=== UNKNOWN ERROR TYPE: ${e.runtimeType} ===');
      debugPrint('=== UNKNOWN ERROR: $e ===');
      rethrow;
    }
  }
}

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PostRepository(dio);
});