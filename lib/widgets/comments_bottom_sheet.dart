import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';
import 'comment_section.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final MockUser currentUser;
  final Function(Map<String, dynamic>, String, {dynamic extraData}) onPostAction;
  final List<MockUser> allUsers;
  final ScrollController? scrollController;
  final bool allowComments;

  const CommentsBottomSheet({
    super.key,
    required this.post,
    required this.currentUser,
    required this.onPostAction,
    required this.allUsers,
    this.scrollController,
    this.allowComments = true,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late List<Map<String, dynamic>> _localComments;
  late int _serverCount;
  bool _isSubmitting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serverCount = (widget.post['commentsCount'] as num?)?.toInt() ?? 0;
    _localComments = _flatten(widget.post['comments'] as List? ?? []);
    final loaded = _localRootCount();
    if (loaded > _serverCount) _serverCount = loaded;
    _fetchCommentsFromApi();
  }

  // ── Fetch comments from API ────────────────────────────────────────────────
  Future<void> _fetchCommentsFromApi() async {
    final postId = widget.post['id'];
    if (postId == null) return;
    final int? pid = postId is int ? postId : int.tryParse(postId.toString());
    if (pid == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      debugPrint('=== FETCH COMMENTS pid=$pid');

      final response = await Dio().get(
        'https://openzippers.com/api/v1/zippfans/comments',
        queryParameters: {'post_id': pid},
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      debugPrint('=== FETCH STATUS: ${response.statusCode}');
      debugPrint('=== FETCH DATA: ${response.data}');

      if (!mounted) return;

      List? rawList;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          final d = data['data'];
          if (d is List) {
            rawList = d;
          } else if (d is Map) {
            rawList = d['comments'] as List? ??
                d['data'] as List? ??
                d['items'] as List? ??
                [];
          } else {
            rawList = data['comments'] as List? ?? [];
          }
        } else if (data is List) {
          rawList = data;
        }
      }

      rawList ??= [];
      debugPrint('=== PARSED ${rawList.length} comments');

      final fetched = _flatten(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );

      if (mounted) {
        setState(() {
          // Keep all local comments; only add truly new ones from server
          final localIds =
          _localComments.map((c) => c['id'].toString()).toSet();

          final newFromServer = fetched
              .where((c) => !localIds.contains(c['id'].toString()))
              .toList();

          _localComments = [..._localComments, ...newFromServer];

          // Clear _pending flag for comments that the server now knows about
          final serverIds =
          fetched.map((c) => c['id'].toString()).toSet();
          _localComments = _localComments.map((c) {
            if (c['_pending'] == true &&
                serverIds.contains(c['id'].toString())) {
              return {...c, '_pending': false};
            }
            return c;
          }).toList();

          final rootCount = _localComments.where((c) {
            final pid = c['parentId'];
            return pid == null || pid == 0 || pid == '0';
          }).length;

          _serverCount =
          rootCount > _serverCount ? rootCount : _serverCount;
          widget.post['comments'] = _localComments;
          widget.post['commentsCount'] = _getDisplayCount();
        });
      }
    } catch (e) {
      debugPrint('=== FETCH ERROR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── URL helper ─────────────────────────────────────────────────────────────
  static String _normalizeUrl(String url) {
    if (url.isEmpty || url.startsWith('http')) return url;
    final trimmed = url.startsWith('/') ? url : '/$url';
    return 'https://openzippers.com$trimmed';
  }

  // ── Auth helper ────────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ── Comment normalization ──────────────────────────────────────────────────
  Map<String, dynamic> _normalizeComment(dynamic raw,
      {dynamic forcedParentId}) {
    if (raw is! Map) return {};
    final m = Map<String, dynamic>.from(raw);

    int? id;
    final rawId = m['id'];
    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.tryParse(rawId);
    } else if (rawId is num) {
      id = rawId.toInt();
    }

    final user = m['user'];
    final Map<String, dynamic> userMap =
    user is Map ? Map<String, dynamic>.from(user) : <String, dynamic>{};
    final String author =
    (userMap['name'] ?? userMap['username'] ?? m['author'] ?? 'User')
        .toString();

    final String avatar = _normalizeUrl(
      (userMap['avatar'] ?? userMap['avatar_url'] ?? m['avatar'] ?? '')
          .toString(),
    );

    String time = (m['time'] ?? '').toString();
    DateTime timestamp = DateTime.now();
    final createdAt = m['created_at'] ?? m['createdAt'];
    if (createdAt != null) {
      final dt = createdAt is DateTime
          ? createdAt
          : DateTime.tryParse(createdAt.toString());
      if (dt != null) {
        timestamp = dt;
        if (time.isEmpty) {
          final diff = DateTime.now().difference(dt);
          if (diff.inMinutes < 1) {
            time = 'Just now';
          } else if (diff.inMinutes < 60) {
            time = '${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            time = '${diff.inHours}h ago';
          } else {
            time = '${diff.inDays}d ago';
          }
        }
      }
    } else if (m['timestamp'] is DateTime) {
      timestamp = m['timestamp'] as DateTime;
    }

    dynamic parentId = m['parentId'] ?? m['parent_id'];
    if (forcedParentId != null &&
        (parentId == null || parentId == 0 || parentId == '0')) {
      parentId = forcedParentId;
    }

    return {
      'id': id ?? DateTime.now().microsecondsSinceEpoch,
      'author': author,
      'avatar': avatar,
      'text': (m['text'] ?? m['comment'] ?? m['content'] ?? m['body'] ?? '')
          .toString(),
      'time': time,
      'timestamp': timestamp,
      'parentId': parentId,
      'likes': List<String>.from(m['likes'] ?? const []),
    };
  }

  List<Map<String, dynamic>> _flatten(List<dynamic> rawItems) {
    final List<Map<String, dynamic>> result = [];
    void walk(dynamic item, dynamic forcedParentId) {
      if (item is! Map) return;
      final normalized =
      _normalizeComment(item, forcedParentId: forcedParentId);
      if (normalized.isNotEmpty) {
        final exists = result
            .any((e) => e['id'].toString() == normalized['id'].toString());
        if (!exists) result.add(normalized);
      }
      final replies = item['replies'];
      if (replies is List) {
        for (final r in replies) {
          walk(r, normalized['id']);
        }
      }
    }

    for (final i in rawItems) {
      walk(i, null);
    }
    return result;
  }

  int _localRootCount() => _localComments.where((c) {
    final pid = c['parentId'];
    return pid == null ||
        pid == 0 ||
        pid == '0' ||
        (pid is String && pid.trim().isEmpty);
  }).length;

  int _getDisplayCount() {
    final loaded = _localRootCount();
    return loaded > _serverCount ? loaded : _serverCount;
  }

  // ── Submit comment ─────────────────────────────────────────────────────────
  Future<void> _submitComment(String text, {dynamic parentId}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isSubmitting) return;

    final postId = widget.post['id'];
    if (postId == null) return;

    final bool isRoot =
        parentId == null || parentId == 0 || parentId == '0';

    // Optimistic insert
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final optimistic = <String, dynamic>{
      'id': tempId,
      'author': widget.currentUser.name,
      'avatar': _normalizeUrl(widget.currentUser.avatar),
      'text': cleanText,
      'time': 'Just now',
      'parentId': parentId,
      'timestamp': DateTime.now(),
      'likes': <String>[],
      '_pending': true,
    };

    setState(() {
      _isSubmitting = true;
      _localComments.insert(0, optimistic);
      if (isRoot) _serverCount += 1;
      widget.post['comments'] = _localComments;
      widget.post['commentsCount'] = _getDisplayCount();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _rollback(tempId, isRoot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to comment')),
          );
        }
        return;
      }

      final dio = Dio();
      dio.options.baseUrl = 'https://openzippers.com/api/v1/';
      dio.options.headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final int parsedPostId =
      postId is int ? postId : int.tryParse(postId.toString()) ?? 0;

      if (parsedPostId == 0) {
        _rollback(tempId, isRoot);
        return;
      }

      final response = await dio.post(
        'zippfans/comments',
        data: FormData.fromMap({
          'post_id': parsedPostId,
          'content': cleanText,
          if (!isRoot && parentId != null)
            'parent_id': parentId is int
                ? parentId
                : int.tryParse(parentId.toString()),
        }),
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      debugPrint('COMMENT BODY: post_id=$parsedPostId content=$cleanText');
      debugPrint(
          'COMMENT RESPONSE ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Replace optimistic entry with real server data (or just clear _pending)
        dynamic rawSaved;
        if (response.data is Map) {
          rawSaved =
              response.data['data'] ?? response.data['comment'];
        }
        final saved = rawSaved != null
            ? _normalizeComment(rawSaved)
            : <String, dynamic>{};

        // ✅ NO _fetchCommentsFromApi() call here — that was wiping the comment
        setState(() {
          final idx =
          _localComments.indexWhere((c) => c['id'] == tempId);
          if (idx != -1) {
            _localComments[idx] = saved.isNotEmpty
                ? saved
                : {...optimistic, '_pending': false};
          }
          widget.post['comments'] = _localComments;
          widget.post['commentsCount'] = _getDisplayCount();
        });
      } else {
        _rollback(tempId, isRoot);
        final msg = response.data is Map
            ? (response.data['message'] ??
            response.data['errors']?.toString() ??
            'Failed to post')
            : 'Error ${response.statusCode}';
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      _rollback(tempId, isRoot);
      debugPrint('Comment submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Network error. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Rollback optimistic insert ─────────────────────────────────────────────
  void _rollback(int tempId, bool wasRoot) {
    if (!mounted) return;
    setState(() {
      _localComments.removeWhere((c) => c['id'] == tempId);
      if (wasRoot && _serverCount > 0) _serverCount -= 1;
      widget.post['comments'] = _localComments;
      widget.post['commentsCount'] = _getDisplayCount();
    });
  }

  // ── Action router ──────────────────────────────────────────────────────────
  void _handlePostAction(
      Map<String, dynamic> post,
      String action, {
        dynamic extraData,
      }) {
    if (action == 'SubmitComment' && extraData != null) {
      final text = (extraData['text'] ?? '').toString();
      final parentId = extraData['parentId'];
      _submitComment(text, parentId: parentId);
      return;
    }

    if (action == 'LikeComment' && extraData is Map<String, dynamic>) {
      // Update _localComments in place so CommentSection sees the change
      setState(() {
        final idx = _localComments.indexWhere(
                (c) => c['id'].toString() == extraData['id'].toString());
        if (idx != -1) {
          _localComments[idx] = Map<String, dynamic>.from(extraData);
        }
        widget.post['comments'] = _localComments;
      });
      // Propagate to HomeScreen for persistence
      widget.onPostAction(post, action, extraData: extraData);
      return;
    }

    widget.onPostAction(post, action, extraData: extraData);
  }

  // ── Post preview ───────────────────────────────────────────────────────────
  Widget _buildPostPreview(ThemeData theme) {
    final postType =
    (widget.post['post_type'] ?? '').toString().toLowerCase();
    final imageUrl = _normalizeUrl(
        (widget.post['imageUrl'] ??
            widget.post['image'] ??
            widget.post['coverPath'] ??
            '')
            .toString());
    final title = (widget.post['title'] as String? ?? '').trim();
    final author = (widget.post['author'] as String? ?? '').trim();
    final ImageProvider? imageProvider =
    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              color: theme.dividerColor,
              child: imageProvider != null
                  ? Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    color: theme.hintColor),
              )
                  : Icon(
                postType == 'video'
                    ? Icons.videocam_rounded
                    : postType == 'song'
                    ? Icons.music_note_rounded
                    : Icons.article_rounded,
                color: const Color(0xFFDB2777),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                if (author.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(author,
                        style:
                        TextStyle(fontSize: 12, color: theme.hintColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _getDisplayCount();

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildPostPreview(theme),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr.commentsCount(count),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (_isSubmitting || _isLoading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      height: 13,
                      width: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFDB2777),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: CommentSection(
                key: ValueKey(
                    'comments_${widget.post['id']}_${_localComments.length}'),
                post: {
                  ...widget.post,
                  'comments': _localComments,
                  'commentsCount': count,
                },
                currentUser: widget.currentUser,
                users: widget.allUsers,
                onPostAction: _handlePostAction,
                scrollController: widget.scrollController,
                enableComments: widget.allowComments,
              ),
            ),
          ],
        ),
      ),
    );
  }
}