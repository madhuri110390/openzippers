import 'dart:io';
import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';

class CommentSection extends StatefulWidget {
  final Map<String, dynamic> post;
  final MockUser currentUser;
  final List<MockUser> users;
  final Function(Map<String, dynamic>, String, {dynamic extraData}) onPostAction;
  final Function(MockUser)? onUserTap;
  final ValueChanged<bool>? onTyping;
  final String? targetCommentKey;
  final Function(String, GlobalKey)? onCommentKeyCreated;
  final bool isReel;
  final VoidCallback? onFocusRequested;
  final bool isUserInteracting;
  final Widget? header;
  final ScrollController? scrollController;
  final bool enableComments;

  const CommentSection({
    super.key,
    required this.post,
    required this.currentUser,
    required this.onPostAction,
    required this.users,
    this.onUserTap,
    this.onTyping,
    this.targetCommentKey,
    this.onCommentKeyCreated,
    this.isReel = false,
    this.onFocusRequested,
    this.isUserInteracting = false,
    this.header,
    this.scrollController,
    this.enableComments = true,
  });

  @override
  State<CommentSection> createState() => CommentSectionState();
}

class CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  Map<String, dynamic>? _replyingTo;
  bool _isSubmitting = false;

  // Local like state: commentId → Set of usernames who liked
  // This is the source of truth for UI — not the comment map itself.
  // Avoids StatefulBuilder stale-closure issues entirely.
  final Map<String, Set<String>> _localLikes = {};

  DateTime? _parseTimestamp(dynamic ts) {
    if (ts == null) return null;
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.tryParse(ts);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _syncLikesFromPost();
    _commentController.addListener(() {
      final hasText = _commentController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        widget.onTyping?.call(hasText);
      }
    });
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync any new comments' likes from server into local state
    // without overwriting likes the user already toggled locally
    _syncLikesFromPost(onlyNew: true);
  }

  /// Reads likes from widget.post['comments'] into _localLikes.
  /// [onlyNew]: if true, only adds entries for IDs not already tracked.
  void _syncLikesFromPost({bool onlyNew = false}) {
    final raw = widget.post['comments'] as List? ?? [];
    for (final c in raw) {
      if (c is! Map) continue;
      final id = c['id']?.toString();
      if (id == null) continue;
      if (onlyNew && _localLikes.containsKey(id)) continue;
      final likes = (c['likes'] as List?)?.map((e) => e.toString()).toSet()
          ?? <String>{};
      _localLikes[id] = likes;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void focusInput({bool disableAutoScroll = false}) {
    if (mounted) _focusNode.requestFocus();
  }

  void _handleReply(Map<String, dynamic> comment) {
    if (comment['_pending'] == true) return;

    // If replying to a reply, use the root parent id instead.
    // APIs only support one level of nesting — parent_id must be a root comment.
    final effectiveComment = (comment['parentId'] != null && comment['parentId'] != 0)
        ? {...comment, 'id': comment['parentId']}  // use parent's id
        : comment;

    final commentIdStr = effectiveComment['id']?.toString();
    final replyingIdStr = _replyingTo?['id']?.toString();

    setState(() {
      if (replyingIdStr != null && replyingIdStr == commentIdStr) {
        _replyingTo = null;
        _focusNode.unfocus();
      } else {
        _replyingTo = effectiveComment;
        _focusNode.requestFocus();
      }
    });
  }

  void _cancelReply() => setState(() => _replyingTo = null);

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    // Get parentId as int? from _replyingTo
    int? parentIdInt;
    final rawId = _replyingTo?['id'];
    if (rawId != null) {
      if (rawId is int && rawId != 0) {
        parentIdInt = rawId;
      } else {
        final p = int.tryParse(rawId.toString());
        if (p != null && p != 0) parentIdInt = p;
      }
    }

    widget.onPostAction(
      widget.post,
      'SubmitComment',
      extraData: {
        'text': text,
        'parentId': parentIdInt,
        'replyToUser': _replyingTo?['author'] ??
            _replyingTo?['user']?['name'] ??
            'User',
      },
    );

    _commentController.clear();
    setState(() {
      _isSubmitting = false;
      _replyingTo = null;
      _hasText = false;
    });
    _focusNode.unfocus();
  }

  void _toggleLike(Map<String, dynamic> comment) {
    if (comment['_pending'] == true) return;
    final id = comment['id']?.toString();
    if (id == null) return;

    final username = widget.currentUser.username;
    final current = Set<String>.from(_localLikes[id] ?? {});

    setState(() {
      if (current.contains(username)) {
        current.remove(username);
      } else {
        current.add(username);
      }
      _localLikes[id] = current;
    });

    // Update the comment map so the propagated extraData has correct likes
    comment['likes'] = current.toList();
    widget.onPostAction(widget.post, 'LikeComment', extraData: comment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rawComments = (widget.post['comments'] as List? ?? [])
        .where((e) => e != null)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Deduplicate by id
    final Set<String> seenIds = {};
    final List<Map<String, dynamic>> comments = [];
    for (final c in rawComments) {
      final id = c['id']?.toString() ?? '';
      if (id.isEmpty || !seenIds.contains(id)) {
        if (id.isNotEmpty) seenIds.add(id);
        comments.add(c);
      }
    }

    // Root comments: parentId null or 0
    final rootComments = comments.where((c) {
      final pid = c['parentId'];
      return pid == null || pid == 0 || pid == '0' || pid == '';
    }).toList()
      ..sort((a, b) {
        final tA = _parseTimestamp(a['timestamp'] ?? a['created_at']);
        final tB = _parseTimestamp(b['timestamp'] ?? b['created_at']);
        if (tA != null && tB != null) return tB.compareTo(tA);
        return 0;
      });

    // Group replies by parent id (normalised to String for safe lookup)
    final Map<String, List<Map<String, dynamic>>> groupedComments = {};
    for (final c in comments) {
      final rawPid = c['parentId'];
      if (rawPid == null || rawPid == 0 || rawPid == '0' || rawPid == '') continue;
      final pidStr = rawPid.toString();
      groupedComments.putIfAbsent(pidStr, () => []).add(c);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final hasBounded = constraints.maxHeight != double.infinity;

      final list = ListView.builder(
        controller: widget.scrollController,
        shrinkWrap: !hasBounded,
        physics: hasBounded
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: (widget.header != null ? 1 : 0) + rootComments.length,
        itemBuilder: (ctx, i) {
          if (widget.header != null) {
            if (i == 0) return widget.header!;
            i--;
          }
          if (i < rootComments.length) {
            return _buildCommentTree(rootComments[i], groupedComments, theme);
          }
          return const SizedBox.shrink();
        },
      );

      return Column(
        children: [
          if (hasBounded) Expanded(child: list) else list,
          if (widget.enableComments) _buildInputArea(theme),
        ],
      );
    });
  }

  // ── Input area ─────────────────────────────────────────────────────────────
  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      '${context.tr.replyingTo} '
                          '${_replyingTo!['author'] ?? _replyingTo!['user']?['name'] ?? 'User'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDB2777)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCurrentUserAvatar(theme),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _replyingTo != null
                        ? context.tr.replyToAuthor(
                        (_replyingTo!['author'] ??
                            _replyingTo!['user']?['name'] ??
                            'User')
                            .toString())
                        : context.tr.writeSomething,
                    hintStyle:
                    TextStyle(color: theme.hintColor, fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    suffixIcon: _hasText
                        ? IconButton(
                        icon: const Icon(Icons.send,
                            color: Color(0xFFDB2777)),
                        onPressed: _submitComment)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserAvatar(ThemeData theme) {
    ImageProvider? img;
    String? av = widget.currentUser.avatar;
    if (av == null || av.isEmpty) {
      try {
        av = widget.users
            .firstWhere((u) => u.username == widget.currentUser.username)
            .avatar;
      } catch (_) {}
    }
    if (av != null && av.isNotEmpty) {
      if (av.startsWith('http')) {
        img = NetworkImage(av);
      } else {
        final f = File(av);
        if (f.existsSync()) img = FileImage(f);
      }
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: theme.dividerColor,
      backgroundImage: img,
      child: img == null
          ? const Icon(Icons.person, color: Color(0xFFDB2777))
          : null,
    );
  }

  // ── Comment tree ───────────────────────────────────────────────────────────
  Widget _buildCommentTree(
      Map<String, dynamic> comment,
      Map<String, List<Map<String, dynamic>>> groupedComments,
      ThemeData theme, {
        int depth = 0,
      }) {
    final idStr = comment['id']?.toString() ?? '';
    final replies = groupedComments[idStr] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentRow(comment, theme, depth: depth),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: replies
                  .map((r) => _buildCommentTree(r, groupedComments, theme,
                  depth: depth + 1))
                  .toList(),
            ),
          ),
      ],
    );
  }

  // ── Comment row ────────────────────────────────────────────────────────────
  Widget _buildCommentRow(Map<String, dynamic> comment, ThemeData theme,
      {int depth = 0}) {
    final idStr = comment['id']?.toString() ?? '';
    final isPending = comment['_pending'] == true;

    // Use _localLikes as source of truth for this comment's likes
    final likes = _localLikes[idStr] ?? {};
    final isLiked = likes.contains(widget.currentUser.username);
    final likesCount = likes.length;

    // FIX: was semicolon-terminated before — 'Unknown User' was dead code
    final authorName = (comment['author'] ??
        comment['user']?['name'] ??
        'Unknown User')
        .toString();

    final commentText = (comment['text'] ?? '').toString();
    final avatar = comment['avatar'] ?? comment['user']?['avatar'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              if (widget.onUserTap == null) return;
              try {
                final u = widget.users.firstWhere(
                        (u) => u.name == authorName || u.username == authorName);
                widget.onUserTap!(u);
              } catch (_) {}
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.dividerColor,
              backgroundImage: avatar is String &&
                  avatar.isNotEmpty &&
                  avatar.startsWith('http')
                  ? NetworkImage(avatar)
                  : null,
              child: (avatar == null || avatar.toString().isEmpty)
                  ? Text(authorName.isNotEmpty
                  ? authorName[0].toUpperCase()
                  : '?')
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(authorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFFDB2777))),
                          if (isPending) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFFDB2777),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      ExpandableCommentText(
                          text: commentText,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    Text(comment['time'] ?? '',
                        style: TextStyle(
                            fontSize: 11, color: theme.hintColor)),
                    const SizedBox(width: 12),
                    // Like button
                    GestureDetector(
                      onTap: isPending ? null : () => _toggleLike(comment),
                      child: Text(
                        isLiked ? 'Unlike' : 'Like',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPending
                              ? theme.disabledColor
                              : isLiked
                              ? const Color(0xFFDB2777)
                              : theme.hintColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reply button
                    GestureDetector(
                      onTap: isPending ? null : () => _handleReply(comment),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPending
                              ? theme.disabledColor
                              : theme.hintColor,
                        ),
                      ),
                    ),
                    if (likesCount > 0) ...[
                      const Spacer(),
                      const Icon(Icons.favorite,
                          size: 12, color: Color(0xFFDB2777)),
                      const SizedBox(width: 2),
                      Text('$likesCount',
                          style: TextStyle(
                              fontSize: 11, color: theme.hintColor)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expandable text ────────────────────────────────────────────────────────
class ExpandableCommentText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const ExpandableCommentText({super.key, required this.text, this.style});

  @override
  State<ExpandableCommentText> createState() => _ExpandableCommentTextState();
}

class _ExpandableCommentTextState extends State<ExpandableCommentText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final tp = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: 3,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      if (!tp.didExceedMaxLines) {
        return Text(widget.text, style: widget.style);
      }

      return GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _isExpanded ? null : 3,
              overflow:
              _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            Text(
              _isExpanded ? context.tr.showLess : context.tr.showMore,
              style: const TextStyle(
                  color: Color(0xFFDB2777),
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    });
  }
}