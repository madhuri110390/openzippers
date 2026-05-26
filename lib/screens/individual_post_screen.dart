import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_filex/open_filex.dart';
import '../models/mock_data.dart';
import '../widgets/comment_section.dart';
import '../widgets/media_player_widgets.dart';
import 'package:http/http.dart' as http;
import '../helpers/translations.dart';
import '../helpers/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rating_provider.dart';
import '../models/rating_response.dart';
import '../widgets/rating_dialog.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';

class IndividualPostScreen extends ConsumerStatefulWidget {
  final int postId;
  final MockUser currentUser;
  final List<MockUser> users;
  final Map<String, dynamic>? initialPostData;
  final Function(Map<String, dynamic>, String, {dynamic extraData}) onPostAction;
  final Function(MockUser)? onUserTap;
  final List<Map<String, dynamic>> allPosts;
  final Function(MockUser, bool) getDisplayStats;
  final Function(MockUser, String)? onUserAction;
  final List<Map<String, dynamic>> readPosts;
  final List<Map<String, dynamic>> commentedPosts;
  final List<Map<String, dynamic>> watchedPosts;
  final ValueNotifier<List<Map<String, dynamic>>>? cartItemsNotifier;
  final String searchQuery;
  final String authToken;
  final bool initialExpandComments;
  final String? initialCommentAuthor;
  final String? initialCommentText;
  final int? initialCommentId;

  const IndividualPostScreen({
    super.key,
    required this.postId,
    required this.currentUser,
    required this.authToken,
    required this.users,
    this.initialPostData,
    required this.onPostAction,
    this.onUserTap,
    required this.allPosts,
    required this.getDisplayStats,
    this.onUserAction,
    this.readPosts = const [],
    this.commentedPosts = const [],
    this.watchedPosts = const [],
    this.cartItemsNotifier,
    this.searchQuery = "",
    this.initialExpandComments = false,
    this.initialCommentAuthor,
    this.initialCommentText,
    this.initialCommentId,
  });

  @override
  ConsumerState<IndividualPostScreen> createState() => _IndividualPostScreenState();
}

class _IndividualPostScreenState extends ConsumerState<IndividualPostScreen> {
  late Map<String, dynamic> _post;
  bool _notFound = false;
  final GlobalKey<CommentSectionState> _commentSectionKey = GlobalKey<CommentSectionState>();
  bool _isSubscribed = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Set<String> _likedPostIds = {};
  void _showRatingDialog(int postId, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) => RatingDialog(
        post: _post,
        onSubmit: (stars) async {
          try {
            // Update UI immediately
            if (mounted) {
              setState(() {
                _post['my_rating'] = stars;
                _post['user_rating'] = stars;

                final currentTotal =
                (_post['totalRatings'] ??
                    _post['total_ratings'] ??
                    0) as int;

                _post['totalRatings'] = currentTotal + 1;
                _post['total_ratings'] = currentTotal + 1;

                _post['averageRating'] = stars.toDouble();
                _post['average_rating'] = stars.toDouble();
              });
            }

            await ref.read(submitRatingProvider.notifier).submitRating(
              postId: postId,
              rating: stars,
            );

            ref.invalidate(ratingProvider(postId));

            if (mounted) {
              Navigator.of(dialogContext).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rating submitted!'),
                ),
              );
            }
          } catch (e, s) {
            debugPrint('RATING ERROR: $e');
            debugPrintStack(stackTrace: s);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rating failed: $e'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  bool _isFree(dynamic price) {
    if (price == null) return true;
    final p = price.toString().toLowerCase().replaceAll('\$', '').trim();
    return p == 'free' || p == '0' || p == '0.00';
  }

  bool _isOwnPost(Map<String, dynamic> post) {
    final postAuthor = post['author'];
    final currentUserName = widget.currentUser.name;
    if (postAuthor == null) return false;
    final authorStr = postAuthor.toString().trim();
    final userStr = currentUserName.toString().trim();
    if (authorStr.isEmpty || userStr.isEmpty) return false;
    return authorStr.toLowerCase() == userStr.toLowerCase();
  }

  bool _isSubscribedToAuthor(String author) {
    if (author.isEmpty) return false;
    final authorLower = author.toLowerCase().trim();
    if (authorLower == 'you') return true;

    String clean(String s) => s.replaceAll(RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false), '').replaceAll(' ', '').trim().toLowerCase();
    final targetClean = clean(author);

    try {
      if (_isSubscribed) return true;
      final userIdx = widget.users.indexWhere((u) => clean(u.name) == targetClean || clean(u.username) == targetClean);
      if (userIdx != -1) {
        return widget.users[userIdx].isSubscribed;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _checkSubscription() async {
    final authorName = _post['author']?.toString() ?? '';
    if (authorName.isEmpty) return;
    final relationships = await _dbHelper.getRelationships(widget.currentUser.username);
    String clean(String s) => s.replaceAll(RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false), '').replaceAll(' ', '').trim().toLowerCase();
    final targetClean = clean(authorName);
    bool subscribed = false;
    relationships.forEach((person, type) {
      if (clean(person) == targetClean && type == 'subscribed') {
        subscribed = true;
      }
    });
    if (mounted) {
      setState(() {
        _isSubscribed = subscribed;
      });
      debugPrint("IndividualPostScreen: Checked subscription for $authorName: $subscribed");
    }
  }

  bool _isUnlocked(Map<String, dynamic> post) {
    if (_isOwnPost(post)) return true;
    if (_isFree(post['price'])) return true;
    final author = post['author']?.toString() ?? '';
    return _isSubscribedToAuthor(author);
  }

  void _navigateToProfile(dynamic authorName) {
    if (authorName == null || authorName.toString().isEmpty) return;
    try {
      String clean(String s) => s.replaceAll(RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false), '').replaceAll(' ', '').trim().toLowerCase();
      final targetClean = clean(authorName.toString());
      final author = widget.users.firstWhere(
            (u) => clean(u.name) == targetClean || clean(u.username) == targetClean,
        orElse: () => MockUser(
          name: authorName.toString(),
          username: authorName.toString().replaceAll(' ', '').toLowerCase(),
          avatar: '',
          type: 'other',
        ),
      );
      if (widget.onUserTap != null) {
        widget.onUserTap!(author);
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              authToken: widget.authToken,
              posts: widget.allPosts.where((p) => p['author'] == author.name).toList(),
              onEditProfile: () {},
              onPostAction: widget.onPostAction,
              onUserAction: widget.onUserAction,
              followerCount: widget.getDisplayStats(author, true),
              followingCount: widget.getDisplayStats(author, false),
              subscriberCount: "0",
              users: widget.users,
              currentUser: widget.currentUser,
              user: author,
              searchQuery: widget.searchQuery,
              readPosts: widget.readPosts,
              commentedPosts: widget.commentedPosts,
              watchedPosts: widget.watchedPosts,
              cartItemsNotifier: widget.cartItemsNotifier,
              onUpdateProfile: (updatedUser) {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error finding user for profile navigation: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    if (widget.initialPostData != null) {
      _post = Map<String, dynamic>.from(widget.initialPostData!);
      // --- Image path resolution (keep your existing code) ---
      if (_post['type'] == 'Image') {
        final allImageFields = [
          _post['image'],
          _post['media'],
          _post['filePath'],
          _post['coverPath'],
          _post['cover'],
        ];
        String? foundImagePath;
        for (var field in allImageFields) {
          if (field != null && field.toString().trim().isNotEmpty) {
            foundImagePath = field.toString().trim();
            break;
          }
        }
        if (foundImagePath != null && foundImagePath.isNotEmpty) {
          _resolveImagePath(foundImagePath).then((resolvedPath) {
            if (mounted) {
              final finalPath = resolvedPath ?? foundImagePath;
              _post['image'] = finalPath;
              _post['media'] = finalPath;
              _post['filePath'] = finalPath;
              _post['coverPath'] = finalPath;
              _post['cover'] = finalPath;
              setState(() {});
            }
          });
        }
      }
      final imagePath = _post['image'] ?? _post['media'] ?? _post['filePath'] ?? _post['coverPath'] ?? _post['cover'];
      if (imagePath != null && imagePath.toString().isNotEmpty) {
        _resolveImagePath(imagePath.toString()).then((resolvedPath) {
          if (mounted) {
            final finalPath = resolvedPath ?? imagePath.toString();
            _post['image'] = finalPath;
            _post['media'] = finalPath;
            _post['filePath'] = finalPath;
            if (_post['type'] == 'Image') {
              _post['coverPath'] = finalPath;
              if (_post.containsKey('cover')) _post['cover'] = finalPath;
            }
            setState(() {});
          }
        });
      } else if (_post['type'] == 'Image') {
        final allFields = [_post['image'], _post['media'], _post['filePath'], _post['coverPath'], _post['cover']];
        final foundPath = allFields.firstWhere((field) => field != null && field.toString().trim().isNotEmpty, orElse: () => null);
        if (foundPath != null) {
          _resolveImagePath(foundPath.toString()).then((resolvedPath) {
            if (mounted) {
              final finalPath = resolvedPath ?? foundPath.toString();
              _post['image'] = finalPath;
              _post['media'] = finalPath;
              _post['filePath'] = finalPath;
              _post['coverPath'] = finalPath;
              if (_post.containsKey('cover')) _post['cover'] = finalPath;
              setState(() {});
            }
          });
        }
      }
      // --- end image resolution ---
      final isLiked = widget.readPosts.any((p) => p['id'] == _post['id']);
      if (isLiked) {
        _likedPostIds.add("${_post['title']}_${_post['author']}");
      }
    } else {
      _notFound = true;
    }
    if (widget.initialCommentAuthor != null && widget.initialCommentText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _commentSectionKey.currentState != null) {
            _commentSectionKey.currentState!.focusInput();
          }
        });
      });
    }
  }

  @override
  void didUpdateWidget(IndividualPostScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPostData != null && widget.initialPostData != oldWidget.initialPostData) {
      setState(() {
        _post = Map<String, dynamic>.from(widget.initialPostData!);
        final isLiked = widget.readPosts.any((p) => p['id'] == _post['id']);
        if (isLiked) {
          _likedPostIds.add("${_post['title']}_${_post['author']}");
        } else {
          _likedPostIds.remove("${_post['title']}_${_post['author']}");
        }
      });
    }
  }

  Future<String?> _resolveImagePath(String? path) async {
    if (path == null || path.isEmpty) return null;
    final pathStr = path.toString().trim();
    if (pathStr.isEmpty) return null;
    if (pathStr.startsWith('http://') || pathStr.startsWith('https://')) return pathStr;
    if (pathStr.startsWith('/')) {
      try {
        final file = File(pathStr);
        if (file.existsSync()) return pathStr;
      } catch (e) {}
    }
    try {
      final file = File(pathStr);
      if (file.existsSync()) return file.absolute.path;
      final absoluteFile = file.absolute;
      if (absoluteFile.existsSync()) return absoluteFile.path;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final uploadsDir = p.join(appDir.path, 'uploads');
        if (!pathStr.contains('/') && !pathStr.contains('\\')) {
          final uploadsPath = p.join(uploadsDir, pathStr);
          if (File(uploadsPath).existsSync()) return File(uploadsPath).absolute.path;
        }
        if (pathStr.contains('uploads')) {
          final fileName = p.basename(pathStr);
          final uploadsPath = p.join(uploadsDir, fileName);
          if (File(uploadsPath).existsSync()) return File(uploadsPath).absolute.path;
        }
        final fileName = p.basename(pathStr);
        if (fileName != pathStr) {
          final uploadsPath = p.join(uploadsDir, fileName);
          if (File(uploadsPath).existsSync()) return File(uploadsPath).absolute.path;
        }
      } catch (e) {}
    } catch (e) {}
    return pathStr;
  }

  ImageProvider? _getAvatar(String? authorName) {
    if (authorName == null) return null;
    try {
      String clean(String s) => s.replaceAll(RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false), '').replaceAll(' ', '').trim().toLowerCase();
      final targetClean = clean(authorName.toString());
      final user = widget.users.firstWhere(
            (u) => clean(u.name) == targetClean || clean(u.username) == targetClean,
        orElse: () => widget.users.first,
      );
      if (user.avatar.isNotEmpty) {
        if (user.avatar.startsWith('http')) return NetworkImage(user.avatar);
        return FileImage(File(user.avatar));
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _downloadPdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final filename = 'temp_pdf_${url.hashCode}.pdf';
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        return file.path;
      }
    } catch (e) {
      debugPrint("Error downloading PDF: $e");
    }
    return null;
  }

  Widget _buildPdfPreview(String path) {
    if (path.startsWith('http') || path.startsWith('https')) {
      return FutureBuilder<String?>(
        future: _downloadPdf(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return _buildLocalPdfPreview(snapshot.data!);
          }
          return Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.blue, size: 40),
                  const SizedBox(height: 8),
                  Text(context.tr.couldNotLoadPdf, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      );
    }
    return _buildLocalPdfPreview(path);
  }

  Widget _buildLocalPdfPreview(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFDB2777), size: 40),
                const SizedBox(height: 8),
                Text(context.tr.pdfNotFound, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      }
      return Container(
        color: Colors.white,
        child: IgnorePointer(
          child: SfPdfViewer.file(
            File(path),
            key: ValueKey(path),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error loading PDF preview: $e");
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDB2777), size: 40),
              const SizedBox(height: 8),
              Text(context.tr.couldNotLoadPreview, style: TextStyle(color: Colors.grey[800])),
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(e.toString(), style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      );
    }
  }

  String? _getTargetCommentKey() {
    if (widget.initialCommentId != null) {
      final comments = (_post['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      Map<String, dynamic>? foundComment;
      void searchById(List<Map<String, dynamic>> list) {
        for (var c in list) {
          if (c['id'] == widget.initialCommentId) {
            foundComment = c;
            return;
          }
          final replies = comments.where((r) => r['parentId'] == c['id']).toList();
          if (replies.isNotEmpty) {
            searchById(replies);
            if (foundComment != null) return;
          }
        }
      }
      searchById(comments);
      if (foundComment != null) {
        final author = foundComment!['author'] ?? '';
        final text = foundComment!['text'] ?? '';
        return "${widget.postId}_${author}_${text}_${widget.initialCommentId}";
      }
    }
    if (widget.initialCommentAuthor != null && widget.initialCommentText != null) {
      final comments = (_post['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      String? actualAuthor;
      String? actualText;
      int? foundId;
      void searchComments(List<Map<String, dynamic>> commentList) {
        for (var comment in commentList) {
          final commentText = comment['text']?.toString().trim() ?? '';
          final commentAuthor = comment['author']?.toString().trim() ?? '';
          final notificationText = widget.initialCommentText!.trim();
          final notificationAuthor = widget.initialCommentAuthor!.trim();
          if (commentText == notificationText && commentAuthor.toLowerCase() == notificationAuthor.toLowerCase()) {
            actualAuthor = commentAuthor;
            actualText = commentText;
            foundId = comment['id'];
            return;
          }
          final replies = comments.where((c) => c['parentId'] == comment['id'] || (comment['id'] != null && c['parentId'] == comment['id'])).toList();
          if (replies.isNotEmpty) {
            searchComments(replies);
            if (actualAuthor != null && actualText != null) return;
          }
        }
      }
      searchComments(comments);
      final authorToUse = actualAuthor ?? widget.initialCommentAuthor!.trim();
      final textToUse = actualText ?? widget.initialCommentText!.trim();
      String key = "${widget.postId}_${authorToUse}_${textToUse.trim()}";
      if (foundId != null) key = "${key}_$foundId";
      debugPrint("IndividualPostScreen: Generated target comment key: $key");
      return key;
    }
    return null;
  }

  Widget _buildPostHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // RATING - simple, no Consumer/ratingProvider
                GestureDetector(
                onTap: () => _showRatingDialog(
    _post['id'] is int ? _post['id'] : int.tryParse(_post['id'].toString()) ?? 0,
    _post['title'] ?? 'Post',
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          (_post['my_rating'] ?? 0) > 0
              ? Icons.star
              : Icons.star_border,
          color: Colors.amber,
          size: 22,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
              ((_post['averageRating'] ??
                  _post['average_rating'] ??
                  0) as num)
                  .toDouble()
                  .toStringAsFixed(1)
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            "(${_post['totalRatings'] ??
                _post['total_ratings'] ??
                0})",
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(_post['author']),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _post['author'] ?? context.tr.unknown,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (_post['location'] != null)
                          Text(
                            _post['location'],
                            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_isOwnPost(_post))
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Theme.of(context).hintColor, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    position: PopupMenuPosition.under,
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onPostAction(_post, 'edit');
                      } else if (value == 'delete') {
                        widget.onPostAction(_post, 'delete');
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(context.tr.editPost),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 20, color: Color(0xFFD32F2F)),
                            const SizedBox(width: 12),
                            Text(context.tr.deletePost, style: const TextStyle(color: Color(0xFFD32F2F))),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_post['content'] != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_post['content'], style: const TextStyle(fontSize: 15)),
            ),
          ],
          Builder(
            builder: (context) {
              final path = _post['filePath'] as String? ??
                  _post['image'] as String? ??
                  _post['media'] as String? ??
                  _post['coverPath'] as String? ??
                  _post['cover'] as String?;
              final bool isVideo = _post['type'] == 'Video' ||
                  _post['type'] == 'Reel' ||
                  _post['type'] == 'Reels' ||
                  (path != null && path.toLowerCase().endsWith('.mp4'));
              if (isVideo && path != null && path.isNotEmpty) {
                final isPaid = !_isFree(_post['price']);
                final isUnlocked = _isUnlocked(_post);
                final coverPath = _post['cover'] ?? _post['image'] ?? _post['coverPath'];
                if (isPaid && !isUnlocked) {
                  return SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        if (coverPath != null && coverPath.toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(coverPath.toString()),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Theme.of(context).cardColor,
                              child: Center(
                                child: Icon(Icons.videocam_outlined, size: 60, color: Colors.grey),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: _buildLockedOverlay(context, _post['price']?.toString() ?? '\$0.00'),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VideoPlayerWidget(
                      videoPath: path,
                      coverPath: _post['coverPath'],
                      autoPlay: true,
                      showControls: false,
                      fit: BoxFit.contain,
                      looping: true,
                      showEnlargeButton: true,
                      onEnlargeTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenVideoPlayer(
                              tracks: [{'filePath': path ?? ''}],
                              initialIndex: 0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
              final bool isPdf = path != null && path.toLowerCase().endsWith('.pdf');
              if (isPdf) {
                final isPaid = !_isFree(_post['price']);
                final isUnlocked = _isUnlocked(_post);
                return Column(
                  children: [
                    Container(
                      height: 400,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        color: Colors.white,
                      ),
                      child: Stack(
                        children: [
                          _buildPdfPreview(path),
                          if (isPaid && !isUnlocked)
                            Positioned.fill(
                              child: _buildLockedOverlay(context, _post['price']?.toString() ?? '\$0.00'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          OpenFilex.open(path);
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: Text(context.tr.openFullPdf),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDB2777),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                );
              }
              final bool isAudio = _post['type'] == 'Song' ||
                  (path != null && (path.toLowerCase().endsWith('.mp3') ||
                      path.toLowerCase().endsWith('.wav') ||
                      path.toLowerCase().endsWith('.m4a') ||
                      path.toLowerCase().endsWith('.aac')));
              if (isAudio && path != null && path.isNotEmpty) {
                final isPaid = !_isFree(_post['price']);
                final isUnlocked = _isUnlocked(_post);
                final coverPath = _post['coverPath'] ?? _post['image'] ?? _post['cover'];
                if (isPaid && !isUnlocked) {
                  return SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverPath != null && coverPath.toString().isNotEmpty)
                          (coverPath.toString().startsWith('http'))
                              ? Image.network(
                            coverPath.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                          )
                              : Image.file(
                            File(coverPath.toString()),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                          )
                        else
                          Container(
                            color: Colors.grey[900],
                            child: const Center(child: Icon(Icons.music_note, size: 50, color: Colors.white54)),
                          ),
                        Positioned.fill(
                          child: _buildLockedOverlay(context, _post['price']?.toString() ?? '\$0.00'),
                        ),
                      ],
                    ),
                  );
                }
                return AudioPlayerWidget(
                  key: ValueKey('${path}_${_post['id']}'),
                  audioPath: path,
                  coverPath: coverPath?.toString(),
                );
              }
              if (path != null && path.isNotEmpty) {
                final isPaid = !_isFree(_post['price']);
                final isUnlocked = _isUnlocked(_post);
                if (isPaid && !isUnlocked) {
                  return SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (path.startsWith('http'))
                          Image.network(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                          )
                        else
                          Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                          ),
                        Positioned.fill(
                          child: _buildLockedOverlay(context, _post['price']?.toString() ?? '\$0.00'),
                        ),
                      ],
                    ),
                  );
                }
                final isNetworkImage = path.startsWith('http') || path.startsWith('https');
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 200, maxHeight: 600),
                  child: SizedBox(
                    width: double.infinity,
                    child: isNetworkImage
                        ? Image.network(
                      path,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (c, e, s) {
                        debugPrint("Error loading network image: $e");
                        return Container(
                          width: double.infinity,
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        );
                      },
                    )
                        : Builder(
                      builder: (context) {
                        try {
                          final file = File(path);
                          if (!file.existsSync()) {
                            final absoluteFile = File(file.absolute.path);
                            if (absoluteFile.existsSync()) {
                              return Image.file(
                                absoluteFile,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                cacheWidth: 800,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 300,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                        const SizedBox(height: 8),
                                        Text(context.tr.imageNotFound, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              width: double.infinity,
                              height: 300,
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(context.tr.imageNotFound, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Image.file(
                            file,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            cacheWidth: 800,
                            gaplessPlayback: true,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return frame == null
                                  ? Container(
                                width: double.infinity,
                                height: 300,
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              )
                                  : child;
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("Error loading local image: $error");
                              try {
                                final absoluteFile = File(file.absolute.path);
                                if (absoluteFile.existsSync()) {
                                  return Image.file(
                                    absoluteFile,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    cacheWidth: 800,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: double.infinity,
                                      height: 300,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                            const SizedBox(height: 8),
                                            Text(context.tr.failedToLoadImage, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {}
                              return Container(
                                width: double.infinity,
                                height: 300,
                                color: Colors.grey[200],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      Text(context.tr.failedToLoadImage, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } catch (e) {
                          return Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(context.tr.invalidImagePath, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }
              if (_post['video'] != null && _post['video'].toString().isNotEmpty) {
                final isPaid = !_isFree(_post['price']);
                final isUnlocked = _isUnlocked(_post);
                final coverPath = _post['image'] ?? _post['coverPath'] ?? _post['cover'];
                if (isPaid && !isUnlocked) {
                  return SizedBox(
                    height: 300,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverPath != null && coverPath.toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (coverPath.toString().startsWith('http'))
                                ? Image.network(
                              coverPath.toString(),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).cardColor),
                            )
                                : Image.file(
                              File(coverPath.toString()),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).cardColor),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Theme.of(context).cardColor,
                              child: Center(
                                child: Icon(Icons.videocam_outlined, size: 60, color: Colors.grey),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: _buildLockedOverlay(context, _post['price']?.toString() ?? '\$0.00'),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VideoPlayerWidget(
                      videoPath: _post['video'],
                      coverPath: coverPath?.toString(),
                      autoPlay: true,
                      showControls: false,
                      fit: BoxFit.contain,
                      looping: true,
                      showEnlargeButton: true,
                      onEnlargeTap: () {
                        if (_post['video'] != null && _post['video'].toString().isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenVideoPlayer(
                                tracks: [{'filePath': _post['video'] ?? ''}],
                                initialIndex: 0,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }
              if (_post['type'] == 'Image') {
                debugPrint("IndividualPostScreen: Image post but no media path found.");
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
                        const SizedBox(height: 8),
                        Text(context.tr.imageNotAvailable, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // LIKE interactive
                GestureDetector(
                  onTap: () {
                    final key = "${_post['title']}_${_post['author']}";
                    final wasLiked = _likedPostIds.contains(key);
                    setState(() {
                      if (wasLiked) {
                        _likedPostIds.remove(key);
                        _post['likeCount'] = (_post['likeCount'] ?? 0) - 1;
                      } else {
                        _likedPostIds.add(key);
                        _post['likeCount'] = (_post['likeCount'] ?? 0) + 1;
                      }
                      if (_post['likeCount'] < 0) _post['likeCount'] = 0;
                    });
                    widget.onPostAction(_post, 'Like');
                  },
                  child: Row(
                    children: [
                      Icon(
                        _likedPostIds.contains("${_post['title']}_${_post['author']}")
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.pink,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${_post['likeCount'] ?? 0}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                // Comments
                Row(
                  children: [
                    const Icon(Icons.chat_bubble, color: Colors.blue, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "${(_post['comments'] as List?)?.length ?? 0}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                // RATING interactive
    Consumer(

    builder: (context, ref, _) {

    final int postId =
    _post['id'] is int
    ? _post['id']
        : int.tryParse(
    _post['id'].toString(),
    ) ??
    0;

    final ratingAsync =
    ref.watch(
    ratingProvider(postId),
    );

    return ratingAsync.when(

      data: (ratingResponse) {

        final ratingData =
            ratingResponse.data;

        final double avg =
        (_post['averageRating'] ??
            ratingData.averageRating)
            .toDouble();

        final int total =
            ratingData.totalRatings;

        final myRating =
            ratingData.userRating ?? 0;

        return GestureDetector(

          onTap: () {

            _showRatingDialog(
              postId,
              _post['title'] ?? 'Post',
            );

          },

          child: Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              Icon(
                myRating > 0
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 22,
              ),

              const SizedBox(width: 5),

              Text(

                avg.toStringAsFixed(1),

                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),

              ),

              const SizedBox(width: 4),

              Text(

                "($total)",

                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                ),

              ),

            ],

          ),

        );
      },

      loading: () {

        return Row(

          children: [

            Icon(
              Icons.star,
              color: Colors.amber,
              size: 22,
            ),

            const SizedBox(width: 5),

            Text(

              (_post['averageRating'] ?? 0)
                  .toString(),

              style: const TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),

            ),

          ],

        );
      },

      error: (_, __) {

        return Row(

          children: [

            Icon(
              Icons.star,
              color: Colors.amber,
              size: 22,
            ),

            const SizedBox(width: 5),

            Text(

              (_post['averageRating'] ?? 0)
                  .toString(),

              style: const TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),

            ),

          ],

        );
      },

    );


    },

    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr.postUnavailable)),
        body: Center(child: Text(context.tr.postCouldNotBeFound)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.post),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CommentSection(
        key: _commentSectionKey,
        post: _post,
        currentUser: widget.currentUser,
        users: widget.users,
        onUserTap: widget.onUserTap,
        onPostAction: widget.onPostAction,
        targetCommentKey: _getTargetCommentKey(),
        header: _buildPostHeader(context),
      ),
    );
  }

  Widget _buildLockedOverlay(BuildContext context, String price) {
    String displayPrice = price;
    if (!price.startsWith(context.tr.currencySymbol) && !price.toLowerCase().contains('free')) {
      displayPrice = "${context.tr.currencySymbol}$price";
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(Icons.lock_outline, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final authorName = _post['author']?.toString() ?? '';
                if (authorName.isEmpty) return;
                String clean(String s) => s.replaceAll(RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false), '').replaceAll(' ', '').trim().toLowerCase();
                final targetClean = clean(authorName);
                final author = widget.users.firstWhere(
                      (u) => clean(u.name) == targetClean || clean(u.username) == targetClean,
                  orElse: () => MockUser(name: authorName, username: authorName, avatar: '', type: 'other'),
                );
                if (widget.onUserAction != null) {
                  await widget.onUserAction!(author, 'Subscribe');
                  await _checkSubscription();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: const Color(0xFFDB2777).withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                context.tr.subscribeToUnlock,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}