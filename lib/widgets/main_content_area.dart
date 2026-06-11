import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart' as widgets;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../providers/block_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/rating_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/cart_screen.dart';
import '../viewmodels/search_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import '../screens/create_post_screen.dart';
import '../models/mock_data.dart';
import 'media_player_widgets.dart';
import 'rating_dialog.dart';
import 'comment_section.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../helpers/translations.dart';
import '../helpers/database_helper.dart';
import 'albums_view.dart';
import 'tip_dialog.dart';
import '../viewmodels/register_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kPink = Color(0xFFDB2777);

// ─────────────────────────────────────────────────────────────────────────────
// MainContentArea widget
// ─────────────────────────────────────────────────────────────────────────────
class MainContentArea extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> posts;
  final String searchQuery;
  final List<MockUser> users;
  final Function(Map<String, dynamic>) onPostCreated;
  final Function(Map<String, dynamic>) onPostDeleted;
  final Function(Map<String, dynamic>, String, {dynamic extraData})
  onPostAction;
  final Function(Map<String, dynamic>)? onAddToCart;
  final MockUser currentUser;
  final MockUser? user;
  final List<Map<String, dynamic>> readPosts;
  final List<Map<String, dynamic>> watchedPosts;
  final List<Map<String, dynamic>> bookmarkedPosts;
  final Function(MockUser, String)? onUserAction;
  final Function(MockUser)? onUserTap;
  final VoidCallback? onInfoTap;
  final ValueNotifier<List<Map<String, dynamic>>>? cartItemsNotifier;
  final Function(Function(int))? onScrollToPostReady;
  final Function(
    Function(
      int, {
      bool expandComments,
      String? commentAuthor,
      String? commentText,
      dynamic commentId,
    }),
  )?
  onScrollToPostWithCommentsReady;
  final ValueNotifier<int>? selectedIndexNotifier;
  final bool isActive;
  final int? targetPostId;
  final VoidCallback? onRefresh;
  final MockUser? selectedUser;

  const MainContentArea({
    super.key,
    required this.posts,
    required this.searchQuery,
    required this.selectedUser,
    required this.users,
    this.user,
    required this.onPostCreated,
    required this.onPostDeleted,
    required this.onPostAction,
    this.onAddToCart,
    required this.currentUser,
    required this.readPosts,
    required this.watchedPosts,
    required this.bookmarkedPosts,
    this.onUserAction,
    this.onUserTap,
    this.onInfoTap,
    this.cartItemsNotifier,
    this.onScrollToPostReady,
    this.onScrollToPostWithCommentsReady,
    this.selectedIndexNotifier,
    this.isActive = true,
    this.targetPostId,
    this.onRefresh,
  });

  @override
  ConsumerState<MainContentArea> createState() => MainContentAreaState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class MainContentAreaState extends ConsumerState<MainContentArea>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  MockUser? _localUserOverride;

  MockUser get effectiveUser {
    if (_localUserOverride != null) return _localUserOverride!;
    final baseUser = widget.user ?? widget.currentUser;
    if (widget.users.isNotEmpty) {
      final idx = widget.users.indexWhere(
        (u) => u.username == baseUser.username,
      );
      if (idx != -1) return widget.users[idx];
    }
    return baseUser;
  }

  @override
  bool get wantKeepAlive => true;

  // Loading / refresh
  bool _isLoading = true;
  Timer? _loadingTimeoutTimer;
  Timer? _autoRefreshTimer;
  bool _autoRefreshTriggered = false;
  bool _isAutoRefreshing = false;
  int _autoRefreshAttempts = 0;
  static const int _maxAutoRefreshAttempts = 6;

  // UI state
  final Set<String> _typingPostIds = {};
  final Set<String> _expandedPostIds = {};
  final Set<String> _expandedContentIds = {};
  final Set<String> _expandedTitleIds = {};
  final ScrollController _scrollController = ScrollController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Map<int, GlobalKey> _postKeys = {};
  final Map<String, GlobalKey> _commentKeys = {};
  final Map<int, GlobalKey<CommentSectionState>> _commentSectionKeys = {};
  String? _highlightedCommentKey;
  final Set<String> _processingNotifications = {};
  List<Map<String, dynamic>> _albums = [];
  int? _currentlyPlayingPostId;
  DateTime _lastScrollUpdate = DateTime.now();
  final Map<int, double> _visibilityCache = {};
  Timer? _scrollDebounceTimer;
  bool _isUserInteracting = false;
  double? _savedScrollOffset;
  bool _showScrollbar = false;
  Timer? _scrollbarHideTimer;
  int _lastFeedIndex = 0;
  final Set<int> _previewingPosts = {};
  final Set<String> _unfollowedAuthors = {};

  // Search
  bool _isSearching = false;
  Timer? _searchTimer;
  String _activeSearchQuery = '';
  String? _searchError;

  // Tab index (0 = All Posts, 1 = My Posts, 2 = Bookmarks)
  int _selectedIndex = 0;

  // ── Public API ─────────────────────────────────────────────────────────────
  void resetToFeed() {
    if (_selectedIndex != 0) {
      if (mounted) {
        setState(() => _selectedIndex = 0);
        widget.selectedIndexNotifier?.value = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  bool _isHtmlContent(String text) => RegExp(r'<[a-zA-Z][^>]*>').hasMatch(text);

  bool _isFree(dynamic price) {
    if (price == null) return true;
    final p = price.toString().toLowerCase().replaceAll('\$', '').trim();
    return p == 'free' || p == '0' || p == '0.00';
  }

  bool _isOwnPost(Map<String, dynamic> post) {
    final postAuthor = post['author']?.toString().trim().toLowerCase() ?? '';
    final currentName = widget.currentUser.name.toString().trim().toLowerCase();
    final currentUsername = widget.currentUser.username
        .toString()
        .trim()
        .toLowerCase();
    if (postAuthor.isEmpty) return false;
    if (postAuthor == 'you') return true;
    if (currentUsername.isNotEmpty && postAuthor == currentUsername)
      return true;
    String strip(String s) => s
        .replaceAll(
          RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false),
          '',
        )
        .replaceAll(' ', '')
        .trim()
        .toLowerCase();
    return strip(postAuthor) == strip(currentName) ||
        strip(postAuthor) == strip(currentUsername);
  }

  bool _isSubscribedToAuthor(String author) {
    if (author.isEmpty) return false;
    if (author.toLowerCase().trim() == 'you') return true;
    String clean(String s) => s
        .replaceAll(
          RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false),
          '',
        )
        .replaceAll(' ', '')
        .trim()
        .toLowerCase();
    final target = clean(author);
    final idx = widget.users.indexWhere(
      (u) => clean(u.name) == target || clean(u.username) == target,
    );
    return idx != -1 && widget.users[idx].isSubscribed;
  }

  bool _isUnlocked(Map<String, dynamic> post) {
    if (_isOwnPost(post)) return true;
    if (_isFree(post['price'])) return true;
    if (post['is_purchased'] == true) return true;
    return _isSubscribedToAuthor(post['author']?.toString() ?? '');
  }

  MockUser _getAuthor(Map<String, dynamic> post) {
    final postAuthor = post['author']?.toString().trim() ?? '';
    if (postAuthor.isEmpty) return widget.currentUser;
    String clean(String s) => s
        .replaceAll(
          RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false),
          '',
        )
        .replaceAll(' ', '')
        .trim()
        .toLowerCase();
    final target = clean(postAuthor);
    return widget.users.firstWhere(
      (u) => clean(u.name) == target || clean(u.username) == target,
      orElse: () => MockUser(
        name: postAuthor,
        username: postAuthor.replaceAll(' ', '').toLowerCase(),
        avatar: '',
        type: 'other',
      ),
    );
  }

  int _countTopLevelComments(List<dynamic> comments) {
    if (comments.isEmpty) return 0;
    return comments.where((c) {
      if (c is! Map) return false;
      final pid = c['parentId'] ?? c['parent_id'];
      return pid == null || pid == '' || pid == 0 || pid == '0';
    }).length;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  bool _isUselessText(String text) {
    if (text.trim().isEmpty) return true;
    final lower = text.trim().toLowerCase();
    const bad = ['test', 'temp', 'hget', 'ddd', 'get', '...'];
    return bad.any((b) => lower == b || (b.length > 3 && lower.contains(b)));
  }

  // ── Filtered posts ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredPosts {


    int idx = _selectedIndex == 4 ? _lastFeedIndex : _selectedIndex;

    List<Map<String, dynamic>> base;
    if (idx == 0) {
      base = widget.posts.toList();
    } else if (idx == 1) {
      base = widget.posts.where((p) {
        final author = p['author'] as String? ?? '';
        return author.trim().toLowerCase() ==
            widget.currentUser.name.trim().toLowerCase();
      }).toList();
    } else if (idx == 2) {
      base = widget.bookmarkedPosts;
    } else {
      base = [];
    }

    return base.where((p) {
      if (widget.targetPostId != null &&
          p['id']?.toString() == widget.targetPostId.toString())
        return true;
      final author = p['author']?.toString().trim() ?? '';
      if (_unfollowedAuthors.contains(author)) return false;
      final fans = p['zippfansStatus'] ?? p['fans_status'] ?? 0;
      if (fans == 1 &&
          !_isOwnPost(p) &&
          (widget.targetPostId == null ||
              p['id'].toString() != widget.targetPostId.toString())) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    if (widget.posts.isNotEmpty) _isLoading = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVideoVisibilityImmediate();
      _triggerAutoRefreshIfNeeded();
    });

    widget.onScrollToPostReady?.call(_scrollToPost);
    widget.onScrollToPostWithCommentsReady?.call(_scrollToPostWithComments);
    widget.selectedIndexNotifier?.addListener(_onSelectedIndexChanged);
    if (widget.selectedIndexNotifier != null) {
      _selectedIndex = widget.selectedIndexNotifier!.value;
    }
    _loadAlbums();
    _startLoadingTimeout();
  }

  @override
  void didUpdateWidget(MainContentArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLoading && widget.posts.isNotEmpty) {
      _loadingTimeoutTimer?.cancel();
      _autoRefreshTimer?.cancel();
      _isAutoRefreshing = false;
      setState(() => _isLoading = false);
    }
    if (widget.onScrollToPostReady != oldWidget.onScrollToPostReady &&
        widget.onScrollToPostReady != null) {
      widget.onScrollToPostReady!(_scrollToPost);
    }
    if (widget.onScrollToPostWithCommentsReady !=
            oldWidget.onScrollToPostWithCommentsReady &&
        widget.onScrollToPostWithCommentsReady != null) {
      widget.onScrollToPostWithCommentsReady!(_scrollToPostWithComments);
    }
    if (oldWidget.selectedIndexNotifier != widget.selectedIndexNotifier) {
      oldWidget.selectedIndexNotifier?.removeListener(_onSelectedIndexChanged);
      widget.selectedIndexNotifier?.addListener(_onSelectedIndexChanged);
    }
    if (widget.currentUser.username != oldWidget.currentUser.username) {
      _loadAlbums();
    }
    if (oldWidget.posts != widget.posts) {
      _unfollowedAuthors.clear();
      if (mounted) setState(() {});
    }
    if (oldWidget.searchQuery != widget.searchQuery) {
      _handleSearchQueryChange();
    }
    if (oldWidget.posts.isNotEmpty && widget.posts.isEmpty) {
      _autoRefreshTriggered = false;
      _triggerAutoRefreshIfNeeded();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoRefreshTriggered = false;
      _triggerAutoRefreshIfNeeded();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _scrollbarHideTimer?.cancel();
    _loadingTimeoutTimer?.cancel();
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.selectedIndexNotifier?.removeListener(_onSelectedIndexChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ── Loading / auto-refresh ─────────────────────────────────────────────────
  void _startLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    });
  }

  void _triggerAutoRefreshIfNeeded() {
    if (!mounted || widget.onRefresh == null || widget.posts.isNotEmpty) return;
    if (!_autoRefreshTriggered) {
      _autoRefreshTriggered = true;
      _autoRefreshAttempts = 0;
    }
    _startAutoRefreshLoop();
  }

  void _startAutoRefreshLoop() {
    if (!mounted || widget.onRefresh == null) return;
    if (!_isLoading) setState(() => _isLoading = true);
    if (_isAutoRefreshing) return;
    _isAutoRefreshing = true;
    _autoRefreshTimer?.cancel();

    void tick() {
      if (!mounted || !_isAutoRefreshing) return;
      if (widget.posts.isNotEmpty) {
        _stopAutoRefreshLoop(keepLoading: false);
        return;
      }
      if (_autoRefreshAttempts >= _maxAutoRefreshAttempts) {
        _stopAutoRefreshLoop(keepLoading: true);
        return;
      }
      _autoRefreshAttempts++;
      widget.onRefresh!.call();
      final delay = (400 * _autoRefreshAttempts).clamp(400, 2400);
      _autoRefreshTimer = Timer(Duration(milliseconds: delay), tick);
    }

    tick();
  }

  void _stopAutoRefreshLoop({required bool keepLoading}) {
    _autoRefreshTimer?.cancel();
    _isAutoRefreshing = false;
    if (mounted && _isLoading) {
      _loadingTimeoutTimer?.cancel();
      setState(() => _isLoading = false);
    }
  }

  // ── Scroll / visibility ────────────────────────────────────────────────────
  void _onScroll() {
    if (!_showScrollbar) setState(() => _showScrollbar = true);
    _scrollbarHideTimer?.cancel();
    _scrollbarHideTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showScrollbar = false);
    });
    if (!mounted) return;
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      final now = DateTime.now();
      if (now.difference(_lastScrollUpdate).inMilliseconds < 50) return;
      _lastScrollUpdate = now;
      _checkVideoVisibilityImmediate();
    });
  }

  void _checkVideoVisibilityImmediate() {
    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    int? focusedId;
    if (_visibilityCache.length > 20) _visibilityCache.clear();

    for (final entry in _postKeys.entries) {
      final id = entry.key;
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final rb = ctx.findRenderObject();
      if (rb is! RenderBox || !rb.attached) continue;
      try {
        final offset = rb.localToGlobal(Offset.zero);
        final top = offset.dy;
        final height = rb.size.height;
        final bottom = top + height;
        final visTop = top < 0 ? 0.0 : top;
        final visBot = bottom > screenHeight ? screenHeight : bottom;
        final visH = visBot - visTop;
        if (visH <= 0) continue;
        final post = _filteredPosts.firstWhere(
          (p) => p['id'] == id,
          orElse: () => <String, dynamic>{},
        );
        final rawType = (post['type'] ?? post['post_type'] ?? '')
            .toString()
            .toLowerCase();
        final isMedia =
            rawType == 'video' ||
            rawType == 'reel' ||
            rawType == 'reels' ||
            rawType == 'song' ||
            rawType == 'audio';
        if (isMedia && visH / height > 0.0) {
          focusedId ??= id;
          if (visH / height >= 0.5) {
            focusedId = id;
            break;
          }
        }
      } catch (_) {}
    }

    if (mounted && focusedId != _currentlyPlayingPostId) {
      setState(() => _currentlyPlayingPostId = focusedId);
    }
  }

  // ── Notifier listeners ─────────────────────────────────────────────────────
  void _onSelectedIndexChanged() {
    if (widget.selectedIndexNotifier == null || !mounted) return;
    final newIdx = widget.selectedIndexNotifier!.value;
    if (newIdx >= 0 && _selectedIndex != newIdx) {
      setState(() {
        _selectedIndex = newIdx;
        if (newIdx < 3) _lastFeedIndex = newIdx;
      });
    }
  }

  void _handleSearchQueryChange() {
    _searchTimer?.cancel();
    if (widget.searchQuery.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _activeSearchQuery = '';
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _activeSearchQuery = widget.searchQuery;
      _searchError = null;
    });
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isSearching = false);
    });
  }

  // ── Scroll-to-post ─────────────────────────────────────────────────────────
  Future<void> _scrollToPost(int postId) async =>
      _scrollToPostWithComments(postId);

  void _scrollToPostWithComments(
    int postId, {
    bool expandComments = false,
    String? commentAuthor,
    String? commentText,
    dynamic commentId,
  }) {
    if (_isUserInteracting) return;
    int retries = 0;

    void attempt() {
      if (!mounted || _isUserInteracting) return;
      final idx = _filteredPosts.indexWhere(
        (p) => p['id'] == postId || p['id'].toString() == postId.toString(),
      );
      if (idx != -1) {
        if (expandComments) {
          final pidStr = postId.toString();
          if (!_expandedPostIds.contains(pidStr)) {
            setState(() => _expandedPostIds.add(pidStr));
          }
        }
        if (_scrollController.hasClients && _typingPostIds.isEmpty) {
          final est = idx * 500.0;
          if ((_scrollController.offset - est).abs() >
              MediaQuery.of(context).size.height * 2) {
            _scrollController.jumpTo(est);
          }
        }
        void scrollToKey(int vis) {
          if (!mounted || vis > 50) return;
          final key = _postKeys[postId];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              alignment: 0.1,
            );
          } else {
            Future.delayed(
              const Duration(milliseconds: 200),
              () => scrollToKey(vis + 1),
            );
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToKey(0));
        return;
      }
      if (retries < 30) {
        retries++;
        Future.delayed(const Duration(milliseconds: 100), attempt);
      }
    }

    attempt();
  }

  // ── Albums ─────────────────────────────────────────────────────────────────
  Future<void> _loadAlbums() async {
    try {
      final loaded = await _dbHelper.getAlbums(
        username: widget.currentUser.username,
      );
      if (mounted) setState(() => _albums = loaded);
    } catch (e) {
      debugPrint('Error loading albums: $e');
    }
  }

  void _deleteAlbum(Map<String, dynamic> album) {
    setState(() => _albums.remove(album));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.albumDeleted), backgroundColor: _kPink),
    );
    if (album['id'] != null) _dbHelper.deleteAlbum(album['id']);
  }

  void _showAlbumDetailsDialog(Map<String, dynamic> album) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text(album['title'] ?? 'Album')],
        ),
      ),
    );
  }

  void _showCreateAlbumDialog({Map<String, dynamic>? existingAlbum}) {}

  void _playAlbum(
    Map<String, dynamic> album, {
    List<Map<String, dynamic>>? allAlbums,
  }) {}

  // ── Share / report ─────────────────────────────────────────────────────────
  void _handleShare(Map<String, dynamic> post) async {
    final author = post['author'] == widget.currentUser.name
        ? context.tr.you
        : (post['author'] ?? context.tr.unknown);
    final text = '${post['title']}\n\nBy: $author\nShared from OpenZippers';
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr.linkCopied),
        backgroundColor: _kPink,
        duration: const Duration(seconds: 2),
      ),
    );
    await Share.share(text, subject: post['title']);
  }

  void _showReportDialog(Map<String, dynamic> post) {
    String selected = context.tr.selectCategory;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, ss) => Dialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr.reportPostFormTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MenuAnchor(
                    menuChildren:
                        [
                              context.tr.categorySpam,
                              context.tr.categoryInappropriate,
                              context.tr.categoryHarassment,
                              context.tr.categoryFalseInfo,
                              context.tr.categoryCopyright,
                              context.tr.categoryOther,
                            ]
                            .map(
                              (e) => MenuItemButton(
                                onPressed: () => ss(() => selected = e),
                                child: Text(e),
                              ),
                            )
                            .toList(),
                    builder: (_, controller, __) => OutlinedButton(
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                      child: Text(selected),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: context.tr.enterDescription,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr.reportSubmitted),
                          backgroundColor: _kPink,
                        ),
                      );
                    },
                    child: Text(context.tr.submit),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleEditPost(Map<String, dynamic> post) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(existingPost: post),
      ),
    );
    if (updated != null && updated is Map<String, dynamic>) {
      widget.onPostAction(updated, 'Update');
    }
  }

  Future<void> _navigateToCreatePost({String? initialType}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(initialType: initialType),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      widget.onPostCreated(result);
      if (mounted) {
        setState(() => _selectedIndex = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.postCreatedSuccessfully),
            backgroundColor: _kPink,
          ),
        );
      }
    }
  }

  void _toggleComments(String id) {
    setState(() {
      if (_expandedPostIds.contains(id)) {
        _expandedPostIds.remove(id);
      } else {
        _expandedPostIds.add(id);
      }
    });
  }

  void _showRatingDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (dialogContext) => RatingDialog(
        post: post,
        onSubmit: (stars) async {
          try {
            await ref
                .read(submitRatingProvider.notifier)
                .submitRating(postId: post['id'], rating: stars);

            if (!mounted) return;

            setState(() {
              post['my_rating'] = stars;
              post['user_rating'] = stars;

              final currentTotal =
                  (post['total_ratings'] ?? post['totalRatings'] ?? 0) as int;

              post['total_ratings'] = currentTotal + 1;
              post['totalRatings'] = currentTotal + 1;

              post['average_rating'] = stars.toDouble();
              post['averageRating'] = stars.toDouble();
            });

            ref.invalidate(ratingProvider(post['id']));

            widget.onRefresh?.call();

            Navigator.of(dialogContext).pop();

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Rating submitted!')));
          } catch (e) {
            debugPrint('Rating Error: $e');
          }
        },
      ),
    );
  }

  void _showInfoDialog(Map<String, dynamic> post) {}

  void _showContentDetails(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E2A44)
              : Theme.of(context).textTheme.bodyLarge?.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Content Details",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _row(context, "Likes", "${post['likeCount'] ?? 0}"),
              _row(context, "Comments", "${post['commentsCount'] ?? 0}"),
              _row(
                context,
                "Type",
                "${post['type'] ?? post['post_type'] ?? 'N/A'}",
              ),
              _row(context, "Size", "${post['file_size'] ?? 'N/A'}"),
              _row(
                context,
                "Dimension",
                "${post['post_width'] ?? 0} × ${post['post_height'] ?? 0}",
              ),
              _row(context, "Uploaded On", _formatDate(post['date'])),
            ],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final searchState = ref.watch(searchProvider);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20.0 : 16.0,
        vertical: 16.0,
      ),
      child: IndexedStack(
        index: _selectedIndex == 4 ? 1 : 0,
        children: [
          // ── Main feed / search ──────────────────────────────────────────
          Builder(
            builder: (context) {
              if (_isLoading) return _buildShimmerLoader();

              final showSearch =
                  searchState.users.isNotEmpty && widget.searchQuery.isNotEmpty;

              return ListView.builder(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                cacheExtent: 3000,
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _filteredPosts.length + 1 + (showSearch ? 1 : 0),
                itemBuilder: (context, index) {
                  // Row 0 → header
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildFeedHeader(),
                    );
                  }
                  int adj = index - 1;

                  // Row 1 (when searching) → search results panel
                  if (showSearch) {
                    if (adj == 0) {
                      return _buildUserSearchResults(searchState);
                    }
                    adj--;
                  }

                  if (adj < _filteredPosts.length) {
                    final post = _filteredPosts[adj];
                    final postId = post['id'] is int
                        ? post['id'] as int
                        : post.hashCode;
                    final key = _postKeys.putIfAbsent(
                      postId,
                      () => GlobalKey(),
                    );
                    return RepaintBoundary(
                      key: key,
                      child: _buildPostCard(post),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),

          // ── Albums tab ─────────────────────────────────────────────────
          AlbumsView(
            currentUser: widget.currentUser,
            albums: _albums,
            onCreateAlbum: () => _showCreateAlbumDialog(),
            onDeleteAlbum: _deleteAlbum,
            onEditAlbum: (album) =>
                _showCreateAlbumDialog(existingAlbum: album),
            onViewAlbum: (album) => _playAlbum(album, allAlbums: _albums),
            onShowDetails: _showAlbumDetailsDialog,
            isOwner: true,
            isScrollable: true,
          ),
        ],
      ),
        ), );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEARCH RESULTS PANEL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildUserSearchResults(SearchState searchState) {
    final theme = Theme.of(context);

    // Loading spinner
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _kPink),
            ),
            const SizedBox(height: 10),
            Text(
              'Searching…',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    // No results
    if (searchState.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 52,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 14),
            Text(
              'No users found for\n"${widget.searchQuery}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Results list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 19, color: _kPink),
              const SizedBox(width: 8),
              Text(
                'People',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${searchState.users.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── User cards ────────────────────────────────────────────────────
        ...searchState.users.take(8).map((user) {
          return _SearchUserCard(
            name: user.name,
            username: user.username,
            avatar: user.avatar,
            postsCount: user.postsCount,
            onTap: () {
              final mockUser = MockUser(
                username: user.username,
                name: user.name,
                avatar: user.avatar,
                coverImage: '',
                isVerified: false,
                bio: '',
                type: 'public',
                country: '',
                state: '',
                city: '',
                gender: '',
              );
              // Clear search and go to profile properly
              FocusScope.of(context).unfocus();
              widget.onUserTap?.call(mockUser);
            },
          );
        }),

        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEED HEADER (tab bar)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFeedHeader() {
    return Row(
      children: [
        Expanded(
          child: _buildHeaderTab(
            icon: Icons.web_stories,
            label: context.tr.allPosts,
            isActive: _selectedIndex == 0,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildHeaderTab(
            icon: Icons.person_outline,
            label: context.tr.myPosts,
            isActive: _selectedIndex == 1,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildHeaderTab(
            icon: Icons.bookmark_border,
            label: context.tr.bookmarks,
            isActive: _selectedIndex == 2,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildHeaderTab(
            icon: Icons.edit_outlined,
            label: context.tr.createPost,
            isActive: false,
            onTap: _navigateToCreatePost,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final color = isActive ? _kPink : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _kPink.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _kPink : theme.dividerColor,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // POST CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPostCard(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final author = _getAuthor(post);
    final postIdStr = post['id']?.toString() ?? '';
    final avgRating =
        double.tryParse(
          (post['average_rating'] ?? post['averageRating'] ?? 0).toString(),
        ) ??
        0.0;

    final totalRatings = post['total_ratings'] ?? post['totalRatings'] ?? 0;

    final commentCount =
        post['commentsCount'] ??
        _countTopLevelComments(post['comments'] as List? ?? []);
    final isLiked = widget.readPosts.any((p) => p['id'] == post['id']);
    final isBookmarked = widget.bookmarkedPosts.any(
      (p) => p['id'] == post['id'],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: GestureDetector(
              onTap: () => widget.onUserTap?.call(author),
              // child: _buildAvatar(author.avatar, radius: 22),
              child: _buildAvatar(post['avatar'] ?? '', radius: 22),
            ),
            title: GestureDetector(
              onTap: () => widget.onUserTap?.call(author),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      // post['author'] ?? 'User',
                      post['author']?.toString().trim() ?? '',
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (post['verified'] == true || author.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.verified, size: 15, color: _kPink),
                    ),
                ],
              ),
            ),
            subtitle: Text(
              _formatDate(post['date']),
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuTheme(
              data: PopupMenuThemeData(
                color: const Color(0xFF14233D),
                surfaceTintColor: Colors.transparent,
                textStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    textStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                child: PopupMenuButton<String>(
                  color: const Color(0xFF14233D),
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onSelected: (val) async {
                    final author = _getAuthor(post);
                    switch (val) {
                      case 'share':
                        _handleShare(post);
                        break;

                      case 'bookmark':
                        widget.onPostAction(post, 'ToggleBookmark');
                        break;

                      case 'report':
                        _showReportDialog(post);
                        break;

                      case 'edit':
                        _handleEditPost(post);
                        break;

                      case 'delete':
                        widget.onPostDeleted(post);
                        break;

                      case 'unfollow':
                        setState(() => _unfollowedAuthors.add(
                            post['author']?.toString().trim() ?? ''));
                        widget.onUserAction?.call(author, 'Unfollow');
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unfollowed ${author.name}')));
                        break;

                      case 'block':
                      // Call blockProvider directly for instant UI feedback
                        final userId = author.id;
                        if (userId != null) {
                          try {
                            final res = await ref
                                .read(blockProvider.notifier)
                                .toggleBlock(userId);
                            if (res != null && mounted) {
                              // Remove their posts from feed instantly
                              setState(() => _unfollowedAuthors.add(
                                  post['author']?.toString().trim() ?? ''));
                              widget.onUserAction?.call(author, 'Block');
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res.message)));
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                          }
                        } else {
                          // fallback if no server id
                          widget.onUserAction?.call(author, 'Block');
                          setState(() => _unfollowedAuthors.add(
                              post['author']?.toString().trim() ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${author.name} blocked')));
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Share Post',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuItem<String>(
                      value: 'send_to_ozvault',
                      child: Row(
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Send To OzVault',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuItem<String>(
                      value: 'playlist',
                      child: Row(
                        children: [
                          Icon(
                            Icons.playlist_add_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Add to Playlist',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuItem<String>(
                      value: 'bookmark',
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Bookmark this post',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    if (!_isOwnPost(post))
                      const PopupMenuItem<String>(
                        value: 'unfollow',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_remove_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Unfollow',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                    if (!_isOwnPost(post))
                      const PopupMenuItem<String>(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(
                              Icons.block_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Block',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                    if (!_isOwnPost(post))
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Report',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                    if (_isOwnPost(post))
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 12),
                            Text('Edit', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),

                    if (_isOwnPost(post))
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Title ────────────────────────────────────────────────────────
          if (post['title'] != null && post['title'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                post['title'],
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

          // ── Body text ────────────────────────────────────────────────────
          if ((post['text'] ?? post['content']) != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Builder(
                builder: (_) {
                  final raw = (post['text'] ?? post['content'] ?? '')
                      .toString();
                  if (_isHtmlContent(raw)) {
                    return Text(
                      _stripHtml(raw),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    );
                  }
                  return Text(
                    raw,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  );
                },
              ),
            ),

          // ── Media ─────────────────────────────────────────────────────────

          // ── Action bar ───────────────────────────────────────────────────────
          // ── Media ─────────────────────────────────────────────────────────────

          if (_isUnlocked(post))
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 180,
                      maxHeight: 500,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildMediaPreview(post),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: InkWell(
                      onTap: () => _showContentDetails(post),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildLockedOverlay(context, post),
              ],
            ),

          // ── Action bar ───────────────────────────────────────────────────────
          if (_isUnlocked(post))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked
                        ? _kPink
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                    label: '${post['likeCount'] ?? 0}',
                    onTap: () => widget.onPostAction(post, 'Like'),
                  ),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: _expandedPostIds.contains(postIdStr)
                        ? _kPink
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87),
                    label: '$commentCount',
                    onTap: () => _toggleComments(postIdStr),
                  ),
                  GestureDetector(
                    onTap: () => _showRatingDialog(post),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color:
                                (post['user_rating'] != null &&
                                    post['user_rating'] != 0)
                                ? Colors.amber
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            avgRating > 0 ? avgRating.toStringAsFixed(1) : '0',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Comments section ─────────────────────────────────────────────
          if (_expandedPostIds.contains(postIdStr))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: CommentSection(
                post: post,
                currentUser: widget.currentUser,
                users: widget.users,
                onPostAction: (p, a, {extraData}) {
                  widget.onPostAction(p, a, extraData: extraData);
                  if (mounted) setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 21),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MEDIA PREVIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMediaPreview(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final type = (post['type'] ?? '').toString();
    final videoPath = (post['video_url'] ?? post['filePath'] ?? '').toString();
    final audioPath = (post['audio_url'] ?? post['filePath'] ?? '').toString();
    final imagePath = (post['image'] ?? post['filePath'] ?? '').toString();
    final previewPath = (post['preview_url'] ?? '').toString();
    final litPath = (post['literature_url'] ?? post['filePath'] ?? '')
        .toString();
    final title = (post['title'] ?? 'Document').toString();

    // ── Video ─────────────────────────────────────────────────────────────
    if (type == 'Video' || type == 'Reel' || type == 'Reels') {
      if (videoPath.isEmpty) return _buildEmptyMedia();
      return SizedBox(
        height: 420,
        width: double.infinity,
        child: VideoPlayerWidget(
          videoPath: videoPath,
          coverPath: previewPath.isNotEmpty
              ? previewPath
              : (imagePath.isNotEmpty ? imagePath : null),
          autoPlay: false,
          showPlayButton: true,
          showEnlargeButton: false,
        ),
      );
    }

    // ── Audio ─────────────────────────────────────────────────────────────
    if (type == 'Song' || type == 'Audio') {
      if (audioPath.isEmpty) return _buildEmptyMedia();
      return AudioPlayerWidget(
        audioPath: audioPath,
        coverPath: imagePath.isNotEmpty ? imagePath : null,
        autoPlay: true,
        showEnlargeButton: false,
      );
    }

    // ── Image ─────────────────────────────────────────────────────────────
    if (type == 'Image') {
      if (imagePath.isEmpty) return _buildEmptyMedia();
      return GestureDetector(
        onTap: () => _openFullscreenImage(imagePath),
        child: Stack(
          children: [
            imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _buildEmptyMedia(),
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.zoom_out_map,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Literature ────────────────────────────────────────────────────────
    if (type == 'Literature') {
      if (litPath.isEmpty) return _buildEmptyMedia();
      return GestureDetector(
        onTap: () => _openFullscreenPdf(litPath, title),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 60, color: _kPink),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _kPink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Open Document',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildEmptyMedia();
  }

  Widget _buildEmptyMedia() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLockedOverlay(BuildContext context, Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final imagePath =
        (post['image'] ?? post['preview_url'] ?? post['filePath'] ?? '')
            .toString();
    final hasPreview = imagePath.isNotEmpty && imagePath.startsWith('http');

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // ── Blurred background image ──────────────────────────────────
          if (hasPreview)
            SizedBox(
              height: 320,
              width: double.infinity,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 320, color: theme.cardColor),
                ),
              ),
            )
          else
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),

          // ── Dark overlay ──────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // ── Lock content ──────────────────────────────────────────────
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPink.withOpacity(.2),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Premium Content",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Subscribe to unlock this content",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                  child: Text(
                    "₹${post["price"] ?? "0"}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 32),
                //   child: SizedBox(
                //     width: double.infinity,
                //     height: 48,
                //     child: ElevatedButton.icon(
                //      onPressed:
                //           ? null
                //           : () async {
                //         //await ref
                //           //  .read(paymentViewModelProvider.notifier)
                //           //  .buyPost(postId: post["id"]);
                //
                //         await ref.refresh(cartProvider.future);
                //
                //         if (mounted) {
                //           Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (_) => const CartScreen(),
                //             ),
                //           );
                //         }
                //       },
                //       // icon: paymentState.isLoading
                //       //     ? const SizedBox(
                //       //         width: 16,
                //       //         height: 16,
                //       //         child: CircularProgressIndicator(
                //       //           strokeWidth: 2,
                //       //           color: Colors.white,
                //       //         ),
                //       //       )
                //       //     : const Icon(
                //       //         Icons.shopping_cart_outlined,
                //       //         color: Colors.white,
                //       //         size: 18,
                //       //       ),
                //       label: Text(
                //         //paymentState.isLoading
                //           //  ? "Processing..."
                //              "Add to Cart",
                //         style: const TextStyle(
                //           color: Colors.white,
                //           fontSize: 14,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: _kPink,
                //         foregroundColor: Colors.white,
                //         elevation: 0,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(12),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        widget.onAddToCart?.call(post);

                        ref.invalidate(cartProvider);
                        await ref.refresh(cartProvider.future);

                        if (!mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreenImage(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: url.startsWith('http')
                  ? Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 64,
                      ),
                    )
                  : Image.file(File(url), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullscreenPdf(String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title, overflow: TextOverflow.ellipsis),
            backgroundColor: _kPink,
            foregroundColor: Colors.white,
          ),
          body: url.startsWith('http')
              ? SfPdfViewer.network(url)
              : SfPdfViewer.file(File(url)),
        ),
      ),
    );
  }

  // ── Avatar helper ──────────────────────────────────────────────────────────
  Widget _buildAvatar(String avatar, {double radius = 20}) {
    if (avatar.isNotEmpty &&
        (avatar.startsWith('http://') || avatar.startsWith('https://'))) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatar),
        onBackgroundImageError: (_, __) {},
        backgroundColor: _kPink.withOpacity(0.2),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _kPink.withOpacity(0.2),
      child: Icon(Icons.person, color: _kPink, size: radius),
    );
  }

  // Widget _buildAvatar(String avatar, {double radius = 20}) {
  //   if (avatar.isNotEmpty && avatar.startsWith('http')) {
  //     return CircleAvatar(
  //       radius: radius,
  //       backgroundImage: NetworkImage(avatar),
  //     );
  //   }
  //
  //
  //   return CircleAvatar(
  //     radius: radius,
  //     backgroundImage: NetworkImage(avatar),
  //   );
  // }

  // ── Shimmer / empty ────────────────────────────────────────────────────────
  Widget _buildShimmerLoader() {
    return const Center(child: CircularProgressIndicator(color: _kPink));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEARCH USER CARD  (private top-level widget)
// ══════════════════════════════════════════════════════════════════════════════
class _SearchUserCard extends StatelessWidget {
  final String name;
  final String username;
  final String avatar;
  final int postsCount;
  final VoidCallback onTap;

  const _SearchUserCard({
    required this.name,
    required this.username,
    required this.avatar,
    required this.postsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with pink ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kPink.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _kPink.withValues(alpha: 0.1),
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  child: avatar.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: _kPink,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(width: 14),

              // Name / username / post count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    if (postsCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 11,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$postsCount post${postsCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Tap indicator
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
