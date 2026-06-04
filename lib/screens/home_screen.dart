import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/translations.dart';
import 'package:sqflite/sqflite.dart';
import '../network/api_client.dart';
import '../providers/rating_provider.dart';
import '../viewmodels/comment_viewmodel.dart';
import '../viewmodels/search_viewmodel.dart';
import 'albums_screen.dart';
import 'literature_pdf_viewer_screen.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../viewmodels/like_viewmodel.dart';
import '../widgets/left_sidebar.dart';
import '../widgets/main_content_area.dart';
import '../widgets/right_sidebar.dart';
import '../widgets/top_search_bar.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'connections_screen.dart';
import 'settings_screen.dart';
import 'suggestions_screen.dart';
import 'cart_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'subscriptions_page.dart';
import 'individual_post_screen.dart';
import 'reels_screen.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../main.dart';
import '../models/mock_data.dart';
import '../helpers/database_helper.dart';
import 'copyright_screen.dart';
import 'publishing_screen.dart';
import 'create_post_screen.dart';
import '../helpers/post_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/register_view_model.dart';
import '../viewmodels/login_view_model.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _searchQuery = "";
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _communityPosts = [];
  List<Map<String, dynamic>> _samplePosts = [];
  int _currentIndex = 0;
  List<MockUser> _allUsers = [];
  late PageController _pageController;
  MockUser? _selectedSuggestedUser;
  MockUser? _selectedHomeUser;
  bool _hasSyncedPageAfterRebuild = false;
  bool _isArtist = false;
  String? _authToken;
  bool _feedLoaded = false;

  final ValueNotifier<int> _mainContentSelectedIndexNotifier =
  ValueNotifier<int>(0);
  final GlobalKey<MainContentAreaState> _mainContentKey =
  GlobalKey<MainContentAreaState>();
 // final GlobalKey<ReelsScreenState> _reelsKey = GlobalKey<ReelsScreenState>();

  final Map<String, dynamic> _defaultPost = {
    'type': 'Image',
    'title': 'Sweet Strawberry',
    'price': 'Free',
    'content': 'Check out this fresh strawberry from the garden!',
    'author': '',
    'isUserPost': true,
    'date': DateTime.now().subtract(const Duration(hours: 1)),
    'readCount': 0,
    'watchCount': 0,
    'likeCount': 0,
    'ratingCount': 0,
    'averageRating': 0.0,
    'totalRatings': 0,
    'comments': [],
  };

  final List<Map<String, dynamic>> _samplePostsSource = [];

  List<Map<String, dynamic>> _readPosts = [];
  List<Map<String, dynamic>> _commentedPosts = [];
  List<Map<String, dynamic>> _watchedPosts = [];
  List<Map<String, dynamic>> _communityPostsTemp = [];
  List<Map<String, dynamic>> _notifications = [];

  bool _notificationsEnabled = true;
  bool _likeNotificationsEnabled = true;
  bool _commentNotificationsEnabled = true;
  bool _newSubNotificationsEnabled = true;
  bool _tipNotificationsEnabled = true;
  bool _messageNotificationsEnabled = true;
  bool _expiringSubNotificationsEnabled = false;
  bool _upcomingRenewalNotificationsEnabled = false;
  String? _connectionsHighlightUser;
  List<Map<String, dynamic>> _bookmarkedPosts = [];
  final ValueNotifier<List<Map<String, dynamic>>> _cartItemsNotifier =
  ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _notificationsNotifier =
  ValueNotifier([]);

  Function(int)? _scrollToPostCallback;
  Function(
      int, {
      bool expandComments,
      String? commentAuthor,
      String? commentText,
      dynamic commentId,
      })? _scrollToPostWithCommentsCallback;
  int? _targetPostIdFromNotification;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _allUsers = MockCommunity.generateUsers();
    _pageController = PageController(initialPage: _currentIndex);
    _hasSyncedPageAfterRebuild = true;
    _pageController.addListener(_pageControllerListener);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeedFromApi();
    });
  }

  void _pageControllerListener() {
    if (!_pageController.hasClients || _hasSyncedPageAfterRebuild || !mounted)
      return;
    if (_pageController.position.isScrollingNotifier.value) return;
    try {
      final currentPage = _pageController.page?.round();
      if (currentPage != null && currentPage != _currentIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _pageController.hasClients &&
              !_hasSyncedPageAfterRebuild) {
            _pageController.jumpToPage(_currentIndex);
            _hasSyncedPageAfterRebuild = true;
          }
        });
      }
    } catch (e) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    try {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.detached) {
        _saveNotifications();
        _saveUserPosts();
        _saveCommunityPosts();
      } else if (state == AppLifecycleState.resumed) {
        _loadRelationships();
      }
    } catch (e) {
      debugPrint("Error handling app lifecycle: $e");
    }
  }

  void _syncPageController() {
    if (!_hasSyncedPageAfterRebuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performPageSync();
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _performPageSync();
      });
    }
  }

  void _performPageSync() {
    if (mounted && _pageController.hasClients && !_hasSyncedPageAfterRebuild) {
      try {
        final currentPage = _pageController.page?.round();
        if (currentPage == null || currentPage != _currentIndex) {
          _pageController.jumpToPage(_currentIndex);
        }
        _hasSyncedPageAfterRebuild = true;
      } catch (e) {
        _hasSyncedPageAfterRebuild = true;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.removeListener(_pageControllerListener);
    _pageController.dispose();
    _cartItemsNotifier.dispose();
    _notificationsNotifier.dispose();
    _saveCommunityPosts();
    super.dispose();
  }

  // MockUser _getCurrentUser() {
  //   if (_allUsers.isEmpty) {
  //     return MockUser(
  //       username: 'default',
  //       name: 'Default User',
  //       avatar: '',
  //       coverImage: '',
  //       isVerified: false,
  //       bio: '',
  //       type: 'creator',
  //       country: '',
  //       state: '',
  //       city: '',
  //       gender: '',
  //     );
  //   }
  //
  //   return _allUsers[0];
  // }
  MockUser _getCurrentUser() {

    if (_allUsers.isEmpty) {
      return MockUser(
        username: '',
        name: '',
        avatar: '',
        coverImage: '',
        isVerified: false,
        bio: '',
        type: '',
        country: '',
        state: '',
        city: '',
        gender: '',
      );
    }

    final current = _allUsers.firstWhere(

          (u) => u.username ==
          (_authToken != null
              ? _allUsers.first.username
              : ''),

      orElse: () => _allUsers.first,
    );

    return current;
  }
  Future<void> _loadRelationships() async {
    final currentUser = _getCurrentUser();
    if (currentUser.username.isEmpty) return;

    try {
      final relationships =
      await _dbHelper.getRelationships(currentUser.username);

      final followingCount = relationships.values
          .where((v) => v == 'following' || v == 'subscribed' || v == 'mutual')
          .length;
      if (followingCount == 0 && _allUsers.isNotEmpty) {
        final usersToFollow =
        _allUsers.where((u) => u.isArtist).take(5).toList();
        if (usersToFollow.isEmpty) {
          usersToFollow.addAll(
            _allUsers
                .where((u) => u.username != currentUser.username)
                .take(3),
          );
        }
        for (var u in usersToFollow) {
          await _dbHelper.followUser(currentUser.username, u.username);
          relationships[u.username] = 'following';
        }
      }

      setState(() {
        for (int i = 0; i < _allUsers.length; i++) {
          final user = _allUsers[i];
          if (user.username == currentUser.username) continue;

          String newType = 'public';
          bool isSubscribed = false;

          if (relationships.containsKey(user.username)) {
            newType = relationships[user.username]!;
            isSubscribed = (newType == 'subscribed');
          } else {
            newType = 'public';
          }

          if (user.type != newType || user.isSubscribed != isSubscribed) {
            _allUsers[i] = user.copyWith(
              type: newType,
              isSubscribed: isSubscribed,
            );
          }
        }

        if (_selectedHomeUser != null) {
          final idx = _allUsers
              .indexWhere((u) => u.username == _selectedHomeUser!.username);
          if (idx != -1) _selectedHomeUser = _allUsers[idx];
        }
      });
    } catch (e) {
      debugPrint("Error loading relationships: $e");
    }
  }

  String _getPostType(Map<String, dynamic> post) {
    return PostHelper.getPostType(post);
  }

  Map<String, dynamic> _normalizePost(Map<String, dynamic> post) {
    return PostHelper.normalizePost(post);
  }
  String _toWidgetType(String postType) {
    switch (postType.toLowerCase()) {
      case 'video': return 'Video';
      case 'audio': return 'Audio';
      case 'literature': return 'Literature';
      case 'post': return 'Image';
      default: return 'Image';
    }
  }
  Future<void> _loadFeedFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    debugPrint('=== FEED LOAD TRIGGERED ===');
    debugPrint('=== TOKEN: $token ===');

    if (token == null || token.isEmpty) {
      debugPrint('=== NO TOKEN FOUND - ABORTING ===');
      return;
    }

    try {
      await ref.read(feedViewModelProvider.notifier).loadFeed();
      final feedState = ref.read(feedViewModelProvider);

      debugPrint('=== FEED STATUS: ${feedState.status} ===');
      debugPrint('=== FEED POSTS: ${feedState.posts.length} ===');
      debugPrint('=== FEED ERROR: ${feedState.errorMessage} ===');

      if (feedState.posts.isNotEmpty && mounted) {
        // final mapped = feedState.posts.map((p) => {
        //   'id': p.id,
        //   'title': p.title,
        //   'author': p.user.name,
        //
        //   // ── Avatar fixes ──────────────────────────
        //   'avatar': p.user.avatar ?? '',
        //   'avatar_url': p.user.avatar ?? '',
        //   'authorAvatar': p.user.avatar ?? '',   // ← ADD
        //   'userAvatar': p.user.avatar ?? '',     // ← ADD
        //
        //   'text': p.text,
        //   'content': p.text,                     // ← ADD (some widgets use 'content')
        //
        //   // ── Type fixes ────────────────────────────
        //   'type': _toWidgetType(p.postType.name), // ← ADD (widget reads 'type')
        //   'post_type': p.postType.name,           // keep existing
        //
        //   // ── Media URLs ────────────────────────────
        //   'image': p.image,
        //   'audio_url': p.audioUrl,
        //   'video_url': p.videoUrl,
        //   'literature_url': p.literatureUrl,
        //   'preview_url': p.previewUrl,
        //   'duration': p.duration,
        //
        //   'likeCount': p.likesCount,
        //   'commentsCount': p.commentsCount,
        //   'comments': p.comments,
        //   'is_liked': p.isLiked,
        //   'is_bookmarked': p.isBookmarked,
        //   'is_premium': p.isPremium,
        //   'price': p.price,
        //   'in_cart': p.inCart,
        //   'is_purchased': p.isPurchased,
        //   'vat_percent': p.vatPercent,
        //   'average_rating': p.averageRating,
        //   'total_ratings': p.totalRatings,
        //   'date': p.createdAt,
        //   'views': p.views,
        //   'fans_status': p.fansStatus,
        //   'isUserPost': false,
        //   'verified': p.user.verified,           // ← ADD
        // }).toList();

        final mapped = <Map<String, dynamic>>[];

        for (final p in feedState.posts) {
          int width = 0;
          int height = 0;

          if (p.image != null && p.image!.isNotEmpty) {
            try {
              final size = await getImageSize(p.image!);
              width = size.width.toInt();
              height = size.height.toInt();
            } catch (_) {}
          }

          mapped.add({
            'id': p.id,
            'title': p.title,
            'author': p.user.name,

            'average_rating': p.averageRating,
            'total_ratings': p.totalRatings,

            'user_rating': p.userRating,

            'image': p.image,
            'likeCount': p.likesCount,
            'commentsCount': p.commentsCount,
          });
          setState(() {
            _communityPosts = mapped;
            _feedLoaded = true;
          });

          await _saveCachedFeed(prefs, mapped);
        }
      }} catch (e, stack) {
      debugPrint('=== FEED EXCEPTION: $e ===');
      debugPrint('=== STACK: $stack ===');
    }
  }
  Future<Size> getImageSize(String imageUrl) async {
    final completer = Completer<Size>();

    final image = NetworkImage(imageUrl);

    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        completer.complete(
          Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ),
        );
      }),
    );

    return completer.future;
  }
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUsername = prefs.getString('current_user_username');
    final String? savedName = prefs.getString('user_name');       // ← ADD
    final String? savedAvatar = prefs.getString('user_avatar');   // ← ADD
    final String? authToken = prefs.getString('auth_token');
    if (mounted) setState(() => _authToken = authToken);
    final bool isArtistPref = prefs.getBool('is_artist') ?? false;
    final bool isMigrated = prefs.getBool('db_migrated') ?? false;
    if (_communityPosts.isEmpty) {
      final cached = _loadCachedFeed(prefs);
      if (cached.isNotEmpty && mounted) {
        setState(() => _communityPosts = cached);
      }
    }
// Pre-populate _allUsers so _getCurrentUser() works immediately
    if (_allUsers.isEmpty && savedName != null && currentUsername != null) {
      setState(() {
        _allUsers = [MockUser(
          username: currentUsername,
          name: savedName,
          avatar: savedAvatar ?? '',
          coverImage: '',
          isVerified: false,
          bio: '',
          type: 'creator',
          country: '',
          state: '',
          city: '',
          gender: '',
        )];
      });
    }
    if (mounted) {
      setState(() {
        _isArtist = isArtistPref;
      });
    }

    if (!isMigrated) {
      await _migrateToDatabase(prefs);
      await prefs.setBool('db_migrated', true);
    }

    // Cold-start cache: show last-known feed immediately so the home
    // screen has content the moment the app reopens (even before the
    // network call resolves, or when offline).


    // if (authToken != null && authToken.isNotEmpty && !_feedLoaded) {
    //   try {
    //     await ref.read(feedViewModelProvider.notifier).loadFeed();
    //     var feedState = ref.read(feedViewModelProvider);
    //
    //     // One automatic retry on transient failure / empty result
    //     if (feedState.hasError || feedState.posts.isEmpty) {
    //       debugPrint('HomeFeed: retrying after error=${feedState.errorMessage} / empty');
    //       await ref.read(feedViewModelProvider.notifier).refresh();
    //       feedState = ref.read(feedViewModelProvider);
    //     }
    //
    //     final profile = feedState.userProfile;
    //     if (profile != null && profile.success && profile.data != null) {
    //       final user = profile.data!.user;
    //       await prefs.setInt('role_id', user.roleId);
    //       await prefs.setBool('is_artist', user.isArtist ?? false);
    //       await prefs.setString('user_name', user.name);
    //       await prefs.setString('user_avatar', user.avatarUrl ?? '');
    //
    //       if (mounted) {
    //         setState(() {
    //           _isArtist = user.isArtist ?? false;
    //           final idx =
    //           _allUsers.indexWhere((u) => u.username == user.username);
    //           if (idx != -1) {
    //             _allUsers[idx] = _allUsers[idx].copyWith(
    //               isArtist: user.isArtist ?? false,
    //               name: user.name,
    //               avatar: user.avatarUrl ?? '',
    //             );
    //           }
    //         });
    //       }
    //     }
    //
    //     if (feedState.hasError) {
    //       debugPrint("Feed load reported error: ${feedState.errorMessage}");
    //     }
    //
    //     final posts = feedState.posts;
    //     debugPrint('HomeFeed: API returned ${posts.length} posts');
    //     if (posts.isNotEmpty) {
    //       final mapped = posts.where((p) {
    //         // Show every post the API hands back. The backend already
    //         // decides what the current user is entitled to see for the
    //         // zippfans feed — don't double-filter premium/fans content
    //         // on the client, or we end up dropping the entire feed.
    //         return true;
    //       }).map((p) => {
    //         'id': p.id,
    //         'title': p.title,
    //         'author': p.user.name,
    //         'avatar': p.user.avatar ?? '',
    //         'avatar_url': p.user.avatar ?? '',
    //         'text': p.text,
    //         'image': p.image,
    //         'audio_url': p.audioUrl,
    //         'video_url': p.videoUrl,
    //         'literature_url': p.literatureUrl,
    //         'preview_url': p.previewUrl,
    //         'duration': p.duration,
    //         'likeCount': p.likesCount,
    //         'commentsCount': p.commentsCount,
    //         'comments': p.comments,
    //         'is_liked': p.isLiked,
    //         'is_bookmarked': p.isBookmarked,
    //         'is_premium': p.isPremium,
    //         'post_type': p.postType.name,
    //         'price': p.price,
    //         'in_cart': p.inCart,
    //         'is_purchased': p.isPurchased,
    //         'vat_percent': p.vatPercent,
    //         'average_rating': p.averageRating,
    //         'total_ratings': p.totalRatings,
    //         'date': p.createdAt,
    //         'views': p.views,
    //         'fans_status': p.fansStatus,
    //         'isUserPost': false,
    //       }).toList();
    //
    //       if (mounted) setState(() => _communityPosts = mapped);
    //       _feedLoaded = true;
    //       await _saveCachedFeed(prefs, mapped);
    //     }
    //   } catch (e) {
    //     debugPrint("Error fetching from API: $e");
    //   }
    // }

    final users = await _dbHelper.getUsers();
    if (users.isNotEmpty) {
      List<MockUser> loadedUsers =
      users.map((u) => MockUser.fromJson(u)).toList();
      if (currentUsername != null && currentUsername.isNotEmpty) {
        final currentUserIndex =
        loadedUsers.indexWhere((u) => u.username == currentUsername);
        if (currentUserIndex != -1) {
          final currentUser = loadedUsers.removeAt(currentUserIndex);
          loadedUsers.insert(0, currentUser);
        }
      }
      setState(() {
        _allUsers = loadedUsers;
      });
    } else {
      setState(() {
        _allUsers = [];
      });
    }

    await _loadRelationships();

    _dbHelper.cleanupUselessPosts().then((deletedCount) {
      if (deletedCount > 0) {
        _dbHelper.getPosts().then((cleanedPosts) {
          if (mounted) {
            setState(() {
              _userPosts = cleanedPosts.where((p) {
                final author = p['author'] as String? ?? '';
                final currentUser = _getCurrentUser();
                return author == 'You' ||
                    (author.isNotEmpty &&
                        currentUser.name.isNotEmpty &&
                        author.toLowerCase() ==
                            currentUser.name.toLowerCase());
              }).toList();

              if (_communityPosts.isEmpty) {
                _communityPosts = cleanedPosts.where((p) {
                  final author = p['author'] as String? ?? '';
                  final currentUser = _getCurrentUser();
                  final isMe = author == 'You' ||
                      (author.isNotEmpty &&
                          currentUser.name.isNotEmpty &&
                          author.toLowerCase() ==
                              currentUser.name.toLowerCase());
                  final isFollowed = _allUsers.any((u) =>
                  u.name == author &&
                      ['following', 'subscribed', 'mutual'].contains(u.type));
                  // final zippfansStatus = p['zippfansStatus'] ?? 0;
                  //                   // return !isMe && isFollowed && (zippfansStatus != 1);
                  // final fansStatus = p['fans_status']?.toString() ?? '0';
                  // return !isMe && isFollowed && (fansStatus != '1');
                  final fansStatus = p['fans_status']?.toString() ?? '0'; // ✅ fixed
                  return !isMe && isFollowed && (fansStatus != '1');       // ✅ fixed
                }).toList();
              }
            });
          }
        });
      }
    });

    await _dbHelper.deletePostsByAuthor('Global Wanderer');

    if (_communityPosts.isEmpty) {
      final dbPosts = await _dbHelper.getPosts();
      if (dbPosts.isNotEmpty) {
        setState(() {
          final currentUser = _getCurrentUser();
          _userPosts = dbPosts.where((p) {
            final author = p['author'] as String? ?? '';
            return author == 'You' ||
                (author.isNotEmpty &&
                    currentUser.name.isNotEmpty &&
                    author.toLowerCase() == currentUser.name.toLowerCase());
          }).toList();

          _communityPosts = dbPosts.where((p) {
            final author = p['author'] as String? ?? '';
            final isMe = author == 'You' ||
                (author.isNotEmpty &&
                    currentUser.name.isNotEmpty &&
                    author.toLowerCase() == currentUser.name.toLowerCase());
            final isFollowed = _allUsers.any((u) =>
            u.name == author &&
                ['following', 'subscribed', 'mutual'].contains(u.type));
            // final zippfansStatus = p['zippfansStatus'] ?? 0;
            // return !isMe && isFollowed && (zippfansStatus != 1);
            final fansStatus = p['fans_status']?.toString() ?? '0'; // ✅ fixed
            return !isMe && isFollowed && (fansStatus != '1');
          }).toList();
          _samplePosts = [];
        });
      }
    }

    final read = await _dbHelper.getActionPosts('read');
    final watch = await _dbHelper.getActionPosts('watch');
    final bookmark = await _dbHelper.getActionPosts('bookmark');

    setState(() {
      _readPosts = List<Map<String, dynamic>>.from(read);
      _watchedPosts = List<Map<String, dynamic>>.from(watch);
      _bookmarkedPosts = List<Map<String, dynamic>>.from(bookmark);
    });

    final currentUser = _getCurrentUser();
    final cartConfig = await _dbHelper.getCartItems(currentUser.username);
    _cartItemsNotifier.value = cartConfig;

    _notificationsEnabled =
        prefs.getBool('notifications_enabled_${currentUser.username}') ?? true;
    _likeNotificationsEnabled =
        prefs.getBool('like_notifications_enabled_${currentUser.username}') ??
            true;
    _commentNotificationsEnabled = prefs.getBool(
        'comment_notifications_enabled_${currentUser.username}') ??
        true;
    _newSubNotificationsEnabled = prefs.getBool(
        'new_sub_notifications_enabled_${currentUser.username}') ??
        true;
    _tipNotificationsEnabled =
        prefs.getBool('tip_notifications_enabled_${currentUser.username}') ??
            true;
    _messageNotificationsEnabled = prefs.getBool(
        'message_notifications_enabled_${currentUser.username}') ??
        true;
    _expiringSubNotificationsEnabled = prefs.getBool(
        'expiring_sub_notifications_enabled_${currentUser.username}') ??
        false;
    _upcomingRenewalNotificationsEnabled = prefs.getBool(
        'upcoming_renewal_notifications_enabled_${currentUser.username}') ??
        false;
    if (authToken != null && authToken.isNotEmpty) {
      try {
        await ref.read(feedViewModelProvider.notifier).loadFeed();

        final feedState = ref.read(feedViewModelProvider);

        if (feedState.posts.isNotEmpty && mounted) {
          setState(() {
            _communityPosts = feedState.posts.map((p) => {
              'id': p.id,
              'title': p.title,
              'author': p.user.name,
              'avatar': p.user.avatar ?? '',
              'text': p.text,
              'image': p.image,
              'video_url': p.videoUrl,
              'audio_url': p.audioUrl,
              'literature_url': p.literatureUrl,
              'fans_status': p.fansStatus,
            }).toList();
          });
        }
      } catch (e) {
        debugPrint('Feed API Error: $e');
      }
    }

    _loadSavedNotifications(prefs);
    _loadNotifications();
  }

  Future<void> _loadSavedNotifications(SharedPreferences prefs) async {
    final currentUser = _getCurrentUser();
    final notificationKey = 'saved_notifications_${currentUser.username}';
    final String? savedNotificationsJson = prefs.getString(notificationKey);
    if (savedNotificationsJson != null && savedNotificationsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(savedNotificationsJson);
        final savedNotifications = decoded.map((n) {
          final map = Map<String, dynamic>.from(n);
          final String type = map['type'] as String? ?? '';
          final String message = map['message'] as String? ?? '';

          if (map['timestamp'] != null && map['timestamp'] is String) {
            try {
              map['timestamp'] = DateTime.parse(map['timestamp']);
            } catch (e) {
              map['timestamp'] = DateTime.now();
            }
          } else if (map['timestamp'] == null) {
            map['timestamp'] = DateTime.now();
          }

          if (map['postId'] != null) {
            if (map['postId'] is String) {
              map['postId'] = int.tryParse(map['postId'] as String);
            }
          }

          if (type == 'comment' || type == 'reply') {
            if (map['commentAuthor'] == null || map['commentText'] == null) {
              final match = RegExp(r'^(.+?)\s+(?:commented|replied):\s+"(.+?)"')
                  .firstMatch(message);
              if (match != null) {
                map['commentAuthor'] ??= match.group(1)?.trim();
                map['commentText'] ??= match.group(2)?.trim();
              }
            }
          } else if (type == 'like') {
            if (map['postTitle'] == null) {
              final match =
              RegExp(r'liked your post\s+"(.+?)"').firstMatch(message);
              if (match != null) map['postTitle'] = match.group(1);
            }
            if (map['user'] == null) {
              final authorMatch =
              RegExp(r'^(.+?)\s+liked').firstMatch(message);
              if (authorMatch != null)
                map['user'] = authorMatch.group(1)?.trim();
            }
          } else if (type == 'subscription') {
            if (map['user'] == null) {
              final match =
              RegExp(r'^(.+?)\s+has subscribed').firstMatch(message);
              if (match != null) map['user'] = match.group(1)?.trim();
            }
          } else if (type == 'message') {
            if (map['user'] == null) {
              final match =
              RegExp(r'from\s+(.+?)(?:\.|$)').firstMatch(message);
              if (match != null) map['user'] = match.group(1)?.trim();
            }
          }
          return map;
        }).toList();

        savedNotifications.sort((a, b) {
          try {
            DateTime? tA, tB;
            final tsA = a['timestamp'];
            final tsB = b['timestamp'];
            if (tsA is DateTime) tA = tsA;
            else if (tsA is String) tA = DateTime.tryParse(tsA);
            if (tsB is DateTime) tB = tsB;
            else if (tsB is String) tB = DateTime.tryParse(tsB);
            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          } catch (e) {
            return 0;
          }
        });

        final filteredNotifications = <Map<String, dynamic>>[];
        for (var notification in savedNotifications) {
          final postId = notification['postId'] as int?;
          final notificationType = notification['type'] as String? ?? '';
          if (notificationType == 'cart') continue;

          bool postExists = false;
          if (postId != null) {
            postExists = _allPosts.any((p) => p['id'] == postId);
            if (!postExists) {
              try {
                final dbPost = await _dbHelper.getPostById(postId);
                postExists = dbPost != null;
              } catch (e) {}
            }
          } else {
            final message = notification['message'] as String? ?? '';
            if (message.isNotEmpty &&
                (notificationType == 'like' ||
                    notificationType == 'comment' ||
                    notificationType == 'reply')) {
              final match = RegExp(r'"([^"]+)"').firstMatch(message);
              if (match != null) {
                final postTitle = match.group(1);
                if (postTitle != null) {
                  postExists = _allPosts.any((p) => p['title'] == postTitle);
                  if (!postExists) {
                    try {
                      final allDbPosts = await _dbHelper.getPosts();
                      postExists =
                          allDbPosts.any((p) => p['title'] == postTitle);
                    } catch (e) {}
                  }
                }
              }
            } else {
              postExists = true;
            }
          }

          if (postExists) filteredNotifications.add(notification);
        }

        _notificationsNotifier.value = filteredNotifications;
        if (filteredNotifications.length != savedNotifications.length) {
          _saveNotifications();
        }
      } catch (e) {
        debugPrint("Error loading saved notifications: $e");
      }
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = _getCurrentUser();
      final notificationKey = 'saved_notifications_${currentUser.username}';
      final notifications = _notificationsNotifier.value;
      final notificationsToSave = notifications.length > 100
          ? notifications.sublist(notifications.length - 100)
          : notifications;

      final notificationsJson = notificationsToSave.map((n) {
        final map = Map<String, dynamic>.from(n);
        if (map['timestamp'] is DateTime) {
          map['timestamp'] = (map['timestamp'] as DateTime).toIso8601String();
        }
        return map;
      }).toList();

      await prefs.setString(notificationKey, jsonEncode(notificationsJson));
    } catch (e) {
      debugPrint("Error saving notifications: $e");
    }
  }

  void _loadNotifications() {
    return;
  }

  void _filterNotifications() {
    if (!_notificationsEnabled) return;
    final current =
    List<Map<String, dynamic>>.from(_notificationsNotifier.value);
    final filtered = current.where((notification) {
      final type = notification['type'] as String? ?? '';
      switch (type) {
        case 'like':
          return _likeNotificationsEnabled;
        case 'comment':
          return _commentNotificationsEnabled;
        case 'reply':
          return _commentNotificationsEnabled;
        case 'subscription':
          return _newSubNotificationsEnabled;
        case 'tip':
          return _tipNotificationsEnabled;
        case 'message':
          return _messageNotificationsEnabled;
        case 'expiring_sub':
          return _expiringSubNotificationsEnabled;
        case 'upcoming_renewal':
          return _upcomingRenewalNotificationsEnabled;
        default:
          return true;
      }
    }).toList();
    _notificationsNotifier.value = filtered;
    _saveNotifications();
  }

  Future<void> _addNotificationForUser(
      String targetUsername,
      Map<String, dynamic> notification,
      ) async {
    if (targetUsername.isEmpty) return;
    final currentUser = _getCurrentUser();
    if (targetUsername.toLowerCase() == currentUser.name.toLowerCase() ||
        targetUsername.toLowerCase() == currentUser.username.toLowerCase()) {
      _addNotification(
        notification['type'],
        notification['title'],
        notification['message'],
        postId: notification['postId'],
        commentAuthor: notification['commentAuthor'],
        commentText: notification['commentText'],
        commentId: notification['commentId'],
        user: notification['user'],
        postTitle: notification['postTitle'],
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String effectiveUsername = targetUsername;
      try {
        final user = _allUsers.firstWhere(
              (u) =>
          u.name.toLowerCase() == targetUsername.toLowerCase() ||
              u.username.toLowerCase() == targetUsername.toLowerCase(),
          orElse: () => MockUser(
            username: targetUsername,
            name: targetUsername,
            avatar: '',
            coverImage: '',
            isVerified: false,
            bio: '',
            type: '',
            country: '',
            state: '',
            city: '',
            gender: '',
          ),
        );
        effectiveUsername = user.username;
      } catch (_) {}

      final notificationKey = 'saved_notifications_$effectiveUsername';
      final String? existingJson = prefs.getString(notificationKey);
      List<Map<String, dynamic>> targetNotifications = [];

      if (existingJson != null && existingJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(existingJson);
          targetNotifications =
              decoded.map((n) => Map<String, dynamic>.from(n)).toList();
        } catch (e) {}
      }

      if (notification['timestamp'] == null) {
        notification['timestamp'] = DateTime.now().toIso8601String();
      } else if (notification['timestamp'] is DateTime) {
        notification['timestamp'] =
            (notification['timestamp'] as DateTime).toIso8601String();
      }

      final isDuplicate = targetNotifications.any((n) {
        if (n['type'] != notification['type']) return false;
        if (n['message'] != notification['message']) return false;
        if (notification['commentId'] != null && n['commentId'] != null) {
          return n['commentId'] == notification['commentId'];
        }
        if (notification['commentText'] != null &&
            n['commentText'] != notification['commentText']) return false;
        return true;
      });

      if (!isDuplicate) {
        targetNotifications.add(notification);
        if (targetNotifications.length > 100) {
          targetNotifications = targetNotifications
              .sublist(targetNotifications.length - 100);
        }
        await prefs.setString(
            notificationKey, jsonEncode(targetNotifications));
      }
    } catch (e) {
      debugPrint("Error saving offline notification: $e");
    }
  }

  void _addNotification(
      String type,
      String title,
      String message, {
        int? postId,
        String? commentAuthor,
        String? commentText,
        int? commentId,
        String? user,
        String? postTitle,
      }) {
    if (!_notificationsEnabled) return;
    if (type == 'like' && !_likeNotificationsEnabled) return;
    if (type == 'comment' && !_commentNotificationsEnabled) return;
    if (type == 'cart') return;

    final isDuplicate = _notificationsNotifier.value.any((n) {
      if (n['type'] != type) return false;
      final nPostId = n['postId'] as int?;
      if (postId != null && nPostId != postId) return false;
      if (postId == null && nPostId != null) return false;
      final nCommentId = n['commentId'] as int?;
      if (commentId != null) {
        if (nCommentId == commentId) return true;
        if (nCommentId != null && nCommentId != commentId) return false;
      }
      final nCommentText = n['commentText'] as String?;
      if (commentText != null && nCommentText != commentText) return false;
      if (commentText == null && nCommentText != null) return false;
      return true;
    });

    if (isDuplicate) return;

    String finalMessage = message;
    if ((type == 'comment' || type == 'reply') &&
        commentAuthor != null &&
        commentAuthor.isNotEmpty) {
      if (!finalMessage.startsWith(commentAuthor)) {
        final preview = commentText != null && commentText.length > 50
            ? '${commentText.substring(0, 50)}...'
            : (commentText ?? '');
        finalMessage = type == 'comment'
            ? '$commentAuthor commented: "$preview"'
            : '$commentAuthor replied: "$preview"';
      }
    }

    final notification = {
      'type': type,
      'title': title,
      'message': finalMessage,
      'timestamp': DateTime.now(),
      'isRead': false,
      if (postId != null) 'postId': postId,
      if (commentAuthor != null) 'commentAuthor': commentAuthor,
      if (commentText != null) 'commentText': commentText,
      if (commentId != null) 'commentId': commentId,
      if (user != null) 'user': user,
      if (postTitle != null) 'postTitle': postTitle,
    };

    setState(() {
      final current = List<Map<String, dynamic>>.from(
          _notificationsNotifier.value);
      current.add(notification);
      current.sort((a, b) {
        try {
          DateTime? tA, tB;
          final tsA = a['timestamp'];
          final tsB = b['timestamp'];
          if (tsA is DateTime) tA = tsA;
          else if (tsA is String) tA = DateTime.tryParse(tsA);
          if (tsB is DateTime) tB = tsB;
          else if (tsB is String) tB = DateTime.tryParse(tsB);
          if (tA == null && tB == null) return 0;
          if (tA == null) return 1;
          if (tB == null) return -1;
          return tB.compareTo(tA);
        } catch (e) {
          return 0;
        }
      });
      final limited = current.length > 100 ? current.sublist(0, 100) : current;
      _notificationsNotifier.value = limited;
      _saveNotifications();
    });
  }

  void _updateNotifications(List<Map<String, dynamic>> updatedNotifications) {
    final sorted = List<Map<String, dynamic>>.from(updatedNotifications);
    sorted.sort((a, b) {
      try {
        DateTime? tA, tB;
        final tsA = a['timestamp'];
        final tsB = b['timestamp'];
        if (tsA is DateTime) tA = tsA;
        else if (tsA is String) tA = DateTime.tryParse(tsA);
        if (tsB is DateTime) tB = tsB;
        else if (tsB is String) tB = DateTime.tryParse(tsB);
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      } catch (e) {
        return 0;
      }
    });
    _notificationsNotifier.value = sorted;
    _saveNotifications();
    if (_notificationsEnabled) _filterNotifications();
  }

  Future<void> _migrateToDatabase(SharedPreferences prefs) async {
    final String? usersJson = prefs.getString('saved_users');
    if (usersJson != null) {
      final List<dynamic> decoded = jsonDecode(usersJson);
      for (var u in decoded) {
        await _dbHelper.insertUser(u);
      }
    } else {
      for (var u in _allUsers) {
        await _dbHelper.insertUser(u.toJson());
      }
    }

    final String? userPostsJson = prefs.getString('saved_user_posts');
    if (userPostsJson != null) {
      final List<dynamic> decoded = jsonDecode(userPostsJson);
      for (var p in decoded) {
        await _dbHelper.insertPost(p);
      }
    }

    final String? communityPostsJson = prefs.getString('saved_community_posts');
    if (communityPostsJson != null) {
      final List<dynamic> decoded = jsonDecode(communityPostsJson);
      for (var p in decoded) {
        await _dbHelper.insertPost(p);
      }
    }

    final actionKeys = ['read_posts', 'watched_posts', 'bookmarked_posts'];
    final actionTypes = ['read', 'watch', 'bookmark'];
    for (int i = 0; i < actionKeys.length; i++) {
      final String? json = prefs.getString(actionKeys[i]);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        for (var p in decoded) {
          await _dbHelper.toggleAction(p['title'], p['author'], actionTypes[i]);
        }
      }
    }
  }

  List<Map<String, dynamic>> _loadPostList(
      SharedPreferences prefs, String key) {
    final String? json = prefs.getString(key);
    if (json != null) {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((p) {
        final map = Map<String, dynamic>.from(p);
        map['readCount'] ??= 0;
        map['watchCount'] ??= 0;
        map['comments'] ??= [];
        return map;
      }).toList();
    }
    return [];
  }

  Future<void> _savePostList(
      String key, List<Map<String, dynamic>> list) async {}

  Future<void> _saveUserPosts() async {
    for (var p in _userPosts) {
      await _dbHelper.insertPost(Map<String, dynamic>.from(p));
    }
  }

  Future<void> _saveUsers() async {
    for (var u in _allUsers) {
      await _dbHelper.insertUser(u.toJson());
    }
  }

  Future<void> _saveSamplePosts() async {
    for (var p in _samplePosts) {
      await _dbHelper.insertPost(Map<String, dynamic>.from(p));
    }
  }

  Future<void> _saveCommunityPosts() async {
    for (var p in _communityPosts) {
      await _dbHelper.insertPost(Map<String, dynamic>.from(p));
    }
  }

  static const String _cachedFeedKey = 'cached_feed_posts_v1';

  // Persist the mapped feed posts to SharedPreferences. Survives the
  // process being killed (e.g. when the user clears the app from
  // recents) so the next cold start has something to render.
  Future<void> _saveCachedFeed(
      SharedPreferences prefs, List<Map<String, dynamic>> posts) async {
    try {
      final serialized = posts.map((p) {
        final m = Map<String, dynamic>.from(p);
        if (m['date'] is DateTime) {
          m['date'] = (m['date'] as DateTime).toIso8601String();
        }
        // Drop anything that JSON can't encode (rare — but safe).
        m.removeWhere((_, v) =>
        v != null &&
            v is! String &&
            v is! num &&
            v is! bool &&
            v is! List &&
            v is! Map);
        return m;
      }).toList();
      await prefs.setString(_cachedFeedKey, jsonEncode(serialized));
    } catch (e) {
      debugPrint('Failed to cache feed: $e');
    }
  }

  List<Map<String, dynamic>> _loadCachedFeed(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_cachedFeedKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map<Map<String, dynamic>>((p) {
        final m = Map<String, dynamic>.from(p as Map);
        if (m['date'] is String) {
          m['date'] = DateTime.tryParse(m['date'] as String) ?? DateTime.now();
        }
        m['comments'] ??= [];
        m['isUserPost'] ??= false;
        return m;
      }).toList();
    } catch (e) {
      debugPrint('Failed to load cached feed: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _parsePosts(List<dynamic> jsonList,
      {bool isUser = false}) {
    return jsonList.map((p) {
      final map = Map<String, dynamic>.from(p);
      if (map['date'] != null && map['date'] is String) {
        map['date'] = DateTime.parse(map['date']);
      }
      map['likeCount'] ??= 0;
      map['ratingCount'] ??= 0;
      map['averageRating'] ??= 0.0;
      map['totalRatings'] ??= 0;
      map['comments'] ??= [];
      if (isUser) {
        final currentUserName = _getCurrentUser().name;
        if (map['author'] == 'You' ||
            map['author'] == '' ||
            (map['author'] != null &&
                map['author'].toString().trim().toLowerCase() ==
                    currentUserName.toString().trim().toLowerCase())) {
          map['author'] = currentUserName;
        }
      }
      return map;
    }).toList();
  }

  List<Map<String, dynamic>> _postListToJson(
      List<Map<String, dynamic>> list) {
    return list.map((p) {
      final map = Map<String, dynamic>.from(p);
      if (map['date'] is DateTime) {
        map['date'] = (map['date'] as DateTime).toIso8601String();
      }
      return map;
    }).toList();
  }

  List<Map<String, dynamic>> get _allPosts {
    final combined = [..._userPosts, ..._samplePosts, ..._communityPosts];
    combined.sort((a, b) {
      try {
        final dateA = a['date'];
        final dateB = b['date'];
        if (dateA == null || dateB == null) return 0;
        if (dateA is DateTime && dateB is DateTime) {
          return dateB.compareTo(dateA);
        }
        if (dateA is String && dateB is String) {
          try {
            return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
          } catch (_) {
            return 0;
          }
        }
        return 0;
      } catch (e) {
        return 0;
      }
    });
    return combined;
  }
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;

      if (query.isEmpty) {
        _selectedHomeUser = null;
      } else {
        try {
          _selectedHomeUser = _allUsers.firstWhere(
                (u) =>
            u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.username.toLowerCase().contains(query.toLowerCase()),
          );
        } catch (e) {
          _selectedHomeUser = null;
        }
      }
    });

    if (query.length < 2) return;

    ref
        .read(searchProvider.notifier)
        .searchUsers(query);
  }

  Future<void> _onPostCreated(Map<String, dynamic> newPost) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(context.tr.creatingPost),
            ],
          ),
          backgroundColor: const Color(0xFFDB2777),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    final postWithMeta = {
      ...newPost,
      'author': _getCurrentUser().name,
      'isUserPost': true,
      'date': newPost['date'] ?? DateTime.now(),
      'likeCount': 0,
      'ratingCount': 0,
      'averageRating': 0.0,
      'totalRatings': 0,
      'comments': [],
    };

    final sanitizedPost = Map<String, dynamic>.from(postWithMeta)
      ..remove('images')
      ..remove('imagePaths');

    try {
      final int id = await _dbHelper.insertPost(sanitizedPost);
      postWithMeta['id'] = id;
      sanitizedPost['id'] = id;

      if (mounted) {
        setState(() {
          _userPosts = [postWithMeta, ..._userPosts];
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.postCreated),
            backgroundColor: const Color(0xFFDB2777),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error creating post: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.errorSavingPost(e.toString())),
            backgroundColor: const Color(0xFFDB2777),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  Future<void> _onPostDeleted(Map<String, dynamic> post) async {
    final int? postId = post['id'] as int?;
    if (postId == null) {
      _showActionSnackBar("Cannot delete: missing post ID", isError: true);
      return;
    }

    // Get the auth token (adjust to however your app stores it —
    // SharedPreferences, secure storage, a global AuthService, etc.)
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (authToken == null || authToken.isEmpty) {
      _showActionSnackBar("Please log in again", isError: true);
      return;
    }

    final dio = Dio(BaseOptions(
      baseUrl: "https://openzippers.com/api/v1/",
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $authToken", // ✅ now actually sent
      },
      validateStatus: (status) =>
      status != null && (status < 400 || status == 404),
      // treat 404 as "already gone" = success
    ));

    final apiClient = ApiClient(dio);

    // Helper to clean local state — called on success OR on 404
    void removeLocally() {
      setState(() {
        _userPosts.removeWhere((p) => p['id'] == postId);
        _communityPosts.removeWhere((p) => p['id'] == postId);
        _samplePosts.removeWhere((p) => p['id'] == postId);
        _bookmarkedPosts.removeWhere((p) => p['id'] == postId);
        _readPosts.removeWhere((p) => p['id'] == postId);
        _watchedPosts.removeWhere((p) => p['id'] == postId);
      });
    }

    try {
      await apiClient.deletePost(postId);
      removeLocally();
      await _dbHelper.deletePostById(postId);

      if (mounted) {
        _showActionSnackBar("Post deleted successfully");
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;

      if (code == 404) {
        // Post already deleted server-side — clean up locally anyway
        removeLocally();
        await _dbHelper.deletePostById(postId);
        if (mounted) _showActionSnackBar("Post deleted successfully");
      } else if (code == 401) {
        if (mounted) {
          _showActionSnackBar("Session expired. Please log in again.",
              isError: true);
        }
      } else {
        if (mounted) {
          _showActionSnackBar(
              "Failed to delete (${code ?? 'network error'})",
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showActionSnackBar("Failed to delete", isError: true);
      }
    }
  }


  Future<void> _handleLogout() async {
    _hasSyncedPageAfterRebuild = false;
    _feedLoaded = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.loggingOut),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }

    await ref.read(loginViewModelProvider.notifier).logoutUser(
      onSuccess: (message) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => LoginScreen(logoutMessage: message)),
                (route) => false,
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        }
      },
    );
  }

  // void _showRatingDialog(Map<String, dynamic> post) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => RatingDialog(
  //       post: post,
  //       onSubmit: (stars) {
  //         _handlePostAction(post, 'SubmitRating', extraData: stars);
  //       },
  //     ),
  //   );
  // }
  void _showRatingDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (_) => RatingDialog(
        post: post,
        onSubmit: (stars) async {
          try {
            final postId = int.tryParse(post['id'].toString());

            if (postId == null) return;

            final res = await ref
                .read(submitRatingProvider.notifier)
                .submitRating(
              postId: postId,
              rating: stars,
            );

            await ref.read(feedViewModelProvider.notifier).loadFeed();

            final feedState = ref.read(feedViewModelProvider);

            final updatedPost = feedState.posts.firstWhere(
                  (p) => p.id == postId,
            );

            if (!mounted) return;

            setState(() {
              post['my_rating'] = updatedPost.userRating;
              post['user_rating'] = updatedPost.userRating;

              post['average_rating'] = updatedPost.averageRating;
              post['averageRating'] = updatedPost.averageRating;

              post['total_ratings'] = updatedPost.totalRatings;
              post['totalRatings'] = updatedPost.totalRatings;
            });



            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rating submitted successfully'),
              ),
            );
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rating failed: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _handleEditPost(Map<String, dynamic> post) async {
    final updatedPost = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CreatePostScreen(existingPost: post)),
    );
    if (updatedPost != null && updatedPost is Map<String, dynamic>) {
      _handlePostAction(updatedPost, 'Update');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIXED _handlePostAction — correct brace structure, Like/Rate/Bookmark
  // now properly reachable at the top level of this method.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handlePostAction(
      Map<String, dynamic> post,
      String action, {
        dynamic extraData,
      }) async {
    // ── OpenLiterature ──────────────────────────────────────────────────────
    if (action == 'OpenLiterature') {
      final String? localPath = post['local_pdf_path'] as String?;
      final String? remoteUrl =
          post['literature_url'] as String? ?? post['preview_url'] as String?;
      if ((localPath == null || localPath.isEmpty) &&
          (remoteUrl == null || remoteUrl.isEmpty)) {
        _showActionSnackBar('No PDF available for this post.', isError: true);
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LiteraturePdfViewerScreen(
          title: post['title']?.toString() ?? 'Literature',
          pdfPath:
          (localPath != null && localPath.isNotEmpty) ? localPath : null,
          pdfUrl: (localPath == null || localPath.isEmpty) ? remoteUrl : null,
        ),
      ));
      return;
    }

    // ── Delete ──────────────────────────────────────────────────────────────
    if (action == 'DeletePost' || action == 'Delete' || action == 'delete') {
      _onPostDeleted(post);
      return;
    }

    // ── Unlock ──────────────────────────────────────────────────────────────
    if (action == 'unlock') {
      final authorName = post['author']?.toString() ?? '';
      if (authorName.isNotEmpty) {
        String clean(String s) => s
            .replaceAll(
            RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false), '')
            .replaceAll(' ', '')
            .trim()
            .toLowerCase();
        final targetClean = clean(authorName);
        final author = _allUsers.firstWhere(
              (u) =>
          clean(u.name) == targetClean ||
              clean(u.username) == targetClean,
          orElse: () =>
              MockUser(name: authorName, username: authorName, avatar: '', type: 'other'),
        );
        _handleUserAction(author, 'Subscribe');
      }
      return;
    }

    // ── Update ──────────────────────────────────────────────────────────────
    if (action == 'Update') {
      setState(() {
        for (var list in [_userPosts, _samplePosts, _communityPosts]) {
          final index = list.indexWhere((p) => p['id'] == post['id']);
          if (index != -1) list[index] = post;
        }
        _dbHelper.updatePost(post);
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr.postUpdated)));
      }
      return;
    }

    // ── DeleteComment ───────────────────────────────────────────────────────
    if (action == 'DeleteComment') {
      final comment = extraData as Map<String, dynamic>;
      _handleCommentDelete(post, comment);
      return;
    }

    // ── LikeComment ─────────────────────────────────────────────────────────
    if (action == 'LikeComment') {
      final comment = extraData as Map<String, dynamic>;
      final likes = List<String>.from(comment['likes'] ?? []);
      final username = _getCurrentUser().username;
      if (likes.contains(username)) {
        likes.remove(username);
      } else {
        likes.add(username);
      }
      comment['likes'] = likes;
      setState(() {
        _updateGlobalPostInteraction(post, 'UpdateComment', comment: comment);
        _dbHelper.updateComment(comment);
      });
      return;
    }

    // ── Comment (open bottom sheet) ─────────────────────────────────────────
    if (action == 'Comment') {
      final bool disableComments =
      (extraData is Map && extraData['disableComments'] == true);
      _showCommentDialog(post, enableComments: !disableComments);
      return;
    }

    // ── SubmitComment ───────────────────────────────────────────────────────
    if (action == 'SubmitComment') {
      final data = extraData as Map;
      final text = data['text'];
      final parentId = data['parentId'];
      final currentUser = _getCurrentUser();
      final commentAuthor = currentUser.name;
      final postAuthor = post['author'] as String? ?? '';
      final commentText = text.toString().trim();

      if (commentText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr.commentNotEmpty)));
        }
        return;
      }

      final postId = post['id'];
      final bool hasApiId = postId != null && postId is int;

      if (hasApiId) {
        // ── API path ──────────────────────────────────────────────────────
        try {
          final comment = await ref
              .read(postCommentProvider(postId).notifier)
              .postComment(content: commentText, parentId: parentId);

          if (comment != null && mounted) {
            final appMap = comment.toAppMap();
            setState(() {
              for (var list in [_userPosts, _samplePosts, _communityPosts]) {
                for (var p in list) {
                  if (p['id'] == postId) {
                    final existing = List.from(p['comments'] as List? ?? []);
                    existing.add(appMap);
                    p['comments'] = existing;
                    p['commentsCount'] = (p['commentsCount'] ?? 0) + 1;
                    break;
                  }
                }
              }
            });

            _showActionSnackBar(
              parentId != null
                  ? context.tr.replyPosted
                  : context.tr.commentPosted,
            );

            final isSelfComment =
                commentAuthor.toLowerCase() == postAuthor.toLowerCase();
            if (postAuthor.isNotEmpty && !isSelfComment) {
              final commentPreview = commentText.length > 60
                  ? '${commentText.substring(0, 60)}...'
                  : commentText;
              _addNotificationForUser(postAuthor, {
                'type': parentId == null ? 'comment' : 'reply',
                'title': parentId == null
                    ? 'Commented on your post'
                    : 'Replied to your comment',
                'message':
                '$commentAuthor ${parentId == null ? 'commented' : 'replied'}: "$commentPreview"',
                'postId': postId,
                'commentAuthor': commentAuthor,
                'commentText': commentText,
                'commentId': comment.id,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          } else {
            final errorMsg = ref.read(postCommentProvider(postId)).error ??
                'Failed to post';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(errorMsg),
                backgroundColor: const Color(0xFFDB2777),
              ));
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: const Color(0xFFDB2777),
            ));
          }
        }
      } else {
        // ── Local / offline path ──────────────────────────────────────────
        final Map<String, dynamic> comment = {
          'author': commentAuthor,
          'text': commentText,
          'likes': [],
          'parentId': parentId,
          'timestamp': DateTime.now(),
        };
        try {
          final newId = await _dbHelper.insertComment(post['id'], comment);
          comment['id'] = newId;
          if (mounted) {
            setState(() {
              _updateGlobalPostInteraction(post, 'Comment', comment: comment);
            });
            _showActionSnackBar(context.tr.commentPosted);
          }
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
              Text(context.tr.errorPostingComment(error.toString())),
              backgroundColor: const Color(0xFFDB2777),
            ));
          }
        }
      }
      return;
    }

    // ── Like / Rate / Bookmark ──────────────────────────────────────────────
    // These were previously unreachable due to wrong brace nesting. Now fixed.
    setState(() {
      if (action == 'Like') {
        final isAlreadyLiked = _readPosts.any(
                (p) => p['title'] == post['title'] && p['author'] == post['author']);
        final currentUser = _getCurrentUser();
        final postAuthor = post['author'] as String? ?? '';

        if (isAlreadyLiked) {
          _readPosts.removeWhere(
                  (p) => p['title'] == post['title'] && p['author'] == post['author']);
          _dbHelper.toggleAction(post['title'], post['author'], 'read');
          _updateGlobalPostInteraction(post, 'Unlike');
        } else {
          _readPosts.add(post);
          _dbHelper.toggleAction(post['title'], post['author'], 'read');
          _updateGlobalPostInteraction(post, action);

          // ── Call like API ──
          final postId = post['id'] as int?;
          if (postId != null) {
            ref.read(likeProvider(postId).notifier).toggleLike();
          }

          final isSelfLike =
              currentUser.name.toLowerCase() == postAuthor.toLowerCase();
          final postTitle = post['title'] as String? ?? '';
          if (postAuthor.isNotEmpty && !isSelfLike) {
            final likeMessage =
                '${currentUser.name} liked your post "$postTitle"';
            if (postAuthor.toLowerCase() ==
                currentUser.name.toLowerCase() ||
                postAuthor == 'You') {
              _addNotification('like', 'Liked your post', likeMessage,
                  postId: post['id'] as int?,
                  user: currentUser.name,
                  postTitle: postTitle);
            } else {
              _addNotificationForUser(postAuthor, {
                'type': 'like',
                'title': 'Liked your post',
                'message': likeMessage,
                'postId': post['id'],
                'user': currentUser.name,
                'postTitle': postTitle,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          }
        }
      } else if (action == 'Rate') {
        _showRatingDialog(post);
      } else if (action == 'SubmitRating') {
        final int stars = extraData as int;
        _dbHelper.submitRating(post['title'], post['author'], stars).then((_) {
          _dbHelper.getRatingInfo(post['title'], post['author']).then((info) {
            if (mounted) {
              setState(() {
                _updateGlobalPostInteraction(post, 'UpdateRatingStats',
                    extraData: info);
                if (!_watchedPosts.any((p) =>
                p['title'] == post['title'] &&
                    p['author'] == post['author'])) {
                  _watchedPosts.add(post);
                }
              });
            }
          });
        });
        _showActionSnackBar(context.tr.ratingSubmitted);
      } else if (action == 'ToggleBookmark') {
        final index = _bookmarkedPosts.indexWhere(
                (p) => p['title'] == post['title'] && p['author'] == post['author']);
        if (index != -1) {
          _bookmarkedPosts.removeAt(index);
          _showActionSnackBar(context.tr.bookmarkRemoved);
        } else {
          _bookmarkedPosts.add(post);
          _showActionSnackBar(context.tr.postBookmarked);
        }
        _dbHelper.toggleAction(post['title'], post['author'], 'bookmark');
      }
    });
  }

  void _handleCommentDelete(
      Map<String, dynamic> post, Map<String, dynamic> comment) async {
    if (comment['id'] != null) {
      await _dbHelper.deleteCommentById(comment['id']);
    }
    setState(() {
      _updateGlobalPostInteraction(post, 'DeleteComment', extraData: comment);
      _showActionSnackBar(context.tr.commentDeleted);

      final currentNotifications =
      List<Map<String, dynamic>>.from(_notificationsNotifier.value);
      currentNotifications.removeWhere((n) =>
      (n['type'] == 'comment' || n['type'] == 'reply') &&
          n['commentAuthor'] == comment['author'] &&
          n['commentText'] == comment['text']);
      _notificationsNotifier.value = currentNotifications;
      _saveNotifications();
    });
  }

  void _updateCommentInList(
      List<dynamic> comments, Map<String, dynamic> updatedComment) {
    final index =
    comments.indexWhere((c) => c['id'] == updatedComment['id']);
    if (index != -1) comments[index] = updatedComment;
  }

  void _updateGlobalPostInteraction(
      Map<String, dynamic> post,
      String action, {
        Map<String, dynamic>? comment,
        dynamic extraData,
      }) {
    bool dbUpdated = false;

    int? baseLikeCount;
    for (var list in [_userPosts, _samplePosts, _communityPosts]) {
      for (var p in list) {
        if ((post['id'] != null && p['id'] == post['id']) ||
            (p['title'] == post['title'] && p['author'] == post['author'])) {
          baseLikeCount = (p['likeCount'] ?? 0) as int;
          break;
        }
      }
      if (baseLikeCount != null) break;
    }
    baseLikeCount ??= (post['likeCount'] ?? 0) as int;

    int newLikeCount;
    if (action == 'Like') {
      newLikeCount = (baseLikeCount + 1).clamp(0, double.infinity).toInt();
    } else if (action == 'Unlike') {
      newLikeCount = (baseLikeCount - 1).clamp(0, double.infinity).toInt();
    } else {
      newLikeCount = baseLikeCount;
    }

    void updateInList(List<Map<String, dynamic>> list) {
      for (var p in list) {
        if (p['title'] == post['title'] && p['author'] == post['author']) {
          if (action == 'Like') p['likeCount'] = newLikeCount;
          if (action == 'Unlike') p['likeCount'] = newLikeCount;
          if (action == 'Rate') p['ratingCount'] = (p['ratingCount'] ?? 0) + 1;

          if (comment != null && action == 'Comment') {
            final existingComments = p['comments'] as List? ?? [];
            p['comments'] = List.from(existingComments)..add(comment);
            comment['timestamp'] ??= DateTime.now();
          }

          if (comment != null && action == 'UpdateComment') {
            final comments = List.from(p['comments']);
            final index = comments.indexWhere((c) =>
            c['id'] == comment['id'] ||
                (c['text'] == comment['text'] &&
                    c['author'] == comment['author']));
            if (index != -1) {
              comments[index] = comment;
              p['comments'] = comments;
            }
          }

          if (action == 'UpdateRatingStats' &&
              extraData is Map<String, dynamic>) {
            p['averageRating'] = extraData['averageRating'];
            p['totalRatings'] = extraData['totalRatings'];
            p['ratingCount'] = extraData['totalRatings'];
          }

          if (action == 'DeleteComment') {
            final commentData = extraData as Map<String, dynamic>;
            final comments = List.from(p['comments']);
            final commentId = commentData['id'];
            final Set<int?> idsToDelete = {};

            void collectReplyIds(int? parentId) {
              for (var c in comments) {
                if (c['parentId'] == parentId && c['id'] != null) {
                  final replyId = c['id'];
                  if (!idsToDelete.contains(replyId)) {
                    idsToDelete.add(replyId);
                    collectReplyIds(replyId);
                  }
                }
              }
            }

            if (commentId != null) {
              collectReplyIds(commentId);
              idsToDelete.add(commentId);
              for (var id in idsToDelete) {
                if (id != null) _dbHelper.deleteCommentById(id);
              }
            }
            comments.removeWhere((c) => idsToDelete.contains(c['id']));
            p['comments'] = comments;
          }

          if (!dbUpdated) {
            if (action == 'Like') {
              _dbHelper.updatePostCounts(p['title'], p['author'],
                  incrementLike: true, incrementRating: false);
              dbUpdated = true;
            } else if (action == 'Unlike') {
              _dbHelper.updatePostCounts(p['title'], p['author'],
                  incrementLike: false,
                  decrementLike: true,
                  incrementRating: false);
              dbUpdated = true;
            } else if (action == 'Rate') {
              _dbHelper.updatePostCounts(p['title'], p['author'],
                  incrementLike: false, incrementRating: true);
              dbUpdated = true;
            }
          }
          return;
        }
      }
    }

    updateInList(_userPosts);
    updateInList(_samplePosts);
    updateInList(_communityPosts);
    updateInList(_readPosts);
    updateInList(_watchedPosts);
    updateInList(_bookmarkedPosts);
  }

  bool _isFree(dynamic price) {
    if (price == null) return true;
    final p = price.toString().toLowerCase().replaceAll('\$', '').trim();
    return p == 'free' || p == '0' || p == '0.00';
  }

  Future<String?> _resolveImagePath(String? path) async {
    if (path == null || path.isEmpty) return null;
    final pathStr = path.toString().trim();
    if (pathStr.isEmpty) return null;
    if (pathStr.startsWith('http://') || pathStr.startsWith('https://'))
      return pathStr;
    try {
      final file = File(pathStr);
      if (file.existsSync()) return file.absolute.path;
      final appDir = await getApplicationDocumentsDirectory();
      final uploadsDir = p.join(appDir.path, 'uploads');
      final fileName = p.basename(pathStr);
      final uploadsPath = p.join(uploadsDir, fileName);
      final uploadsFile = File(uploadsPath);
      if (uploadsFile.existsSync()) return uploadsFile.absolute.path;
    } catch (e) {}
    return pathStr;
  }

  Future<bool> _validateCartItemExists(Map<String, dynamic> cartItem) async {
    try {
      final title = cartItem['title'] as String?;
      final author = cartItem['author'] as String?;
      final postId = cartItem['id'] as int?;
      if (title == null || author == null) return false;
      if (postId != null && _allPosts.any((p) => p['id'] == postId))
        return true;
      if (_allPosts.any((p) => p['title'] == title && p['author'] == author))
        return true;
      if (postId != null) {
        final dbPost = await _dbHelper.getPostById(postId);
        if (dbPost != null) return true;
      }
      final allDbPosts = await _dbHelper.getPosts();
      return allDbPosts
          .any((p) => p['title'] == title && p['author'] == author);
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleAddToCart(Map<String, dynamic> post) async {
    try {
      if (_isFree(post['price'])) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr.freePostsNoCart)));
        }
        return;
      }

      final author = post['author']?.toString().trim() ?? '';
      final currentUser = _getCurrentUser();
      if (author.isEmpty || author == currentUser.name) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr.ownPostsNoCart)));
        }
        return;
      }

      final currentCart = _cartItemsNotifier.value;
      final postTitle = post['title']?.toString() ?? '';
      final postAuthor = post['author']?.toString() ?? '';
      final alreadyInCart = currentCart.any((item) =>
      item['title']?.toString() == postTitle &&
          item['author']?.toString() == postAuthor);

      if (alreadyInCart) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr.alreadyInCart),
            duration: const Duration(seconds: 2),
          ));
        }
        return;
      }

      await _dbHelper.addToCart(post, currentUser.username);
      final updatedCart = await _dbHelper.getCartItems(currentUser.username);

      if (mounted) {
        setState(() {
          _cartItemsNotifier.value = updatedCart;
        });
        _addNotification('cart', context.tr.itemAddedToCart,
            '${post['title']} has been added to your cart');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr.itemAddedToCart)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr.errorAddingToCart(e.toString())),
          backgroundColor: const Color(0xFFDB2777),
        ));
      }
    }
  }

  Future<void> _handleNotificationTap(
      Map<String, dynamic> notification) async {
    final currentNotifications =
    List<Map<String, dynamic>>.from(_notificationsNotifier.value);

    int notificationIndex = -1;
    final internalId = notification['_internalId'];
    if (internalId != null) {
      notificationIndex = currentNotifications
          .indexWhere((n) => n['_internalId'] == internalId);
    }
    if (notificationIndex == -1) {
      notificationIndex = currentNotifications.indexOf(notification);
    }
    if (notificationIndex == -1) {
      notificationIndex = currentNotifications.indexWhere((n) {
        if (n['type'] != notification['type']) return false;
        final nPostId = n['postId'];
        final notifPostId = notification['postId'];
        if (nPostId != null &&
            notifPostId != null &&
            nPostId.toString() == notifPostId.toString()) {
          return n['message'] == notification['message'];
        }
        return false;
      });
    }

    if (notificationIndex != -1 &&
        !(currentNotifications[notificationIndex]['isRead'] == true)) {
      final updated =
      Map<String, dynamic>.from(currentNotifications[notificationIndex]);
      updated['isRead'] = true;
      currentNotifications[notificationIndex] = updated;
      _notificationsNotifier.value = List.from(currentNotifications);
      _saveNotifications();
    }

    final type = notification['type'] as String? ?? '';

    int? parsedPostId;
    final postIdValue = notification['postId'];
    if (postIdValue is int) {
      parsedPostId = postIdValue;
    } else if (postIdValue is num) {
      parsedPostId = postIdValue.toInt();
    } else if (postIdValue is String) {
      parsedPostId = int.tryParse(postIdValue);
    }

    if (parsedPostId == null &&
        (type == 'like' || type == 'comment' || type == 'reply')) {
      final msg = notification['message'] as String? ?? '';
      final match = RegExp(r'"([^"]+)"').firstMatch(msg);
      if (match != null) {
        final title = match.group(1);
        if (title != null) {
          try {
            final post = _allPosts.firstWhere(
                  (p) => p['title'] == title,
              orElse: () => {},
            );
            if (post.isNotEmpty && post['id'] != null) {
              parsedPostId = post['id'] as int;
            } else {
              final dbPosts = await _dbHelper.getPosts();
              final found = dbPosts.firstWhere(
                    (p) => p['title'] == title,
                orElse: () => {},
              );
              if (found.isNotEmpty) parsedPostId = found['id'] as int?;
            }
          } catch (e) {}
        }
      }
    }

    if (parsedPostId != null) {
      setState(() {
        _targetPostIdFromNotification = parsedPostId;
      });
    }

    if (parsedPostId != null &&
        (type == 'comment' || type == 'like' || type == 'reply')) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();

      Map<String, dynamic>? targetPost;
      for (var list in [_userPosts, _allPosts, _communityPosts, _samplePosts]) {
        final idx = list.indexWhere(
                (p) => p['id']?.toString() == parsedPostId.toString());
        if (idx != -1) {
          targetPost = list[idx];
          break;
        }
      }

      if (targetPost == null) {
        try {
          final dbPost = await _dbHelper.getPostById(parsedPostId);
          if (dbPost != null) {
            targetPost = Map<String, dynamic>.from(dbPost);
            final isUserPost = targetPost['isUserPost'] == true;
            setState(() {
              final pidStr = parsedPostId.toString();
              if (isUserPost) {
                if (!_userPosts.any((p) => p['id']?.toString() == pidStr))
                  _userPosts.insert(0, targetPost!);
              } else {
                if (!_communityPosts.any((p) => p['id']?.toString() == pidStr))
                  _communityPosts.insert(0, targetPost!);
              }
            });
          }
        } catch (e) {}
      }

      if (targetPost == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr.postNoLongerAvailable)));
        }
        return;
      }

      final t = targetPost['type']?.toString().trim();
      final isReel = t == 'Video' || t == 'Reel' || t == 'Reels';

      if (isReel) {
        setState(() {
          _currentIndex = 1;
          _selectedHomeUser = null;
          _searchQuery = "";
          if (_pageController.hasClients) _pageController.jumpToPage(1);
        });
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() {});
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          int reelPollCount = 0;
          void pollForReels() {
            if (!mounted || reelPollCount >= 50) return;
            // if (_reelsKey.currentState != null) {
            //   _reelsKey.currentState?.scrollToReelComment(
            //     parsedPostId!,
            //     commentAuthor: notification['commentAuthor'] as String?,
            //     commentText: notification['commentText'] as String?,
            //     commentId: notification['commentId'],
            //   );
            // } else {
            //   reelPollCount++;
            //   Future.delayed(
            //       const Duration(milliseconds: 100), pollForReels);
            // }
          }

          pollForReels();
        }
      } else {
        setState(() {
          _currentIndex = 0;
          _selectedHomeUser = null;
          _searchQuery = "";
          _mainContentSelectedIndexNotifier.value = 0;
          if (_pageController.hasClients) _pageController.jumpToPage(0);
        });
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() {});
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() {});
        if (mounted) {
          _scrollToPostAfterDelay(
            parsedPostId,
            type == 'comment' || type == 'reply',
            commentAuthor: notification['commentAuthor'] as String?,
            commentText: notification['commentText'] as String?,
            commentId: notification['commentId'],
          );
        }
      }
    } else if (type == 'cart') {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CartScreen()));
    } else if (type == 'tip') {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              WalletScreen(currentUser: _getCurrentUser())));
    } else if (type == 'subscription') {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      String? username = notification['user'] as String?;
      if ((username == null || username.isEmpty) &&
          notification['message'] != null) {
        final msg = notification['message'] as String;
        if (msg.contains(" has subscribed")) {
          username = msg.split(" has subscribed").first.trim();
        }
      }
      if (username != null && username.isNotEmpty) {
        _finalRedirectToProfile(username.trim());
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SubscriptionsPage(
              currentUser: _getCurrentUser(), highlightUser: username)));
    } else if (type == 'message') {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      String? username = notification['user'] as String?;
      if ((username == null || username.isEmpty) &&
          notification['message'] != null) {
        final msg = notification['message'] as String;
        if (msg.contains("from ")) {
          username = msg.split("from ").last.replaceAll('.', '').trim();
        }
      }
      if (username != null && username.isNotEmpty) {
        _finalRedirectToProfile(username.trim());
        return;
      }
      setState(() {
        _currentIndex = 2;
        _connectionsHighlightUser = username;
        if (_pageController.hasClients) _pageController.jumpToPage(2);
      });
    }
  }

  Future<void> _finalRedirectToProfile(String username) async {
    try {
      var targetUser = _allUsers.firstWhere(
            (u) =>
        u.username.toLowerCase() == username.toLowerCase() ||
            u.name.toLowerCase() == username.toLowerCase(),
        orElse: () => MockUser(
            username: '',
            name: '',
            avatar: '',
            coverImage: '',
            isVerified: false,
            bio: '',
            type: '',
            country: '',
            state: '',
            city: '',
            gender: ''),
      );

      if (targetUser.username.isEmpty) {
        final dbUserMap = await _dbHelper.getUserByUsername(username);
        if (dbUserMap != null) targetUser = MockUser.fromJson(dbUserMap);
      }

      final user = targetUser.username.isNotEmpty
          ? targetUser
          : MockUser(
          username: username,
          name: username,
          avatar: 'https://ui-avatars.com/api/?name=$username',
          coverImage: 'https://picsum.photos/seed/cover/800/400',
          isVerified: false,
          bio: 'New user',
          type: 'fan',
          country: '',
          state: '',
          city: '',
          gender: '');

      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ProfileScreen(
          user: user,
          currentUser: _getCurrentUser(),
          authToken: _authToken ?? '',
          posts: _allPosts,
          onEditProfile: () {},
          onPostAction: _handlePostAction,
          users: _allUsers,
          onBack: () => Navigator.of(context).pop(),
          onNavigateToPost: _navigateToPostFromProfile,
          readPosts: _readPosts,
          commentedPosts: _commentedPosts,
          watchedPosts: _watchedPosts,
          cartItemsNotifier: _cartItemsNotifier,
        ),
      ));
    } catch (e) {
      debugPrint("Error redirecting to profile: $e");
    }
  }

  void _navigateToPostFromProfile(Map<String, dynamic> post) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    final currentUser = _getCurrentUser();
    final postAuthor = post['author'] as String? ?? '';
    final isMyPost = postAuthor.isNotEmpty &&
        (postAuthor.trim().toLowerCase() ==
            currentUser.name.trim().toLowerCase() ||
            postAuthor.trim().toLowerCase() == 'you' ||
            postAuthor.trim().toLowerCase() ==
                currentUser.username.trim().toLowerCase());

    setState(() {
      _selectedHomeUser = null;
      _currentIndex = 0;
      _searchQuery = "";
      _mainContentSelectedIndexNotifier.value = isMyPost ? 1 : 0;
    });

    if (_pageController.hasClients) _pageController.jumpToPage(0);
    final postId = post['id'] is int ? post['id'] as int : post.hashCode;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scrollToPostAfterDelay(postId, false);
    });
  }

  void _navigateToAlbumFromProfile(Map<String, dynamic> album) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    setState(() {
      _selectedHomeUser = null;
      _currentIndex = 0;
      _searchQuery = "";
      _mainContentSelectedIndexNotifier.value = 4;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  void _scrollToPostAfterDelay(
      int postId,
      bool isCommentNotification, {
        String? commentAuthor,
        String? commentText,
        dynamic commentId,
      }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      int pollCount = 0;
      bool triggered = false;

      void pollForCallback() {
        if (!mounted || pollCount >= 50) return;
        if (isCommentNotification) {
          if (_scrollToPostWithCommentsCallback != null) {
            _scrollToPostWithCommentsCallback!(postId,
                expandComments: true,
                commentAuthor: commentAuthor,
                commentText: commentText,
                commentId: commentId);
            triggered = true;
          }
        } else {
          if (_scrollToPostCallback != null) {
            _scrollToPostCallback!(postId);
            triggered = true;
          }
        }
        if (!triggered) {
          pollCount++;
          Future.delayed(const Duration(milliseconds: 100), pollForCallback);
        }
      }

      pollForCallback();
    });
  }

  Future<void> _handleIncrementCart(int index) async {
    final item = _cartItemsNotifier.value[index];
    final currentQty = item['quantity'] ?? 1;
    final currentUser = _getCurrentUser();
    await _dbHelper.updateCartQuantity(
        currentUser.username, item['title'], item['author'], currentQty + 1);
    _cartItemsNotifier.value =
    await _dbHelper.getCartItems(currentUser.username);
  }

  Future<void> _handleDecrementCart(int index) async {
    final item = _cartItemsNotifier.value[index];
    final currentQty = item['quantity'] ?? 1;
    if (currentQty > 0) {
      final currentUser = _getCurrentUser();
      await _dbHelper.updateCartQuantity(
          currentUser.username, item['title'], item['author'], currentQty - 1);
      _cartItemsNotifier.value =
      await _dbHelper.getCartItems(currentUser.username);
    }
  }

  Future<void> _handleRemoveCart(int index) async {
    final item = _cartItemsNotifier.value[index];
    final itemTitle = item['title'] as String? ?? 'Item';
    final itemAuthor = item['author'] as String? ?? '';
    final currentUser = _getCurrentUser();
    final isOwnPost = itemAuthor == currentUser.name ||
        itemAuthor == 'You' ||
        (itemAuthor.isNotEmpty &&
            currentUser.name.isNotEmpty &&
            itemAuthor.toLowerCase() == currentUser.name.toLowerCase());

    await _dbHelper.updateCartQuantity(
        currentUser.username, item['title'], item['author'], 0);
    _cartItemsNotifier.value =
    await _dbHelper.getCartItems(currentUser.username);

    if (isOwnPost && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr.itemOutOfStock(itemTitle)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _showCommentDialog(Map<String, dynamic> post,
      {bool enableComments = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => CommentsBottomSheet(
          post: post,
          currentUser: _getCurrentUser(),
          onPostAction: (p, a, {extraData}) {
            _handlePostAction(p, a, extraData: extraData);
          },
          allUsers: _allUsers,
          scrollController: controller,
          allowComments: enableComments,
        ),
      ),
    );
  }

  void _showActionSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFDB2777),
      duration: const Duration(seconds: 1),
    ));
  }

  Future<void> _navigateToCreatePost({String? initialType}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => CreatePostScreen(initialType: initialType)),
    );
    if (result != null && result is Map<String, dynamic>) {
      _onPostCreated(result);
    } else if (result == true) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr.postCreated),
          backgroundColor: const Color(0xFFDB2777),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _hasSyncedPageAfterRebuild = false;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1324),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1000;
          final leftSidebarWidth = isDesktop ? 250.0 : 0.0;
          final rightSidebarWidth = isDesktop ? 300.0 : 0.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                SizedBox(
                  width: leftSidebarWidth,
                  child: SingleChildScrollView(
                    child: LeftSidebar(
                      currentIndex: _currentIndex,
                      onIndexChanged: (index) =>
                          setState(() => _currentIndex = index),
                      isArtist: _isArtist,
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(builder: (context, innerConstraints) {
                  return Column(
                    children: [
                      if (_currentIndex == 0 && _selectedHomeUser == null)
                        TopSearchBar(
                            onChanged: (value) {
                              _onSearchChanged(value);
                            },
                          onTap: () {},
                          onHomeTap: () {
                            setState(() => _currentIndex = 0);
                            if (_mainContentSelectedIndexNotifier.value != 0) {
                              _mainContentSelectedIndexNotifier.value = 0;
                            }
                            if (_mainContentKey.currentState != null) {
                              _mainContentKey.currentState!.resetToFeed();
                            }
                            _pageController.animateToPage(0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                          onSettingsTap: () {
                            setState(() => _currentIndex = 4);
                            _pageController.animateToPage(4,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                          onThemeTap: () => MyApp.of(context).toggleTheme(),
                          onLogoutTap: _handleLogout,
                          onFaqTap: _showFaqDialog,
                          cartItemsNotifier: _cartItemsNotifier,
                          onIncrementCart: _handleIncrementCart,
                          onDecrementCart: _handleDecrementCart,
                          onRemoveCart: _handleRemoveCart,
                          validateCartItemExists: _validateCartItemExists,
                          notificationsNotifier: _notificationsNotifier,
                          onNotificationsUpdated: _updateNotifications,
                          onNotificationTap: _handleNotificationTap,
                          currentUser: _getCurrentUser(),
                        ),
                      Expanded(
                        child: LayoutBuilder(
                            builder: (context, contentConstraints) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: SizedBox(
                                      width: contentConstraints.maxWidth -
                                          (isDesktop ? rightSidebarWidth : 0),
                                      child: _buildCurrentScreen(),
                                    ),
                                  ),
                                  if (isDesktop)
                                    SizedBox(
                                      width: rightSidebarWidth,
                                      child: const RightSidebar(),
                                    ),
                                ],
                              );
                            }),
                      ),
                    ],
                  );
                }),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 1000
          ? _buildBottomNav()
          : null,
    );
  }

  void _showFaqDialog() {
    final theme = Theme.of(context);
    final faqs = [
      {
        'q': 'Does the marketplace offer subscription services?',
        'a': 'Yes, we offer various tiered subscription plans to suit different needs and budgets.',
      },
      {
        'q': 'What are the benefits of subscribing?',
        'a': 'Subscribers enjoy exclusive content, early access to new releases, and ad-free experience.',
      },
      {
        'q': 'Can I cancel my subscription at any time?',
        'a': 'Absolutely! You can manage and cancel your subscription anytime through your account settings.',
      },
      {
        'q': 'How do I become a featured artist?',
        'a': 'Artists with high engagement and quality content are regularly selected for our featured sections.',
      },
      {
        'q': 'How long does it take for my content to be approved for sale?',
        'a': 'Content review typically takes between 24 to 48 hours to ensure it meets our quality community guidelines.',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.live_help_outlined, color: Color(0xFFDB2777)),
            const SizedBox(width: 10),
            Text(context.tr.appName,
                style:
                TextStyle(color: theme.textTheme.titleLarge?.color)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: faqs
                  .map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(faq['q']!,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(faq['a']!,
                          style: TextStyle(
                              color: theme.hintColor, fontSize: 13)),
                    ),
                  ],
                  textColor: const Color(0xFFDB2777),
                  iconColor: const Color(0xFFDB2777),
                  shape: const Border(),
                ),
              ))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr.close,
                style: const TextStyle(color: Color(0xFFDB2777))),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    final bool showLive = _currentIndex == 5;
    return IndexedStack(
      index: showLive ? 1 : 0,
      children: [_buildContentLogic()],
    );
  }

  Widget _buildContentLogic() {
    if (_currentIndex == 4) {
      return SettingsScreen(
        currentUser: _getCurrentUser(),
        onSave: (updatedUser) {
          final currentUser = _getCurrentUser();
          final oldName = currentUser.name;
          setState(() {
            final idx = _allUsers
                .indexWhere((u) => u.username == currentUser.username);
            if (idx != -1) _allUsers[idx] = updatedUser;
            if (oldName != updatedUser.name) {
              for (var post in _userPosts) {
                if (post['author'] == oldName) post['author'] = updatedUser.name;
              }
            }
          });
          _saveUsers();
          _saveUserPosts();
        },
        onBack: () {
          setState(() => _currentIndex = 0);
          _pageController.jumpToPage(0);
        },
        onThemeTap: () => MyApp.of(context).toggleTheme(),
        onFaqTap: _showFaqDialog,
        onLogoutTap: _handleLogout,
        notificationsEnabled: _notificationsEnabled,
        likeNotificationsEnabled: _likeNotificationsEnabled,
        commentNotificationsEnabled: _commentNotificationsEnabled,
        newSubNotificationsEnabled: _newSubNotificationsEnabled,
        tipNotificationsEnabled: _tipNotificationsEnabled,
        messageNotificationsEnabled: _messageNotificationsEnabled,
        expiringSubNotificationsEnabled: _expiringSubNotificationsEnabled,
        upcomingRenewalNotificationsEnabled:
        _upcomingRenewalNotificationsEnabled,
        onNotificationSettingsChanged: (notifications, likes, comments, newSub,
            tip, message, expiring, upcoming) async {
          final prefs = await SharedPreferences.getInstance();
          final currentUser = _getCurrentUser();
          setState(() {
            _notificationsEnabled = notifications;
            _likeNotificationsEnabled = likes;
            _commentNotificationsEnabled = comments;
            _newSubNotificationsEnabled = newSub;
            _tipNotificationsEnabled = tip;
            _messageNotificationsEnabled = message;
            _expiringSubNotificationsEnabled = expiring;
            _upcomingRenewalNotificationsEnabled = upcoming;
          });
          await prefs.setBool(
              'notifications_enabled_${currentUser.username}', notifications);
          await prefs.setBool(
              'like_notifications_enabled_${currentUser.username}', likes);
          await prefs.setBool(
              'comment_notifications_enabled_${currentUser.username}', comments);
          await prefs.setBool(
              'new_sub_notifications_enabled_${currentUser.username}', newSub);
          await prefs.setBool(
              'tip_notifications_enabled_${currentUser.username}', tip);
          await prefs.setBool(
              'message_notifications_enabled_${currentUser.username}', message);
          await prefs.setBool(
              'expiring_sub_notifications_enabled_${currentUser.username}',
              expiring);
          await prefs.setBool(
              'upcoming_renewal_notifications_enabled_${currentUser.username}',
              upcoming);
          _filterNotifications();
        },
      );
    }

    if (_currentIndex == 5) return const SizedBox();

    if (_currentIndex == 6) {
      final currentBookmarks = _bookmarkedPosts.where((p) {
        final authorName = p['author'] as String?;
        return !_allUsers
            .any((u) => u.name == authorName && u.type == 'blocked');
      }).toList();
      final nonBlockedUsers =
      _allUsers.where((u) => u.type != 'blocked').toList();

      return MainContentArea(
        key: ValueKey("bookmarks_${currentBookmarks.length}"),
        posts: currentBookmarks,
        searchQuery: _searchQuery,
        selectedUser: _selectedHomeUser,
        users: nonBlockedUsers,
        onPostCreated: _onPostCreated,
        onPostDeleted: _onPostDeleted,
        onPostAction: _handlePostAction,
        onAddToCart: _handleAddToCart,
        onUserAction: _handleUserAction,
        onScrollToPostReady: null,
        onScrollToPostWithCommentsReady: null,
        onUserTap: (user) {
          setState(() {
            _selectedHomeUser = user;
            _currentIndex = 0;
            if (_pageController.hasClients) _pageController.jumpToPage(0);
          });
        },
        selectedIndexNotifier: ValueNotifier(2),
        currentUser: _getCurrentUser(),
        readPosts: _readPosts,
        watchedPosts: _watchedPosts,
        bookmarkedPosts: _bookmarkedPosts,
        cartItemsNotifier: _cartItemsNotifier,
        onRefresh: () {
          setState(() => _feedLoaded = false);
          _loadData();
        },
      );
    }

    _syncPageController();

    final filteredPosts = _allPosts.where((p) {
      if (_targetPostIdFromNotification != null &&
          p['id']?.toString() == _targetPostIdFromNotification.toString()) {
        return true;
      }
      final authorName = p['author'] as String?;
      final currentUser = _getCurrentUser();
      if (authorName == currentUser.name) return true;
      final isBlocked = _allUsers.any((u) =>
      u.name == authorName &&
          (u.type == 'blocked' || u.type == 'blocked_by'));
      return !isBlocked;
    }).toList();

    final nonBlockedUsers = _allUsers
        .where((u) => u.type != 'blocked' && u.type != 'blocked_by')
        .toList();

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
            _hasSyncedPageAfterRebuild = true;
          });
        }
      },
      children: [
        _selectedHomeUser != null
            ? ProfileScreen(
          user: _selectedHomeUser,
          authToken: _authToken ?? '',
          posts: _allPosts.where((p) {
            final isMe = _selectedHomeUser!.username ==
                _getCurrentUser().username;
            if (isMe && p['author'] == 'You') return true;
            if (p['author'] != null &&
                _selectedHomeUser!.name.isNotEmpty) {
              return p['author'].toString().toLowerCase() ==
                  _selectedHomeUser!.name.toLowerCase();
            }
            return p['author'] == _selectedHomeUser!.name;
          }).toList(),
          onEditProfile: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                currentUser: _selectedHomeUser!,
                onSave: (updatedUser) {
                  setState(() {
                    int idx = _allUsers.indexWhere(
                            (u) => u.username == updatedUser.username);
                    if (idx != -1) _allUsers[idx] = updatedUser;
                    if (_selectedHomeUser?.username ==
                        updatedUser.username) {
                      _selectedHomeUser = updatedUser;
                    }
                  });
                  _saveUsers();
                },
                onBack: () => Navigator.of(context).pop(),
              ),
            ));
          },
          onPostAction: _handlePostAction,
          onPostDeleted: _onPostDeleted,
          onUserAction: _handleUserAction,
          onUserTap: (user) {
            setState(() {
              _selectedHomeUser = user;
              _currentIndex = 0;
              if (_pageController.hasClients)
                _pageController.jumpToPage(0);
            });
          },
          followerCount:
          _getDisplayStats(_selectedHomeUser!, 'followers'),
          followingCount:
          _getDisplayStats(_selectedHomeUser!, 'following'),
          subscriberCount:
          _getDisplayStats(_selectedHomeUser!, 'subscribers'),
          users: nonBlockedUsers,
          currentUser: _getCurrentUser(),
          searchQuery: _searchQuery,
          readPosts: _readPosts,
          commentedPosts: _commentedPosts,
          watchedPosts: _watchedPosts,
          cartItemsNotifier: _cartItemsNotifier,
          onBack: () => setState(() => _selectedHomeUser = null),
          onNavigateToPost: _navigateToPostFromProfile,
          onUpdateProfile: (updatedUser) {
            setState(() {
              final oldName = _selectedHomeUser?.name;
              int idx = _allUsers.indexWhere(
                      (u) => u.username == updatedUser.username);
              if (idx != -1) _allUsers[idx] = updatedUser;
              if (_selectedHomeUser?.username == updatedUser.username) {
                _selectedHomeUser = updatedUser;
              }
              if (oldName != null && oldName != updatedUser.name) {
                for (var list in [
                  _userPosts,
                  _communityPosts,
                  _samplePosts
                ]) {
                  for (var post in list) {
                    if (post['author'] == oldName)
                      post['author'] = updatedUser.name;
                  }
                }
              }
            });
            _saveUsers();
            _saveUserPosts();
          },
        )
            : MainContentArea(
          key: _mainContentKey,
          posts: filteredPosts,
          searchQuery: _searchQuery,
          selectedUser: _selectedHomeUser,
          users: nonBlockedUsers,
          onPostCreated: _onPostCreated,
          onPostDeleted: _onPostDeleted,
          onPostAction: _handlePostAction,
          onAddToCart: _handleAddToCart,
          onUserAction: _handleUserAction,
          onScrollToPostReady: (callback) {
            _scrollToPostCallback = callback;
          },
          onScrollToPostWithCommentsReady: (callback) {
            _scrollToPostWithCommentsCallback = callback;
          },
          onUserTap: (user) {
            setState(() {
              _selectedHomeUser = user;
              _currentIndex = 0;
              if (_pageController.hasClients)
                _pageController.jumpToPage(0);
            });
          },
          selectedIndexNotifier: _mainContentSelectedIndexNotifier,
          currentUser: _getCurrentUser(),
          readPosts: _readPosts,
          watchedPosts: _watchedPosts,
          bookmarkedPosts: _bookmarkedPosts,
          cartItemsNotifier: _cartItemsNotifier,
          isActive: _currentIndex == 0,
          targetPostId: _targetPostIdFromNotification,
          onRefresh: () {
            setState(() => _feedLoaded = false);
            _loadData();
          },
        ),
        AlbumsScreen(),
        ConnectionsScreen(
          users: _allUsers,
          username: _getCurrentUser().username,
          posts: _allPosts,
          onPostAction: _handlePostAction,
          onUserAction: _handleUserAction,
          highlightUser: _connectionsHighlightUser,
          onUserTap: (user) {
            setState(() {
              _selectedHomeUser = user;
              _currentIndex = 2;
              if (_pageController.hasClients) _pageController.jumpToPage(0);
            });
          },
        ),
        ProfileScreen(
          posts: _userPosts,
          onPostDeleted: _onPostDeleted,
          authToken: _authToken ?? '',
          onEditProfile: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                currentUser: _getCurrentUser(),
                onSave: (updatedUser) {
                  setState(() {
                    final idx = _allUsers.indexWhere(
                            (u) => u.username == updatedUser.username);
                    if (idx != -1) _allUsers[idx] = updatedUser;
                    final oldName = _getCurrentUser().name;
                    if (oldName != updatedUser.name) {
                      for (var post in _userPosts) {
                        if (post['author'] == oldName)
                          post['author'] = updatedUser.name;
                      }
                    }
                  });
                  _saveUsers();
                  _saveUserPosts();
                },
                onBack: () => Navigator.of(context).pop(),
              ),
            ));
          },
          onPostAction: _handlePostAction,
          onUserAction: _handleUserAction,
          onUserTap: (user) {
            setState(() {
              _selectedHomeUser = user;
              _currentIndex = 3;
              if (_pageController.hasClients) _pageController.jumpToPage(0);
            });
          },
          followerCount: _getDisplayStats(_getCurrentUser(), 'followers'),
          followingCount: _getDisplayStats(_getCurrentUser(), 'following'),
          subscriberCount: _getDisplayStats(_getCurrentUser(), 'subscribers'),
          users: nonBlockedUsers,
          currentUser: _getCurrentUser(),
          searchQuery: _searchQuery,
          readPosts: _readPosts,
          commentedPosts: _commentedPosts,
          watchedPosts: _watchedPosts,
          cartItemsNotifier: _cartItemsNotifier,
          onUpdateProfile: (updatedUser) {
            final oldName = _getCurrentUser().name;
            setState(() {
              final idx = _allUsers
                  .indexWhere((u) => u.username == _getCurrentUser().username);
              if (idx != -1) _allUsers[idx] = updatedUser;
              if (oldName != updatedUser.name) {
                for (var list in [_userPosts, _communityPosts, _samplePosts]) {
                  for (var post in list) {
                    if (post['author'] == oldName || post['author'] == 'You') {
                      post['author'] = updatedUser.name;
                    }
                  }
                }
              }
            });
            _saveUsers();
            _saveUserPosts();
          },
          onNavigateToPost: _navigateToPostFromProfile,
          onSettingsTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SettingsScreen(
                currentUser: _getCurrentUser(),
                notificationsEnabled: _notificationsEnabled,
                likeNotificationsEnabled: _likeNotificationsEnabled,
                commentNotificationsEnabled: _commentNotificationsEnabled,
                newSubNotificationsEnabled: _newSubNotificationsEnabled,
                tipNotificationsEnabled: _tipNotificationsEnabled,
                messageNotificationsEnabled: _messageNotificationsEnabled,
                expiringSubNotificationsEnabled:
                _expiringSubNotificationsEnabled,
                upcomingRenewalNotificationsEnabled:
                _upcomingRenewalNotificationsEnabled,
                onNotificationSettingsChanged: (notifications, likes, comments,
                    newSub, tip, message, expiring, upcoming) async {
                  final prefs = await SharedPreferences.getInstance();
                  final currentUser = _getCurrentUser();
                  setState(() {
                    _notificationsEnabled = notifications;
                    _likeNotificationsEnabled = likes;
                    _commentNotificationsEnabled = comments;
                    _newSubNotificationsEnabled = newSub;
                    _tipNotificationsEnabled = tip;
                    _messageNotificationsEnabled = message;
                    _expiringSubNotificationsEnabled = expiring;
                    _upcomingRenewalNotificationsEnabled = upcoming;
                  });
                  await prefs.setBool(
                      'notifications_enabled_${currentUser.username}',
                      notifications);
                  await prefs.setBool(
                      'like_notifications_enabled_${currentUser.username}',
                      likes);
                  await prefs.setBool(
                      'comment_notifications_enabled_${currentUser.username}',
                      comments);
                  await prefs.setBool(
                      'new_sub_notifications_enabled_${currentUser.username}',
                      newSub);
                  await prefs.setBool(
                      'tip_notifications_enabled_${currentUser.username}', tip);
                  await prefs.setBool(
                      'message_notifications_enabled_${currentUser.username}',
                      message);
                  await prefs.setBool(
                      'expiring_sub_notifications_enabled_${currentUser.username}',
                      expiring);
                  await prefs.setBool(
                      'upcoming_renewal_notifications_enabled_${currentUser.username}',
                      upcoming);
                  _filterNotifications();
                },
                onSave: (updatedUser) {
                  final currentUser = _getCurrentUser();
                  final oldName = currentUser.name;
                  setState(() {
                    final idx = _allUsers.indexWhere(
                            (u) => u.username == currentUser.username);
                    if (idx != -1) _allUsers[idx] = updatedUser;
                    if (oldName != updatedUser.name) {
                      for (var post in _userPosts) {
                        if (post['author'] == oldName)
                          post['author'] = updatedUser.name;
                      }
                    }
                  });
                  _saveUsers();
                  _saveUserPosts();
                },
                onBack: () => Navigator.of(context).pop(),
                onThemeTap: () => MyApp.of(context).toggleTheme(),
                onLogoutTap: _handleLogout,
              ),
            ));
          },
        ),
      ],
    );
  }

  Future<void> _handleUserAction(MockUser user, String action) async {
    final currentUser = _getCurrentUser();
    switch (action) {
      case 'Remove':
        await _dbHelper.unfollowUser(user.username, currentUser.username);
        break;
      case 'Unfollow':
        await _dbHelper.unfollowUser(currentUser.username, user.username);
        break;
      case 'Unblock':
        await _dbHelper.unblockUser(currentUser.username, user.username);
        break;
      case 'Follow':
        await _dbHelper.followUser(currentUser.username, user.username);
        break;
      case 'Block':
        await _dbHelper.blockUser(currentUser.username, user.username);
        break;
      case 'Subscribe':
        await _dbHelper.subscribeToUser(currentUser.username, user.username);
        break;
      case 'Unsubscribe':
        await _dbHelper.unsubscribeFromUser(currentUser.username, user.username);
        break;
    }
    await _loadData();
  }

  String _getDisplayStats(MockUser user, String type) {
    if (user.username == _getCurrentUser().username) {
      if (type == 'followers') {
        return _allUsers
            .where((u) => u.type == 'follower' || u.type == 'mutual')
            .length
            .toString();
      } else if (type == 'following') {
        return _allUsers
            .where((u) => u.type == 'following' || u.type == 'mutual')
            .length
            .toString();
      } else if (type == 'subscribers') {
        final followers = _allUsers
            .where((u) => u.type == 'follower' || u.type == 'mutual')
            .length;
        return (followers ~/ 5).toString();
      }
    }

    int seed = user.username.codeUnits.fold(0, (p, c) => p + c);
    if (type == 'followers') {
      int count = (seed * 13) % 4950 + 50;
      return count > 1000 ? "${(count / 1000).toStringAsFixed(1)}K" : "$count";
    } else if (type == 'subscribers') {
      return "${(seed * 3) % 500 + 10}";
    } else {
      return "${(seed * 7) % 490 + 10}";
    }
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _getBottomNavIndex(_currentIndex),
        onTap: (index) {
          _targetPostIdFromNotification = null;
          if (index == 0 && _currentIndex == 0) {
            setState(() {
              _selectedHomeUser = null;
              _selectedSuggestedUser = null;
            });
            if (_mainContentSelectedIndexNotifier.value != 0) {
              _mainContentSelectedIndexNotifier.value = 0;
            }
            if (_mainContentKey.currentState != null) {
              _mainContentKey.currentState!.resetToFeed();
            }
          }

          int targetIndex = index;
          // if (index == 2) targetIndex = 5;
          // if (index == 3) targetIndex = 2;
          // if (index == 4) targetIndex = 3;

          setState(() => _currentIndex = targetIndex);

          if (targetIndex < 4 && targetIndex != 2) {
            _pageController.animateToPage(targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          } else if (targetIndex == 2) {
            _pageController.animateToPage(2,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          }
        },
        selectedItemColor:
        (_currentIndex == 0 && _selectedHomeUser != null)
            ? theme.hintColor
            : const Color(0xFFDB2777),
        unselectedItemColor: theme.hintColor,
        backgroundColor: theme.cardColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: context.tr.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.photo_library),
            activeIcon: const Icon(Icons.photo_library),
            label: context.tr.albums,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: context.tr.connections,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: context.tr.profile,
          ),
        ],
      ),
    );
  }

  int _getBottomNavIndex(int currentIndex) {
    // if (currentIndex == 0) return 0;
    // if (currentIndex == 1) return 1;
    // if (currentIndex == 5) return 2;
    // if (currentIndex == 2) return 3;
    // if (currentIndex == 3) return 4;
    // return 0;
    return currentIndex;
  }
}