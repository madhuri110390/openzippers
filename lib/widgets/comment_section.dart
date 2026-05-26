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
  bool _isUserTyping = false;

  DateTime? _parseTimestamp(dynamic ts) {
    if (ts == null) return null;
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.tryParse(ts);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      final hasText = _commentController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
          _isUserTyping = hasText;
        });
        widget.onTyping?.call(hasText);
      }
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isUserTyping) {
        setState(() => _isUserTyping = false);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void focusInput({bool disableAutoScroll = false}) {
    if (mounted) {
      _focusNode.requestFocus();
    }
  }

  // void _handleReply(Map<String, dynamic> comment) {
  //   setState(() {
  //     if (_replyingTo != null && _replyingTo!['id'] == comment['id']) {
  //       _replyingTo = null;
  //       _focusNode.unfocus();
  //     } else {
  //       _replyingTo = comment;
  //       _focusNode.requestFocus();
  //     }
  //   });
  // }
  void _handleReply(Map<String, dynamic> comment) {
    final currentId = int.tryParse(comment['id'].toString());

    setState(() {
      final replyId = _replyingTo == null
          ? null
          : int.tryParse(_replyingTo!['id'].toString());

      if (replyId == currentId) {
        _replyingTo = null;
        _focusNode.unfocus();
      } else {
        _replyingTo = comment;
        _focusNode.requestFocus();
      }
    });
  }
  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    // widget.onPostAction(widget.post, 'SubmitComment', extraData: {
    //   'text': text,
    //   'parentId': _replyingTo?['id'],
    //   'replyToUser': _replyingTo?['author'],
    // });
    widget.onPostAction(
      widget.post,
      'SubmitComment',
      extraData: {
        'text': text,
        'parentId': int.tryParse(
          _replyingTo?['id']?.toString() ?? '',
        ),
        'replyToUser':
        _replyingTo?['author'] ??
            _replyingTo?['user']?['name'] ??
            'User',
      },
    );
    _commentController.clear();
    setState(() {
      _isSubmitting = false;
      _replyingTo = null;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawComments =
    (widget.post['comments'] as List? ?? [])
        .where((e) => e != null)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // final Set<int> seenIds = {};
    // final List<Map<String, dynamic>> comments = [];
    // for (final comment in rawComments) {
    //   final id = comment['id'] as int?;
    //   if (id != null) {
    //     if (!seenIds.contains(id)) {
    //       seenIds.add(id);
    //       comments.add(comment);
    //     }
    //   } else {
    //     comments.add(comment);
    //   }
    // }
    final Set<int> seenIds = {};
    final List<Map<String, dynamic>> comments = [];

    for (final comment in rawComments) {
      final dynamic rawId = comment['id'];

      final int? id = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '');

      if (id != null) {
        if (!seenIds.contains(id)) {
          seenIds.add(id);
          comments.add(comment);
        }
      } else {
        comments.add(comment);
      }
    }

    final rootComments = comments.where((c) {
      final parentId = c['parentId'] ?? c['parent_id'];
      return parentId == null || parentId == 0 || parentId == '0' || parentId == '' || parentId == 'null';
    }).toList();

    rootComments.sort((a, b) {
      final tA = _parseTimestamp(a['timestamp'] ?? a['created_at']);
      final tB = _parseTimestamp(b['timestamp'] ?? b['created_at']);
      if (tA != null && tB != null) return tB.compareTo(tA);
      return 0;
    });

    final Map<int, List<Map<String, dynamic>>> groupedComments = {};
    for (final c in comments) {
      final parentId = c['parentId'] ?? c['parent_id'];
      if (parentId == null || parentId == 0 || parentId == '0' || parentId == '' || parentId == 'null') continue;

      int? pid = parentId is int ? parentId : int.tryParse(parentId.toString());
      if (pid != null) {
        groupedComments.putIfAbsent(pid, () => []).add(c);
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final hasBoundedHeight = constraints.maxHeight != double.infinity;
      
      final listView = ListView.builder(
        controller: widget.scrollController,
        shrinkWrap: !hasBoundedHeight,
        physics: hasBoundedHeight ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: (widget.header != null ? 1 : 0) + rootComments.length,
        itemBuilder: (context, index) {
          if (widget.header != null) {
            if (index == 0) return widget.header!;
            index--;
          }

          if (index < rootComments.length) {
            final comment = rootComments[index];
            return _buildCommentTree(comment, groupedComments, theme);
          }
          return const SizedBox.shrink();
        },
      );

      return Column(
        children: [
          if (hasBoundedHeight) Expanded(child: listView) else listView,
          if (widget.enableComments) _buildInputArea(theme),
        ],
      );
    });
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 8, 
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16
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
                        "${context.tr.replyingTo} ${_replyingTo?['author'] ?? _replyingTo?['user']?['name'] ?? 'User'}",
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDB2777))),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Builder(builder: (context) {
                ImageProvider? imageProvider;
                String? avatar = widget.currentUser.avatar;
                
                if (avatar == null || avatar.isEmpty) {
                   try {
                     final found = widget.users.firstWhere((u) => u.username == widget.currentUser.username);
                     avatar = found.avatar;
                   } catch (_) {}
                }

                if (avatar != null && avatar.isNotEmpty) {
                  if (avatar.startsWith('http')) {
                    imageProvider = NetworkImage(avatar);
                  } else {
                    final file = File(avatar);
                    if (file.existsSync()) {
                      imageProvider = FileImage(file);
                    }
                  }
                }
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.dividerColor,
                  backgroundImage: imageProvider,
                  child: imageProvider == null ? const Icon(Icons.person, color: Color(0xFFDB2777)) : null,
                );
              }),
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
                      (_replyingTo?['author'] ??
                          _replyingTo?['user']?['name'] ??
                          'User').toString(),
                    )
                        : context.tr.writeSomething,
                    hintStyle: TextStyle(color: theme.hintColor, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    suffixIcon: _hasText
                        ? IconButton(icon: const Icon(Icons.send, color: Color(0xFFDB2777)), onPressed: _submitComment)
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

  Widget _buildCommentTree(
      Map<String, dynamic> comment,
      Map<int, List<Map<String, dynamic>>> groupedComments,
      ThemeData theme, {
        int depth = 0,
      }) {
    try {
      int? pid = comment['id'] is int
          ? comment['id']
          : int.tryParse(comment['id']?.toString() ?? '');

      final replies = pid != null
          ? (groupedComments[pid] ?? [])
          : [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentRow(comment, theme, depth: depth),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                children: replies
                    .map((reply) => _buildCommentTree(
                  reply,
                  groupedComments,
                  theme,
                  depth: depth + 1,
                ))
                    .toList(),
              ),
            ),
        ],
      );
    } catch (e, s) {
      debugPrint('COMMENT TREE ERROR');
      debugPrint(comment.toString());
      debugPrint(e.toString());
      debugPrint(s.toString());

      return const SizedBox();
    }
  }

  Widget _buildCommentRow(Map<String, dynamic> comment, ThemeData theme, {int depth = 0}) {
    final authorName =
        comment['author'] ??
            comment['user']?['name'];
            'Unknown User';
    final commentText = comment['text'] ?? "";
    final isLiked = (comment['likes'] as List?)?.contains(widget.currentUser.username) ?? false;
    final likesCount = (comment['likes'] as List?)?.length ?? 0;
    final avatar =
        comment['avatar'] ??
            comment['user']?['avatar'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
               if (widget.onUserTap != null) {
                 try {
                   final user = widget.users.firstWhere((u) => u.name == authorName || u.username == authorName);
                   widget.onUserTap!(user);
                 } catch (_) {}
               }
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.dividerColor,
              backgroundImage: avatar is String &&
                  avatar.isNotEmpty &&
                  avatar.startsWith('http')
                  ? NetworkImage(avatar)
                  : null,
              child: (comment['avatar'] == null || comment['avatar'].toString().isEmpty)
                  ? Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : "?") : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFDB2777))),
                      const SizedBox(height: 2),
                      ExpandableCommentText(text: commentText, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(comment['time'] ?? "", style: TextStyle(fontSize: 11, color: Colors.white)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => widget.onPostAction(widget.post, 'LikeComment', extraData: comment),
                      child: Text(isLiked ? "Unlike" : "Like", 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isLiked ? const Color(0xFFDB2777) : Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _handleReply(comment),
                      child: Text("Reply", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    if (likesCount > 0) ...[
                      const Spacer(),
                      Icon(Icons.favorite, size: 12, color: const Color(0xFFDB2777)),
                      const SizedBox(width: 2),
                      Text("$likesCount", style: TextStyle(fontSize: 11, color: Colors.white)),
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

      if (tp.didExceedMaxLines) {
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
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              Text(
                _isExpanded ? context.tr.showLess : context.tr.showMore,
                style: const TextStyle(color: Color(0xFFDB2777), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }
      return Text(widget.text, style: widget.style);
    });
  }
}
