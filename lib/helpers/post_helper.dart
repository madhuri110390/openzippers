import 'dart:convert';
import 'package:flutter/foundation.dart';

class PostHelper {
  static String getPostType(Map<String, dynamic> post) {
    final String postType =
        (post['post_type'] ?? post['type'] ?? '').toString().toLowerCase();
    final String filePath =
        (post['file_path'] ?? post['filePath'] ?? '').toString().toLowerCase();

    // Also check metadata extension if available
    String metadataExt = '';
    if (post['metadata'] != null) {
      try {
        final metadata = post['metadata'] is String
            ? jsonDecode(post['metadata'])
            : post['metadata'];
        if (metadata is Map) {
          metadataExt = (metadata['file_info']?['extension'] ?? '')
              .toString()
              .toLowerCase();
          // Fallback if content_type is present in metadata
          if (metadataExt.isEmpty && metadata['content_type'] != null) {
            final contentType = metadata['content_type'].toString().toLowerCase();
            if (contentType == 'audio') metadataExt = 'mp3';
            if (contentType == 'video') metadataExt = 'mp4';
            if (contentType == 'document' || contentType == 'pdf') metadataExt = 'pdf';
            if (contentType == 'image') metadataExt = 'jpg';
          }
        }
      } catch (e) {
        debugPrint("Error parsing metadata for type detection: $e");
      }
    }

    if (postType == 'audio' ||
        filePath.endsWith('.mp3') ||
        metadataExt == 'mp3') {
      return 'Song';
    }
    if (postType == 'video' ||
        filePath.endsWith('.mp4') ||
        metadataExt == 'mp4') {
      return 'Video';
    }
    if (postType == 'literature' ||
        filePath.endsWith('.pdf') ||
        metadataExt == 'pdf') {
      return 'Literature';
    }

    // Default to Image if it's 'post' or has image extensions
    if (postType == 'post' ||
        postType == 'image' ||
        filePath.endsWith('.jpg') ||
        filePath.endsWith('.jpeg') ||
        filePath.endsWith('.png') ||
        filePath.endsWith('.webp') ||
        metadataExt == 'jpg' ||
        metadataExt == 'jpeg' ||
        metadataExt == 'png' ||
        metadataExt == 'webp') {
      return 'Image';
    }

    // Fallback to existing type or default to Image
    return post['type'] ?? 'Image';
  }

  static Map<String, dynamic> normalizePost(Map<String, dynamic> post) {
    final String detectedType = getPostType(post);

    // Ensure we have a valid image URL for thumbnails
    final String image = post['locked_image_url'] ?? post['image_url'] ?? post['image'] ?? '';
    final String covers = post['cover_url'] ?? post['covers'] ?? '';
    final String filePath = post['file_url'] ?? post['file_path'] ?? post['filePath'] ?? '';
    final String coverPath = post['cover_url'] ?? post['cover_path'] ?? post['coverPath'] ?? '';
    
    final Map<String, dynamic>? user = post['user'] is Map<String, dynamic> ? post['user'] : null;

    return {
      'id': post['id'] ?? 0,
      'userId': post['user_id'] ?? post['userId'] ?? user?['id'] ?? 0,
      'type': detectedType,
      'title': post['title'] ?? post['name'] ?? '',
      'price': post['price']?.toString() ?? '0',
      'content': post['content'] ?? post['description'] ?? post['body'] ?? '',
      'author': post['author'] ?? user?['name'] ?? 'Unknown',
      'authorUsername': post['authorUsername'] ?? user?['username'] ?? '',
      'authorAvatar': post['authorAvatar'] ?? user?['avatar_url'] ?? user?['avatar'] ?? '',
      'is_user_post': post['is_user_post'] ?? ((post['author'] ?? user?['name']) == 'You'),
      'date': post['created_at'] != null
          ? DateTime.tryParse(post['created_at']) ?? DateTime.now()
          : DateTime.now(),
      'likeCount': post['likes_count'] ?? post['likeCount'] ?? 0,
      'ratingCount': post['ratings_count'] ?? post['ratingCount'] ?? 0,
      'commentsCount': post['comments_count'] ?? post['commentsCount'] ?? 0,
      'comments': post['comments'] ?? [],
      'image': image,
      'imageUrl': image,
      'covers': covers,
      // Ensure filePath and coverPath fall back to image/covers if they are likely to be URLs
      'filePath': filePath.isNotEmpty ? filePath : (detectedType == 'Image' ? image : ''),
      'coverPath': coverPath.isNotEmpty ? coverPath : (covers.isNotEmpty ? covers : image),
      'previewPath': post['preview_url'] ?? post['preview_path'] ?? post['previewPath'] ?? '',
      'zippfansStatus': post['zippfans_status'] ?? post['zippfansStatus'] ?? 0,
    };
  }
}
