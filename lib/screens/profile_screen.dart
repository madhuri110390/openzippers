import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_models.dart';
import '../models/rating_response.dart';
import '../providers/block_provider.dart';
import '../providers/connections_provider.dart';
import '../providers/delete_post_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/rating_provider.dart';
import '../providers/subscriptions_list_provider.dart';
import '../viewmodels/delete_post_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/register_view_model.dart' hide dioProvider;
import 'package:openzippers/screens/subscriptions_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';

import '../widgets/media_player_widgets.dart';
import '../helpers/database_helper.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';
import '../widgets/rating_dialog.dart';
import 'copyright_screen.dart';
import 'edit_profile_screen.dart';
import 'like_button.dart';
import 'publishing_screen.dart';
import 'create_post_screen.dart';
import '../helpers/post_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../widgets/tip_dialog.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/albums_view.dart';
import '../widgets/comment_section.dart';
import '../widgets/comments_bottom_sheet.dart';
import 'reels_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String authToken;
  final List<Map<String, dynamic>> posts;
  final VoidCallback onEditProfile;
  final Function(Map<String, dynamic>, String, {dynamic extraData}) onPostAction;
  final Function(Map<String, dynamic>)? onPostDeleted;
  final String followerCount;
  final String followingCount;
  final String subscriberCount;
  final List<MockUser> users;
  final MockUser currentUser;
  final String searchQuery;
  final Function(MockUser, String)? onUserAction;
  final Function(MockUser)? onUserTap;
  final Function(MockUser)? onUpdateProfile;
  final VoidCallback? onBack;
  final VoidCallback? onSettingsTap;
  final MockUser? user;
  final Function(Map<String, dynamic>)? onNavigateToPost;
  final Function(Map<String, dynamic>)? onNavigateToAlbum;
  final List<Map<String, dynamic>> readPosts;
  final List<Map<String, dynamic>> commentedPosts;
  final VoidCallback? onRefresh;
  final List<Map<String, dynamic>> watchedPosts;
  final ValueNotifier<List<Map<String, dynamic>>>? cartItemsNotifier;

  const ProfileScreen({
    super.key,
    required this.authToken,
    required this.posts,
    required this.onEditProfile,
    required this.onPostAction,
    required this.currentUser,
    this.user,
    this.onUserAction,
    this.onUserTap,
    this.onUpdateProfile,
    this.onPostDeleted,
    this.followerCount = "0",
    this.followingCount = "0",
    this.subscriberCount = "0",
    this.users = const [],
    this.searchQuery = "",
    this.onNavigateToPost,
    this.onNavigateToAlbum,
    this.onBack,
    this.readPosts = const [],
    this.commentedPosts = const [],
    this.watchedPosts = const [],
    this.onSettingsTap,
    this.cartItemsNotifier,
    this.onRefresh,
  });

  bool get fromProfile => true;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTabIndex = 0;
  final Map<dynamic, int> selectedRatings = {};
  bool _isVideoPlaying = false;
  bool _showCoverMenu = false;
  bool _showAvatarMenu = false;
  late ProfileViewModel _viewModel;
  List<Map<String, dynamic>> _posts = [];
  static const Color _kPink = Color(0xFFDB2777);
  final Set<String> _expandedPostIds = {};
  final ScrollController _scrollController = ScrollController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _albums = [];
  final Set<String> _likedPostIds = {};
  final Set<String> _failedMediaUrls = {};
  String _followerCount = "0";
  String _followingCount = "0";
  bool? _isFollowingOverride;
  bool _isFollowLoading = false;
  bool? _isBlockedOverride;
  bool _isBlockLoading = false;

  // ── NEW: list vs grid toggle ──────────────────────────────────
  bool _isListView = false;

  MockUser? _localUserOverride;

  MockUser get effectiveUser {
    if (_localUserOverride != null) return _localUserOverride!;
    final baseUser = widget.user ?? widget.currentUser;
    if (widget.users.isNotEmpty) {
      final idx = widget.users.indexWhere((u) => u.username == baseUser.username);
      if (idx != -1) return widget.users[idx];
    }
    return baseUser;
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

  bool get isMe {
    if (widget.user == null) return true;
    return effectiveUser.username == widget.currentUser.username;
  }

  bool get isFollowing =>
      _isFollowingOverride ?? effectiveUser.type == 'following';

  @override
  void initState() {
    super.initState();
    final dio = ref.read(dioProvider);
    _viewModel = ProfileViewModel(dio);

    _posts = List<Map<String, dynamic>>.from(widget.posts);

    for (var p in widget.readPosts) {
      _likedPostIds.add(
        p['id']?.toString() ?? "${p['title']}_${p['author']}",
      );
    }

    _loadAlbums();
    _fetchConnectionCounts();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? widget.authToken;
      _viewModel.fetchPresence(token);
      await Future.wait([
        _loadPostsFromApi(),
        _refreshUserData(),
        if (isMe) _fetchLoggedInUserDetails() else Future.value(),
      ]);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posts != widget.posts && _posts.isEmpty) {
      setState(() {
        _posts = List<Map<String, dynamic>>.from(widget.posts);
      });
      _prefillRatings(_posts);
    }
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
                .submitRating(
              postId: post['id'],
              rating: stars,
            );

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

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rating submitted!')),
            );
          } catch (e) {
            debugPrint('Rating Error: $e');
          }
        },
      ),
    );
  }

  Future<void> _fetchConnectionCounts() async {
    try {
      final username = effectiveUser.username;
      if (username.isEmpty) return;

      final response = await ref.read(connectionsProvider(username).future);
      if (!mounted) return;

      final currentUserConnections = await ref.read(
        connectionsProvider(widget.currentUser.username).future,
      );
      if (!mounted) return;

      final amFollowing = currentUserConnections.data.following
          .any((u) => u.id == effectiveUser.id);
      final isBlocked = currentUserConnections.data.blocked
          .any((u) => u.id == effectiveUser.id);

      setState(() {
        _followerCount = response.data.counts.followers.toString();
        _followingCount = response.data.counts.following.toString();
        if (_isFollowingOverride == null) {
          _isFollowingOverride = amFollowing;
        }
        // ← Always sync blocked state from server, not just on first load
        _isBlockedOverride = isBlocked;
      });
    } catch (e) {
      debugPrint('_fetchConnectionCounts error: $e');
      if (mounted) {
        setState(() {
          _followerCount = widget.followerCount;
          _followingCount = widget.followingCount;
        });
      }
    }
  }

  Future<void> _resolveLocationsUpdates(int? cId, int? sId, int? cityId) async {
    if (cId == null) return;
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final results = await Future.wait([
        authRepo.getCountries(),
        sId != null
            ? authRepo.getStates(cId.toString())
            : Future.value(<StateModel>[]),
        (sId != null && cityId != null)
            ? authRepo.getCities(sId.toString())
            : Future.value(<CityModel>[]),
      ]);

      final countries = results[0] as List<Country>;
      final states = results[1] as List<StateModel>;
      final cities = results[2] as List<CityModel>;

      final cObj = countries.firstWhere((c) => c.id == cId,
          orElse: () => Country(id: 0, name: ''));
      String mappedCountry =
      cObj.name.isNotEmpty ? cObj.name : effectiveUser.country;

      String mappedState = effectiveUser.state;
      if (sId != null && states.isNotEmpty) {
        final sObj = states.firstWhere((s) => s.id == sId,
            orElse: () => StateModel(id: 0, name: ''));
        if (sObj.name.isNotEmpty) mappedState = sObj.name;
      }

      String mappedCity = effectiveUser.city;
      if (cityId != null && cities.isNotEmpty) {
        final cityObj = cities.firstWhere((c) => c.id == cityId,
            orElse: () => CityModel(id: 0, name: ''));
        if (cityObj.name.isNotEmpty) mappedCity = cityObj.name;
      }

      if (mounted) {
        setState(() {
          _localUserOverride = _localUserOverride?.copyWith(
            country: mappedCountry,
            state: mappedState,
            city: mappedCity,
          );
        });
        if (isMe && _localUserOverride != null) {
          widget.onUpdateProfile?.call(_localUserOverride!);
        }
      }
    } catch (e) {
      debugPrint('Error mapping locations: $e');
    }
  }

  Future<void> _refreshUserData() async {
    if (effectiveUser.username.isEmpty) return;
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final apiResponse =
      await authRepo.getUserByUsername(effectiveUser.username);

      if (apiResponse.success && apiResponse.data != null) {
        final user = apiResponse.data!.user;
        final relationships =
        await _dbHelper.getRelationships(widget.currentUser.username);
        String newType = 'public';
        bool isSubscribed = false;
        if (relationships.containsKey(user.username)) {
          newType = relationships[user.username]!;
          isSubscribed = (newType == 'subscribed');
        }

        if (mounted) {
          setState(() {
            _localUserOverride = effectiveUser.copyWith(
              id: user.id,
              name: user.name,
              username: user.username,
              isArtist: user.isArtist ?? false,
              avatar: user.avatarUrl ?? effectiveUser.avatar,
              coverImage: user.coverImageUrl ?? effectiveUser.coverImage,
              gender: user.gender ?? effectiveUser.gender,
              isVerified: user.isVerified ?? effectiveUser.isVerified,
              isEmailVerified: user.emailVerifiedAt != null,
              joinedDate: user.createdAt != null
                  ? DateTime.tryParse(user.createdAt!) ?? effectiveUser.joinedDate
                  : effectiveUser.joinedDate,
              bio: user.bio ?? effectiveUser.bio,
              phone: user.mobileNumber ?? effectiveUser.phone,
              countryId: user.countryId,
              stateId: user.stateId,
              cityId: user.cityId,
              type: newType,
              isSubscribed: isSubscribed,
            );
          });
          _resolveLocationsUpdates(user.countryId, user.stateId, user.cityId);
          if (_albums.isEmpty) _loadAlbums();
          _loadAlbums();
          _fetchConnectionCounts();
        }
      }
    } catch (e) {
      debugPrint("Error refreshing user data: $e");
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await _dbHelper.getAlbums(
          username: effectiveUser.username, onlyPublic: !isMe);
      if (mounted) setState(() => _albums = albums);
    } catch (e) {
      debugPrint("Error loading albums: $e");
    }
  }

  Future<void> _loadPostsFromApi() async {
    try {
      if (!mounted) return;
      final authRepo = ref.read(authRepositoryProvider);
      final username = effectiveUser.username;
      if (username.isEmpty) return;
      final apiResponse = await authRepo.getUserByUsername(username);
      if (apiResponse.success && apiResponse.data != null && mounted) {
        final posts = apiResponse.data!.posts ?? [];
        final normalized = posts.map((p) {
          final raw = Map<String, dynamic>.from(p as Map);
          final map = PostHelper.normalizePost(raw);
          map['id'] = raw['id'];
          map['commentsCount'] =
              raw['comments_count'] ?? raw['commentsCount'] ?? 0;
          map['likeCount'] =
              raw['likes_count'] ?? raw['likeCount'] ?? raw['like_count'] ?? 0;
          map['averageRating'] = raw['averageRating'] ??
              raw['average_rating'] ??
              raw['avg_rating'] ??
              0;
          map['average_rating'] = map['averageRating'];
          map['totalRatings'] = raw['totalRatings'] ??
              raw['total_ratings'] ??
              raw['rating_count'] ??
              0;
          map['total_ratings'] = map['totalRatings'];
          map['my_rating'] =
              raw['my_rating'] ?? raw['user_rating'] ?? raw['rating'] ?? 0;
          map['user_rating'] = map['my_rating'];
          map['imageUrl'] =
              raw['image'] ?? raw['imageUrl'] ?? raw['thumbnail'] ?? '';
          map['filePath'] = raw['video_url'] ??
              raw['audio_url'] ??
              raw['literature_url'] ??
              raw['image'] ??
              '';
          map['coverPath'] =
              raw['preview_url'] ?? raw['cover'] ?? raw['image'] ?? '';
          map['is_liked'] = raw['is_liked'];
          return map;
        }).where((p) {
          final deletedAt = p['deleted_at']?.toString() ?? '';
          if (deletedAt.isNotEmpty && deletedAt != 'null') return false;
          final imageUrl = p['imageUrl']?.toString() ?? '';
          if (imageUrl.isEmpty) return true;
          if (!imageUrl.startsWith('http')) return false;
          const brokenPatterns = ['/2026/04/17773'];
          return !brokenPatterns.any((pattern) => imageUrl.contains(pattern));
        }).toList();

        if (mounted) {
          final savedOffset =
          _scrollController.hasClients ? _scrollController.offset : 0.0;

          setState(() {
            if (_posts.isEmpty) {
              _posts = normalized;
            } else {
              for (final updated in normalized) {
                final id = updated['id']?.toString() ?? '';
                if (id.isEmpty) continue;
                final existingIdx = _posts.indexWhere(
                      (p) => p['id']?.toString() == id,
                );
                if (existingIdx != -1) {
                  final localCount =
                  (_posts[existingIdx]['commentsCount'] ?? 0) as num;
                  final serverCount = (updated['commentsCount'] ?? 0) as num;
                  if (serverCount > localCount) {
                    _posts[existingIdx]['commentsCount'] =
                    updated['commentsCount'];
                  }
                  _posts[existingIdx]['likeCount'] = updated['likeCount'];
                  _posts[existingIdx]['averageRating'] =
                  updated['averageRating'];
                  _posts[existingIdx]['totalRatings'] = updated['totalRatings'];
                  _posts[existingIdx]['imageUrl'] = updated['imageUrl'];
                  _posts[existingIdx]['filePath'] = updated['filePath'];
                  _posts[existingIdx]['coverPath'] = updated['coverPath'];
                } else {
                  _posts.add(updated);
                }
              }
              if (normalized.isNotEmpty) {
                _posts.removeWhere((p) {
                  final id = p['id']?.toString() ?? '';
                  return id.isNotEmpty &&
                      !normalized.any((n) => n['id']?.toString() == id);
                });
              }

              for (final p in normalized) {
                final id = p['id']?.toString() ?? '';
                if (id.isEmpty) continue;
                if (p['is_liked'] == true || p['is_liked'] == 1) {
                  _likedPostIds.add(id);
                }
              }

              _prefillRatings(_posts);
            }
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                _scrollController.hasClients &&
                savedOffset > 0 &&
                savedOffset <= _scrollController.position.maxScrollExtent) {
              _scrollController.jumpTo(savedOffset);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('_loadPostsFromApi error: $e');
    }
  }

  Future<void> _fetchLoggedInUserDetails() async {
    if (!isMe) return;
    final prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('auth_token');
    if (authToken == null) return;
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userProfileResponse = await authRepo.getUserDetails();
      if (userProfileResponse.success && userProfileResponse.data != null) {
        final user = userProfileResponse.data!.user;
        await prefs.setInt('role_id', user.roleId);
        await prefs.setBool('is_artist', user.isArtist ?? false);
        if (mounted) {
          setState(() {
            _localUserOverride = effectiveUser.copyWith(
              id: user.id,
              name: user.name,
              username: user.username,
              avatar: user.avatarUrl ?? effectiveUser.avatar,
              coverImage: user.coverImageUrl ?? effectiveUser.coverImage,
              gender: user.gender ?? effectiveUser.gender,
              isVerified: user.isVerified ?? effectiveUser.isVerified,
              isEmailVerified: user.emailVerifiedAt != null,
              joinedDate: user.createdAt != null
                  ? DateTime.tryParse(user.createdAt!) ?? effectiveUser.joinedDate
                  : effectiveUser.joinedDate,
              bio: user.bio ?? effectiveUser.bio,
              phone: user.mobileNumber ?? effectiveUser.phone,
              countryId: user.countryId,
              stateId: user.stateId,
              cityId: user.cityId,
            );
          });
          _resolveLocationsUpdates(user.countryId, user.stateId, user.cityId);
          if (_localUserOverride != null)
            widget.onUpdateProfile?.call(_localUserOverride!);
        }
        final rawPosts = userProfileResponse.posts.isNotEmpty
            ? userProfileResponse.posts
            : (userProfileResponse.data?.posts ?? []);
        if (rawPosts.isNotEmpty) {
          final normalizedPosts = rawPosts
              .map((p) => PostHelper.normalizePost(p))
              .where((p) {
            final postId = p['id']?.toString() ?? '';
            final title = p['title']?.toString().trim() ?? '';
            final deletedAt = p['deleted_at']?.toString() ?? '';
            if (postId.isEmpty || title.isEmpty) return false;
            if (deletedAt.isNotEmpty && deletedAt != 'null') return false;
            return true;
          }).toList();
          if (mounted) {
            setState(() {
              for (final updated in normalizedPosts) {
                final id = updated['id']?.toString() ?? '';
                if (id.isEmpty) continue;
                final existingIdx =
                _posts.indexWhere((p) => p['id']?.toString() == id);
                if (existingIdx == -1) _posts.add(updated);
              }
              if (_posts.isEmpty) _posts = normalizedPosts;
            });
          }
        } else {
          final int? userId = prefs.getInt('user_id');
          if (userId != null) {
            final response = await authRepo.getUserById(userId);
            if (response.posts.isNotEmpty) {
              final normalizedPosts = response.posts
                  .map((p) => PostHelper.normalizePost(p))
                  .where((p) {
                final postId = p['id']?.toString() ?? '';
                final title = p['title']?.toString().trim() ?? '';
                final deletedAt = p['deleted_at']?.toString() ?? '';
                if (postId.isEmpty || title.isEmpty) return false;
                if (deletedAt.isNotEmpty && deletedAt != 'null') return false;
                return true;
              }).toList();
              if (mounted) {
                setState(() {
                  for (final updated in normalizedPosts) {
                    final id = updated['id']?.toString() ?? '';
                    if (id.isEmpty) continue;
                    final existingIdx =
                    _posts.indexWhere((p) => p['id']?.toString() == id);
                    if (existingIdx == -1) _posts.add(updated);
                  }
                  if (_posts.isEmpty) _posts = normalizedPosts;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  bool _isFree(dynamic price) {
    if (price == null) return true;
    final p = price.toString().toLowerCase().replaceAll('\$', '').trim();
    return p == 'free' || p == '0' || p == '0.00';
  }

  String _localizeType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return context.tr.image;
      case 'video':
      case 'reel':
      case 'reels':
        return context.tr.video;
      case 'song':
        return context.tr.song;
      case 'literature':
        return context.tr.literature;
      default:
        return type;
    }
  }

  bool _isUnlocked(Map<String, dynamic> post) {
    if (isMe) return true;
    if (_isFree(post['price'])) return true;
    return effectiveUser.isSubscribed;
  }

  ImageProvider _getAvatarImage(String avatarPath) {
    final defaultUrl =
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(effectiveUser.name)}&background=DB2777&color=fff';
    if (avatarPath.isEmpty) return NetworkImage(defaultUrl);
    try {
      if (avatarPath.startsWith('http')) return NetworkImage(avatarPath);
      final file = File(avatarPath);
      if (file.existsSync()) return FileImage(file);
      return NetworkImage(defaultUrl);
    } catch (e) {
      return NetworkImage(defaultUrl);
    }
  }

  bool _isUselessText(String text) {
    if (text.trim().isEmpty) return true;
    final uselessPatterns = [
      'hget', 'ddd', 'get', '...', 'etc', 'test', 'temp',
      'vhhh', 'fvghhh', 'gghj', 'vvbbb'
    ];
    final lowerText = text.trim().toLowerCase();
    for (var pattern in uselessPatterns) {
      if (lowerText == pattern || lowerText.contains(pattern)) return true;
    }
    if (text.trim().length <= 10) {
      final uniqueChars = text.trim().split('').toSet().length;
      if (uniqueChars == 1) return true;
      if (text.trim().length <= 6 && uniqueChars <= 2) return true;
    }
    return false;
  }

  Widget _buildFilteredText(String text, TextStyle style,
      {int maxLines = 2}) {
    final cleanedText = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
    if (_isUselessText(cleanedText)) return const SizedBox.shrink();
    return Text(cleanedText,
        style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }

  bool _isInaccessibleImageUrl(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) return false;
    return false;
  }

  bool _postHasDisplayableImage(Map<String, dynamic> post) {
    final type =
    (post['type'] ?? post['post_type'] ?? '').toString().toLowerCase();
    if (type == 'song' || type == 'audio' || type == 'literature') return true;

    final imageUrl = post['imageUrl']?.toString().trim() ?? '';
    final filePath = post['filePath']?.toString().trim() ?? '';
    final coverPath = post['coverPath']?.toString().trim() ?? '';

    final urls = [imageUrl, filePath, coverPath]
        .where((u) => u.isNotEmpty && u.startsWith('http'))
        .toList();

    if (urls.isNotEmpty && urls.every((u) => _failedMediaUrls.contains(u))) {
      return false;
    }
    return true;
  }

  List<Map<String, dynamic>> get _filteredPosts {
    var posts = _posts;
    switch (_selectedTabIndex) {
      case 1:
        posts = posts.where((p) => p['type'] == 'Image').toList();
        break;
      case 2:
        posts = posts.where((p) => p['type'] == 'Song').toList();
        break;
      case 3:
        posts = posts
            .where((p) =>
        p['type'] == 'Video' ||
            p['type'] == 'Reel' ||
            p['type'] == 'Reels')
            .toList();
        break;
      case 4:
        posts = posts.where((p) => p['type'] == 'Literature').toList();
        break;
    }
    return posts.where(_postHasDisplayableImage).toList();
  }

  List<MockUser> get _filteredUsers {
    final query = widget.searchQuery;
    if (query.isEmpty) return [];
    return widget.users.where((u) {
      if (u.username == widget.currentUser.username) return false;
      if (u.username == effectiveUser.username) return false;
      return u.name.toLowerCase().contains(query.toLowerCase()) ||
          u.username.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Song':
        return Icons.music_note;
      case 'Video':
      case 'Reel':
      case 'Reels':
        return Icons.videocam;
      case 'Image':
        return Icons.image;
      default:
        return Icons.menu_book;
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickCoverImage() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
          child: Wrap(children: [
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.tr.gallery),
                onTap: () {
                  Navigator.of(context).pop();
                  _processImage(ImageSource.gallery);
                }),
            ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(context.tr.camera),
                onTap: () {
                  Navigator.of(context).pop();
                  _processImage(ImageSource.camera);
                }),
          ])),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final String fileName =
            'cover_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
        final appDir = await getApplicationDocumentsDirectory();
        final uploadsDir = Directory(p.join(appDir.path, "uploads"));
        if (!await uploadsDir.exists())
          await uploadsDir.create(recursive: true);
        final String permanentPath = p.join(uploadsDir.path, fileName);
        await File(image.path).copy(permanentPath);
        final updatedUser = effectiveUser.copyWith(coverImage: permanentPath);
        if (mounted) setState(() => _localUserOverride = updatedUser);
        widget.onUpdateProfile?.call(updatedUser);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickAvatarImage() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
          child: Wrap(children: [
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.tr.gallery),
                onTap: () {
                  Navigator.of(context).pop();
                  _processAvatarImage(ImageSource.gallery);
                }),
            ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(context.tr.camera),
                onTap: () {
                  Navigator.of(context).pop();
                  _processAvatarImage(ImageSource.camera);
                }),
          ])),
    );
  }

  Future<void> _processAvatarImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final String fileName =
            'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
        final appDir = await getApplicationDocumentsDirectory();
        final uploadsDir = Directory(p.join(appDir.path, "uploads"));
        if (!await uploadsDir.exists())
          await uploadsDir.create(recursive: true);
        final String permanentPath = p.join(uploadsDir.path, fileName);
        await File(image.path).copy(permanentPath);
        final updatedUser = effectiveUser.copyWith(avatar: permanentPath);
        if (mounted) setState(() => _localUserOverride = updatedUser);
        widget.onUpdateProfile?.call(updatedUser);
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
    }
  }

  int _getCommentCount(Map<String, dynamic> post) {
    final count = post['commentsCount'] ?? post['comments_count'];
    if (count != null) {
      if (count is num) return count.toInt();
      if (count is String) return int.tryParse(count) ?? 0;
    }
    final list = post['comments'] as List?;
    if (list == null || list.isEmpty) return 0;
    int total = 0;
    void walk(List items) {
      for (var c in items) {
        total++;
        if (c is Map && c['replies'] is List) walk(c['replies'] as List);
      }
    }
    walk(list);
    return total;
  }

  void _openCommentsSheet(Map<String, dynamic> post) async {
    if (post['comments'] == null) post['comments'] = [];

    final savedOffset =
    _scrollController.hasClients ? _scrollController.offset : 0.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => CommentsBottomSheet(
          post: post,
          currentUser: effectiveUser,
          onPostAction: widget.onPostAction,
          allUsers: widget.users,
          scrollController: controller,
        ),
      ),
    );

    final idx = _posts.indexWhere((p) => p['id'] == post['id']);
    if (idx != -1 && mounted) {
      setState(() {
        _posts[idx]['commentsCount'] = post['commentsCount'];
        _posts[idx]['comments'] = post['comments'];
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scrollController.hasClients &&
          savedOffset > 0 &&
          savedOffset <= _scrollController.position.maxScrollExtent) {
        _scrollController.jumpTo(savedOffset);
      }
    });

    await _loadPostsFromApi();
  }

  // ── EXTRACTED like handler (used by both grid overlay and feed card) ──────
  Future<void> _handleFeedLike(Map<String, dynamic> post) async {
    final key = post['id']?.toString() ?? '';
    if (key.isEmpty) return;
    final wasLiked = _likedPostIds.contains(key);
    final postIndex = _posts.indexWhere((p) => p['id'].toString() == key);

    setState(() {
      if (wasLiked) {
        _likedPostIds.remove(key);
        if (postIndex != -1) {
          final current = (_posts[postIndex]['likeCount'] ?? 1) as num;
          _posts[postIndex]['likeCount'] =
              (current - 1).clamp(0, double.infinity).toInt();
          post['likeCount'] = _posts[postIndex]['likeCount'];
        }
      } else {
        _likedPostIds.add(key);
        if (postIndex != -1) {
          final current = (_posts[postIndex]['likeCount'] ?? 0) as num;
          _posts[postIndex]['likeCount'] = current.toInt() + 1;
          post['likeCount'] = _posts[postIndex]['likeCount'];
        }
      }
    });

    final pid = post['id'] is int
        ? post['id'] as int
        : int.tryParse(post['id'].toString());
    if (pid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;
      final dio = Dio();
      dio.options.baseUrl = 'https://openzippers.com/api/v1/';
      dio.options.headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await dio.post(
        'zippfans/likes/post',
        data: {'post_id': pid},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      debugPrint('LIKE RESPONSE ${response.statusCode}: ${response.data}');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'];
        if (data is Map && mounted) {
          setState(() {
            final isLiked = data['is_liked'] == true;
            isLiked ? _likedPostIds.add(key) : _likedPostIds.remove(key);
            if (postIndex != -1 && data['likes_count'] != null) {
              _posts[postIndex]['likeCount'] = data['likes_count'];
              post['likeCount'] = data['likes_count'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Like API error: $e');
      setState(() =>
      wasLiked ? _likedPostIds.add(key) : _likedPostIds.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentlyBlocked = _isBlockedOverride ?? (effectiveUser.type == 'blocked');
    if (isCurrentlyBlocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text(effectiveUser.username),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: widget.onBack != null
              ? IconButton(
              icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
              onPressed: widget.onBack)
              : null,
        ),
        body: Column(children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundImage: effectiveUser.avatar.startsWith('http')
                ? NetworkImage(effectiveUser.avatar)
                : FileImage(File(effectiveUser.avatar)) as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(effectiveUser.name,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text("@${effectiveUser.username}",
              style: TextStyle(color: theme.hintColor)),
          const SizedBox(height: 40),
          Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 64, color: theme.dividerColor),
                    const SizedBox(height: 16),
                    Text(context.tr.youHaveBlockedUser,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color)),
                    const SizedBox(height: 8),
                    Text(context.tr.unblockToSeePosts,
                        style: TextStyle(color: theme.hintColor)),
                    const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final userId = effectiveUser.id;
                  if (userId == null) {
                    widget.onUserAction?.call(effectiveUser, 'Unblock');
                    setState(() => _isBlockedOverride = false);
                    return;
                  }
                  try {
                    final res = await ref
                        .read(blockProvider.notifier)
                        .toggleBlock(userId);
                    if (res != null && mounted) {
                      setState(() => _isBlockedOverride = res.data.isBlocked);
                      widget.onUserAction?.call(
                        effectiveUser,
                        res.data.isBlocked ? 'Block' : 'Unblock',
                      );
                      ref.invalidate(connectionsProvider(widget.currentUser.username));
                      ref.invalidate(connectionsProvider(effectiveUser.username));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(res.message)));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(context.tr.unblockBtn),
              ),
                  ])),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final isWideScreen = constraints.maxWidth > 900;
          return Column(children: [
            Container(
              height: 10,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                    bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.5))),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                          onPressed: widget.onBack,
                          icon: Icon(Icons.arrow_back,
                              color: theme.iconTheme.color, size: 24))
                    else
                      const SizedBox(width: 48),
                    const Expanded(child: SizedBox.shrink()),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (isMe && widget.onSettingsTap != null)
                        IconButton(
                            icon: const Icon(Icons.settings,
                                color: Color(0xFFDB2777), size: 22),
                            onPressed: widget.onSettingsTap),
                      const SizedBox(width: 40),
                      if (!isMe)
                        Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF475569)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'block') {
                                final userId = effectiveUser.id;
                                if (userId == null) {
                                  widget.onUserAction
                                      ?.call(effectiveUser, 'Block');
                                  return;
                                }
                                setState(() => _isBlockLoading = true);
                                try {
                                  final res = await ref
                                      .read(blockProvider.notifier)
                                      .toggleBlock(userId);
                                  if (res != null && mounted) {
                                    setState(() => _isBlockedOverride =
                                        res.data.isBlocked);
                                    widget.onUserAction?.call(
                                        effectiveUser,
                                        res.data.isBlocked
                                            ? 'Block'
                                            : 'Unblock');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(res.message)));
                                  }
                                } catch (e) {
                                  if (mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('Error: $e')));
                                } finally {
                                  if (mounted)
                                    setState(() => _isBlockLoading = false);
                                }
                              }
                            },
                            icon: Icon(Icons.more_vert,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                size: 24),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'block',
                                  child: Row(children: [
                                    const Icon(Icons.block,
                                        size: 18,
                                        color: Color(0xFFDB2777)),
                                    const SizedBox(width: 12),
                                    Text(context.tr.block,
                                        style: const TextStyle(
                                            color: Color(0xFFDB2777),
                                            fontWeight: FontWeight.bold)),
                                  ])),
                            ],
                          ),
                        ),
                    ]),
                  ]),
            ),
            _buildFixedHeader(theme, isSmallScreen),
            Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey('profile_scroll'),
                controller: _scrollController,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 1000 : double.infinity),
                    child: Column(children: [
                      _buildProfileInfo(theme, isSmallScreen),
                      if (isMe) _buildSearchBar(theme),
                      if (_filteredUsers.isNotEmpty)
                        _buildUserSearchResults(theme),
                      const SizedBox(height: 10),
                      _buildBioDetails(theme),
                      const SizedBox(height: 10),
                      _buildTabs(theme),
                      _buildPostsGrid(theme),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildFixedHeader(ThemeData theme, bool isSmallScreen) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomLeft,
            children: [
              GestureDetector(
                onTap: isMe
                    ? () => setState(() => _showCoverMenu = !_showCoverMenu)
                    : null,
                child: Container(
                  height: isSmallScreen ? 160 : 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: DecorationImage(
                      image: (() {
                        if (effectiveUser.coverImage.isEmpty) {
                          return NetworkImage(
                              'https://picsum.photos/seed/${effectiveUser.username}/800/200');
                        }
                        final path = effectiveUser.coverImage;
                        return path.startsWith('http')
                            ? NetworkImage(path)
                            : FileImage(File(path)) as ImageProvider;
                      })(),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: isMe && _showCoverMenu
                      ? Center(
                      child: GestureDetector(
                        onTap: _pickCoverImage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration:
                          const BoxDecoration(shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: Color(0xFFDB2777), size: 32),
                        ),
                      ))
                      : const SizedBox.shrink(),
                ),
              ),
              if (isMe && widget.onSettingsTap != null)
                Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.settings,
                          color: Color(0xFFDB2777), size: 22),
                      onPressed: widget.onSettingsTap,
                    )),
              Positioned(
                bottom: isSmallScreen ? -35 : -50,
                left: isSmallScreen ? 16 : 24,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFFDB2777), Color(0xFFF97316)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.scaffoldBackgroundColor, width: 4)),
                    child: GestureDetector(
                      onTap: isMe
                          ? () => setState(
                              () => _showAvatarMenu = !_showAvatarMenu)
                          : null,
                      child: Stack(alignment: Alignment.center, children: [
                        CircleAvatar(
                          radius: isSmallScreen ? 40 : 60,
                          backgroundColor: Colors.grey[800],
                          foregroundImage:
                          _getAvatarImage(effectiveUser.avatar),
                          child: Icon(Icons.person,
                              size: isSmallScreen ? 40 : 60,
                              color: Colors.white),
                        ),
                        if (isMe && _showAvatarMenu)
                          GestureDetector(
                            onTap: _pickAvatarImage,
                            child: Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.camera_alt,
                                  color: Color(0xFFDB2777), size: 28),
                            ),
                          ),
                        if (effectiveUser.isVerified)
                          Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.check_circle,
                                    color: Color(0xFF60A5FA), size: 18),
                              )),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
        SizedBox(height: isSmallScreen ? 45 : 60),
      ]),
    );
  }

  Widget _buildProfileInfo(ThemeData theme, bool isSmallScreen) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding:
        EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(effectiveUser.username,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color)),
                if (effectiveUser.isEmailVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Colors.blue, size: 20),
                ],
              ]),
              Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (effectiveUser.isArtist)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_pin_circle_outlined,
                            size: 14, color: Color(0xFFDB2777)),
                        const SizedBox(width: 4),
                        Text(context.tr.artist,
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 13)),
                      ]),
                    AnimatedBuilder(
                      animation: _viewModel,
                      builder: (context, _) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF334155)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (_viewModel.isLoading)
                            const SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Color(0xFF94A3B8)))
                          else
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _viewModel.isOnline
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                )),
                          const SizedBox(width: 6),
                          Text(
                            _viewModel.isLoading
                                ? '...'
                                : (_viewModel.isOnline
                                ? context.tr.online
                                : context.tr.offline),
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w500),
                          ),
                        ]),
                      ),
                    ),
                    if (!isMe && !effectiveUser.isSubscribed)
                      ElevatedButton(
                        onPressed: _isFollowLoading
                            ? null
                            : () async {
                          final userId = effectiveUser.id;
                          if (userId == null) return;
                          final wasFollowing = isFollowing;
                          setState(() => _isFollowLoading = true);
                          try {
                            final res = await ref
                                .read(followProvider.notifier)
                                .toggleFollow(userId);
                            if (res != null && mounted) {
                              setState(() {
                                _isFollowingOverride = !wasFollowing;
                                final current =
                                    int.tryParse(_followerCount) ?? 0;
                                _followerCount = !wasFollowing
                                    ? (current + 1).toString()
                                    : (current - 1)
                                    .clamp(0, 999999)
                                    .toString();
                              });
                              widget.onUserAction?.call(
                                effectiveUser,
                                !wasFollowing ? 'Follow' : 'Unfollow',
                              );
                              ref.invalidate(connectionsProvider(
                                  widget.currentUser.username));
                              ref.invalidate(connectionsProvider(
                                  effectiveUser.username));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(!wasFollowing
                                    ? 'Followed successfully'
                                    : 'Unfollowed successfully'),
                              ));
                            }
                          } catch (e) {
                            debugPrint('Profile follow error: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e')));
                            }
                          } finally {
                            if (mounted)
                              setState(() => _isFollowLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowLoading
                              ? Colors.grey.shade700
                              : isFollowing
                              ? (theme.brightness == Brightness.dark
                              ? const Color(0xFF334155)
                              : Colors.grey[200])
                              : const Color(0xFFDB2777),
                          foregroundColor: isFollowing
                              ? (theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87)
                              : Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isFollowLoading
                            ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : Text(
                            isFollowing
                                ? context.tr.following
                                : context.tr.follow,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.share_outlined,
                          size: 18, color: theme.hintColor),
                      onPressed: () {
                        Share.share(
                          context.tr.shareProfileText(effectiveUser.name,
                              'https://openzippers.fans/${effectiveUser.username}'),
                          subject: context.tr.shareProfileSubject,
                        );
                      },
                    ),
                  ]),
            ]),
      ),
      const SizedBox(height: 30),
      Padding(
        padding:
        EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 24),
        child: Row(children: [
          Expanded(
              child: _buildStatCard(
                  theme,
                  Icons.person_outline,
                  _followerCount,
                  context.tr.followers.toUpperCase(),
                  const Color(0xFFDB2777),
                  isSmallScreen)),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
              child: _buildStatCard(
                  theme,
                  Icons.group_outlined,
                  _followingCount,
                  context.tr.following.toUpperCase(),
                  const Color(0xFF3B82F6),
                  isSmallScreen)),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: _buildStatCard(
              theme,
              Icons.card_giftcard_outlined,
              ref.watch(activeSubscriberCountProvider).toString(), // ← LIVE COUNT
              context.tr.subscribers.toUpperCase(),
              const Color(0xFFA855F7),
              isSmallScreen,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SubscriptionsPage(
                    currentUser: widget.currentUser,
                  ),
                ));
              },
            ),
          ),

        ]),
      ),
      if (isMe) ...[
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: UnconstrainedBox(
              child: ElevatedButton.icon(
                onPressed: () {
                  final user = _localUserOverride ?? effectiveUser;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            currentUser: user,
                            onSave: (updatedUser) {
                              setState(
                                      () => _localUserOverride = updatedUser);
                              widget.onUpdateProfile?.call(updatedUser);
                              Navigator.pop(context);
                            },
                            onBack: () => Navigator.pop(context),
                            initialCountryId: user.countryId,
                            initialStateId: user.stateId,
                            initialCityId: user.cityId,
                          )));
                },
                icon: Icon(Icons.edit_outlined,
                    size: 16,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87),
                label: Text(context.tr.editProfile,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark
                      ? const Color(0xFF475569)
                      : Colors.grey[200],
                  foregroundColor: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ),
      ],
      if (!isMe) ...[
        const SizedBox(height: 20),
        if (effectiveUser.isArtist)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    if (widget.onUserAction != null) {
                      await widget.onUserAction!(effectiveUser,
                          effectiveUser.isSubscribed ? 'Unsubscribe' : 'Subscribe');
                      await _refreshUserData();
                    }
                  },
                  icon: Icon(
                      effectiveUser.isSubscribed
                          ? Icons.check_circle
                          : Icons.card_membership,
                      size: 18),
                  label: Text(
                      effectiveUser.isSubscribed
                          ? context.tr.subscribed
                          : context.tr.subscribePrice(
                          '${context.tr.currencySymbol}12.00'),
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: effectiveUser.isSubscribed
                        ? Colors.grey[700]
                        : const Color(0xFFDB2777),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton.icon(
              onPressed: _isBlockLoading
                  ? null
                  : () async {
                setState(() => _isBlockLoading = true);
                try {
                  final userId = effectiveUser.id;
                  if (userId == null) return;
                  final res = await ref
                      .read(blockProvider.notifier)
                      .toggleBlock(userId);
                  if (res != null && mounted) {
                    setState(
                            () => _isBlockedOverride = res.data.isBlocked);
                    widget.onUserAction?.call(
                      effectiveUser,
                      res.data.isBlocked ? 'Block' : 'Unblock',
                    );
                    ref.invalidate(connectionsProvider(
                        widget.currentUser.username));
                    ref.invalidate(
                        connectionsProvider(effectiveUser.username));
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res.message)));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _isBlockLoading = false);
                }
              },
              icon: _isBlockLoading
                  ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : Icon(
                  _isBlockedOverride ?? false
                      ? Icons.lock_open
                      : Icons.block,
                  size: 16),
              label: Text(
                  _isBlockedOverride ?? false ? 'Unblock' : 'Block',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isBlockedOverride ?? false
                    ? Colors.grey.shade600
                    : const Color(0xFFFF2D2D),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
        ),
        if (effectiveUser.isArtist &&
            !isFollowing &&
            !effectiveUser.isSubscribed) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              color: const Color(0xFFDB2777).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () async {
                  if (widget.onUserAction != null) {
                    await widget.onUserAction!(effectiveUser, 'Follow');
                    await _refreshUserData();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                          const Color(0xFFDB2777).withOpacity(0.2))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_alt_1,
                            size: 16,
                            color: Theme.of(context).brightness ==
                                Brightness.dark
                                ? Colors.white70
                                : const Color(0xFFDB2777)),
                        const SizedBox(width: 8),
                        Text(context.tr.followArtistToUnlock,
                            style: TextStyle(
                                color: Theme.of(context).brightness ==
                                    Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : const Color(0xFFDB2777),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ]),
                ),
              ),
            ),
          ),
        ],
      ],
    ]);
  }

  Widget _buildStatCard(ThemeData theme, IconData icon, String count,
      String label, Color color, bool isSmallScreen,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 16 : 24, horizontal: 4),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                color.withOpacity(
                    theme.brightness == Brightness.dark ? 0.1 : 0.05),
              ]),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]),
            child: Icon(icon,
                color: Colors.white, size: isSmallScreen ? 18 : 24),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(count,
              style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 32,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87)),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 10,
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: isSmallScreen ? 0.2 : 1.2)),
        ]),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    if (!isMe) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(children: []),
    );
  }

  Widget _buildBioDetails(ThemeData theme) {
    final months = [
      context.tr.monthFullJan, context.tr.monthFullFeb,
      context.tr.monthFullMar, context.tr.monthFullApr,
      context.tr.monthFullMay, context.tr.monthFullJun,
      context.tr.monthFullJul, context.tr.monthFullAug,
      context.tr.monthFullSep, context.tr.monthFullOct,
      context.tr.monthFullNov, context.tr.monthFullDec
    ];
    final dateStr =
        "${months[effectiveUser.joinedDate.month - 1]} ${effectiveUser.joinedDate.year}";
    final joined = context.tr.joined(dateStr);
    String localizedGender = effectiveUser.gender;
    if (effectiveUser.gender == "Male")
      localizedGender = context.tr.genderMale;
    else if (effectiveUser.gender == "Female")
      localizedGender = context.tr.genderFemale;
    else if (effectiveUser.gender == "Other")
      localizedGender = context.tr.genderOther;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF475569).withOpacity(0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  effectiveUser.bio.isEmpty
                      ? context.tr.welcomeProfile
                      : effectiveUser.bio,
                  style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14)),
              const SizedBox(height: 20),
              Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _buildBioItem(theme, Icons.calendar_today_outlined, joined),
                    _buildBioItem(theme, Icons.person_outline, localizedGender),
                    if (effectiveUser.city.isNotEmpty ||
                        effectiveUser.state.isNotEmpty ||
                        effectiveUser.country.isNotEmpty)
                      _buildBioItem(
                          theme,
                          Icons.location_on_outlined,
                          [
                            if (effectiveUser.city.isNotEmpty)
                              effectiveUser.city,
                            if (effectiveUser.state.isNotEmpty)
                              effectiveUser.state,
                            if (effectiveUser.country.isNotEmpty)
                              effectiveUser.country,
                          ].join(", ")),
                  ]),
            ]),
      ),
    );
  }

  Widget _buildBioItem(ThemeData theme, IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: theme.hintColor),
      const SizedBox(width: 6),
      Text(text,
          style: TextStyle(
              color: theme.hintColor,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildUserSearchResults(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(context.tr.peopleCount(_filteredUsers.length),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold))),
        ..._filteredUsers.take(10).map((user) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.dividerColor.withOpacity(0.5))),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(
                  radius: 20,
                  backgroundImage: user.avatar.startsWith('http')
                      ? NetworkImage(user.avatar)
                      : FileImage(File(user.avatar)) as ImageProvider,
                  backgroundColor: theme.dividerColor),
              if (user.isEmailVerified)
                Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.verified,
                            color: Color(0xFFDB2777), size: 10))),
            ]),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(user.username,
                          style: TextStyle(
                              color: theme.hintColor, fontSize: 11)),
                    ])),
            const SizedBox(width: 12),
            _buildSearchResultAction(theme, user),
          ]),
        )),
        if (_filteredUsers.length > 10)
          Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                  "+ ${_filteredUsers.length - 5} ${context.tr.more}",
                  style:
                  TextStyle(color: theme.hintColor, fontSize: 12))),
        const SizedBox(height: 15),
      ]),
    );
  }

  Widget _buildSearchResultAction(ThemeData theme, MockUser user) {
    if (user.username == effectiveUser.username || user.isSubscribed)
      return const SizedBox.shrink();
    final isFollowing = user.type == 'following';
    return ElevatedButton(
      onPressed: () {
        widget.onUserAction
            ?.call(user, isFollowing ? 'Unfollow' : 'Follow');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
        isFollowing ? theme.dividerColor : const Color(0xFFDB2777),
        foregroundColor: isFollowing
            ? theme.textTheme.bodyMedium?.color
            : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 30),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(isFollowing ? context.tr.following : context.tr.follow,
          style:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ── TABS with view toggle button ────────────────────────────────────────
  Widget _buildTabs(ThemeData theme) {
    final tabs = [
      {
        'icon': Icons.grid_view,
        'activeIcon': Icons.grid_view,
        'label': context.tr.all,
        'count': _posts.where(_postHasDisplayableImage).length.toString()
      },
      {
        'icon': Icons.image_outlined,
        'activeIcon': Icons.image,
        'label': context.tr.image,
        'count': _posts
            .where((p) =>
        p['type'] == 'Image' && _postHasDisplayableImage(p))
            .length
            .toString()
      },
      {
        'icon': Icons.music_note_outlined,
        'activeIcon': Icons.music_note,
        'label': context.tr.song,
        'count':
        _posts.where((p) => p['type'] == 'Song').length.toString()
      },
      {
        'icon': Icons.videocam_outlined,
        'activeIcon': Icons.videocam,
        'label': context.tr.video,
        'count': _posts
            .where((p) =>
        p['type'] == 'Video' ||
            p['type'] == 'Reel' ||
            p['type'] == 'Reels')
            .length
            .toString()
      },
      {
        'icon': Icons.import_contacts,
        'activeIcon': Icons.menu_book,
        'label': context.tr.literature,
        'count': _posts
            .where((p) => p['type'] == 'Literature')
            .length
            .toString()
      },
      {
        'icon': Icons.photo_album_outlined,
        'activeIcon': Icons.photo_album,
        'label': context.tr.albums,
        'count': _albums.length.toString()
      },
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;
                final item = tabs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Material(
                    color: Colors.transparent,
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedTabIndex = index),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(
                                              isSelected
                                                  ? (item['activeIcon']
                                              as IconData)
                                                  : (item['icon']
                                              as IconData),
                                              color: isSelected
                                                  ? const Color(0xFFDB2777)
                                                  : Theme.of(context)
                                                  .hintColor,
                                              size: 24),
                                          if (int.parse(
                                              item['count'] as String) >
                                              0)
                                            Positioned(
                                                right: -6,
                                                top: -4,
                                                child: Container(
                                                  padding:
                                                  const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? const Color(
                                                          0xFFDB2777)
                                                          : Theme.of(context)
                                                          .dividerColor,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color:
                                                          Theme.of(context)
                                                              .cardColor,
                                                          width: 1.5)),
                                                  constraints:
                                                  const BoxConstraints(
                                                      minWidth: 18,
                                                      minHeight: 18),
                                                  child: Center(
                                                      child: Text(
                                                          item['count']
                                                          as String,
                                                          style: TextStyle(
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : Theme.of(
                                                                  context)
                                                                  .hintColor,
                                                              fontSize: 9,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold))),
                                                )),
                                        ]),
                                    const SizedBox(width: 8),
                                    Text(item['label'] as String,
                                        style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFFDB2777)
                                                : Theme.of(context).hintColor,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 15)),
                                  ]),
                              const SizedBox(height: 6),
                              Container(
                                  height: 3,
                                  width: 40,
                                  decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFDB2777)
                                          : Colors.transparent,
                                      borderRadius:
                                      BorderRadius.circular(2))),
                            ]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // ── Grid / List toggle ───────────────────────────────────
          if (_selectedTabIndex != 5)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _isListView = !_isListView),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isListView
                        ? _kPink.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isListView ? _kPink : theme.dividerColor,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    _isListView
                        ? Icons.grid_view
                        : Icons.view_agenda_outlined,
                    color: _isListView ? _kPink : theme.hintColor,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(ThemeData theme) {
    if (_selectedTabIndex == 5) {
      final bool isFollowingUser = effectiveUser.type == 'following' ||
          effectiveUser.type == 'friend' ||
          effectiveUser.type == 'subscribed' ||
          effectiveUser.type == 'mutual';
      if (!isMe && !isFollowingUser)
        return _buildHiddenAlbumsPlaceholder(theme);
      return AlbumsView(
        currentUser: widget.currentUser,
        albums: _albums,
        isOwner: isMe,
        isScrollable: false,
        onCreateAlbum: () => _showCreateAlbumDialog(),
        onDeleteAlbum: (album) => _deleteAlbum(album),
        onEditAlbum: (album) => _showCreateAlbumDialog(existingAlbum: album),
        onViewAlbum: (album) {
          final isPrivate =
              album['isPrivate'] == 1 || album['isPrivate'] == true;
          final hasPrice = album['price'] != null &&
              album['price'].toString() != '0' &&
              album['price'].toString().toLowerCase() != 'free';
          if (isMe) {
            widget.onNavigateToAlbum != null
                ? widget.onNavigateToAlbum!(album)
                : AlbumPlayerDialog.show(context, album, allAlbums: _albums);
          } else if (isPrivate) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("This album is private."),
                backgroundColor: Colors.red));
          } else if (hasPrice && !effectiveUser.isSubscribed) {
            showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Unlock Album"),
                  content: Text(
                      "This album requires a subscription or purchase.\nPrice: ${album['price']}"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(context.tr.cancel)),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _addAlbumToCart(album);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDB2777)),
                        child: const Text("Add to Cart")),
                  ],
                ));
          } else {
            AlbumPlayerDialog.show(context, album, allAlbums: _albums);
          }
        },
        onShowDetails: (album) => _showAlbumDetailsDialog(album),
        showCreateButton: false,
        fromProfile: true,
        onAddToCart: _addAlbumToCart,
      );
    }
    return _buildPostsGridInternal(theme);
  }

  Widget _buildHiddenAlbumsPlaceholder(ThemeData theme) {
    return Container(
      padding:
      const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.grey[100],
                    shape: BoxShape.circle),
                child: const Icon(Icons.visibility_off_outlined,
                    color: Color(0xFFDB2777), size: 48)),
            const SizedBox(height: 24),
            Text(context.tr.hidden,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(context.tr.followToSeeContent,
                style: TextStyle(color: theme.hintColor, fontSize: 14),
                textAlign: TextAlign.center),
          ])),
    );
  }

  Widget _buildPostsGridInternal(ThemeData theme) {
    final bool isFollowingUser = effectiveUser.type == 'following' ||
        effectiveUser.type == 'friend' ||
        effectiveUser.type == 'subscribed' ||
        effectiveUser.type == 'mutual';
    final bool isContentHidden = !isMe && !isFollowingUser;
    final posts = _filteredPosts;

    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(50),
        child: Column(children: [
          Icon(Icons.folder_open_outlined,
              size: 60, color: theme.dividerColor),
          const SizedBox(height: 16),
          Text(context.tr.noPostsFoundCategory,
              style: TextStyle(color: theme.hintColor)),
        ]),
      );
    }

    // ── LIST / FEED VIEW ─────────────────────────────────────────
    if (_isListView) {
      return ListView.separated(
        key: PageStorageKey('profile_list_$_selectedTabIndex'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildFeedCard(theme, posts[index], isContentHidden),
      );
    }

    // ── GRID VIEW ────────────────────────────────────────────────
    return GridView.builder(
      key: PageStorageKey('profile_grid_$_selectedTabIndex'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.68),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final rawPostId = post['id'];
        final int postId = rawPostId is int
            ? rawPostId
            : int.tryParse(rawPostId?.toString() ?? '') ?? 0;
        final ratingAsync = ref.watch(ratingProvider(postId));
        if (isContentHidden) {
          return Container(
            decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF0F172A)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.dividerColor.withOpacity(0.1))),
            child: Stack(children: [
              Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildFilteredText(
                        context.tr.hidden,
                        const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(context.tr.followToSeeContent,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
                  ])),
              Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['title'] ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                        Text(_localizeType(post['type'] ?? ''),
                            style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black54,
                                fontSize: 10)),
                      ])),
              Positioned(
                  top: 6,
                  left: 6,
                  child: const Icon(Icons.info_outline,
                      color: Color(0xFFDB2777), size: 14)),
            ]),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Builder(
                builder: (_) {
                  final imageUrl =
                      post['imageUrl']?.toString() ?? '';
                  if (imageUrl.isEmpty) {
                    return Container(
                      color: Colors.black12,
                      child: const Center(
                          child: Icon(Icons.music_note,
                              color: Colors.white54)),
                    );
                  }
                  return Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.black12,
                        child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black12,
                        child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.white54)),
                      );
                    },
                  );
                },
              ),
              if (!_isUnlocked(post))
                Container(color: Colors.black.withOpacity(0.5)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                  const EdgeInsets.fromLTRB(8, 20, 8, 8),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85)
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => _handleFeedLike(post),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _likedPostIds.contains(
                                  post['id']?.toString() ?? '')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.pink,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                "${post['likeCount'] ?? 0}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openCommentsSheet(post),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                "${_getCommentCount(post)}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final pid = post['id'] is int
                              ? post['id']
                              : int.tryParse(
                              post['id'].toString()) ??
                              0;
                          final ra =
                          ref.watch(ratingProvider(pid));
                          return ra.when(
                            data: (RatingResponse ratingResponse) {
                              final ratingData =
                                  ratingResponse.data;
                              final userRating =
                                  ratingData.userRating;
                              final avg =
                                  ratingData.averageRating;
                              return GestureDetector(
                                onTap: () =>
                                    _showRatingDialog(post),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (userRating != null &&
                                          (userRating as num)
                                              .toInt() >
                                              0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        avg.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 10,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                        overflow:
                                        TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox(
                                width: 20, height: 14),
                            error: (_, __) => const Icon(
                                Icons.star_border,
                                color: Colors.amber,
                                size: 14),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showPostDetails(context, post),
                  child: Container(),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => _showInfoDialog(post),
                  child: const Icon(Icons.info_outline,
                      color: Color(0xFFDB2777), size: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── FEED CARD (list view) ────────────────────────────────────────────────
  Widget _buildFeedCard(ThemeData theme, Map<String, dynamic> post,
      bool isContentHidden) {
    final key = post['id']?.toString() ?? '';
    final isLiked = _likedPostIds.contains(key);
    final commentCount = _getCommentCount(post);
    final isFree = _isFree(post['price']);
    final isUnlocked = _isUnlocked(post);
    final type = (post['type'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha:
                theme.brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + type + menu
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                  _getAvatarImage(effectiveUser.avatar),
                  backgroundColor: Colors.grey[800],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveUser.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      Row(
                        children: [
                          Icon(_getIconForType(type),
                              size: 11, color: _kPink),
                          const SizedBox(width: 3),
                          Text(
                            _localizeType(type),
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor),
                          ),
                          if (!isFree) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                _kPink.withValues(alpha: 0.12),
                                borderRadius:
                                BorderRadius.circular(4),
                              ),
                              child: Text(
                                post['price']?.toString() ?? '',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: _kPink,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isMe)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz,
                        color: theme.hintColor, size: 20),
                    onSelected: (v) {
                      if (v == 'edit') widget.onPostAction(post, 'edit');
                      if (v == 'delete')
                        widget.onPostDeleted != null
                            ? widget.onPostDeleted!(post)
                            : widget.onPostAction(post, 'Delete');
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(context.tr.editPost),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(context.tr.deletePost,
                              style:
                              const TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Title
          if ((post['title'] ?? '').toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Text(
                post['title'],
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Media
          if (isContentHidden)
            _buildFeedLockedPlaceholder(theme)
          else if (!isUnlocked)
            _buildFeedSubscribeBanner()
          else
            _buildFeedMedia(theme, post),

          // Caption
          if (!isContentHidden &&
              (post['content'] ?? '').toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _buildFilteredText(
                post['content'],
                TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.4),
                maxLines: 3,
              ),
            ),

          // Action bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Row(
              children: [
                // Like
                _buildFeedActionBtn(
                  icon: isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: isLiked ? _kPink : theme.hintColor,
                  label: '${post['likeCount'] ?? 0}',
                  onTap: () => _handleFeedLike(post),
                ),
                const SizedBox(width: 4),
                // Comment
                _buildFeedActionBtn(
                  icon: Icons.chat_bubble_outline,
                  color: theme.hintColor,
                  label: '$commentCount',
                  onTap: () => _openCommentsSheet(post),
                ),
                const SizedBox(width: 4),
                // Rating
                Builder(builder: (context) {
                  final int pid = post['id'] is int
                      ? post['id']
                      : int.tryParse(post['id'].toString()) ?? 0;
                  final ra = ref.watch(ratingProvider(pid));
                  return ra.when(
                    data: (r) => _buildFeedActionBtn(
                      icon: (r.data.userRating ?? 0) > 0
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      label:
                      r.data.averageRating.toStringAsFixed(1),
                      onTap: () => _showRatingDialog(post),
                    ),
                    loading: () => const SizedBox(width: 36),
                    error: (_, __) => _buildFeedActionBtn(
                      icon: Icons.star_border,
                      color: Colors.amber,
                      label: '0.0',
                      onTap: () => _showRatingDialog(post),
                    ),
                  );
                }),
                const Spacer(),
                // Info
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                  icon: const Icon(Icons.info_outline,
                      color: _kPink),
                  onPressed: () => _showInfoDialog(post),
                ),
                const SizedBox(width: 8),
                // Share
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                  icon: Icon(Icons.share_outlined,
                      color: theme.hintColor),
                  onPressed: () =>
                      Share.share(post['title'] ?? ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedActionBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color:
                  Theme.of(context).textTheme.bodyMedium?.color)),
        ]),
      ),
    );
  }

  Widget _buildFeedMedia(ThemeData theme, Map<String, dynamic> post) {
    final type = (post['type'] ?? '').toString();
    final imageUrl = post['imageUrl']?.toString() ?? '';

    if (type == 'Song') {
      return Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: AudioPlayerWidget(
          audioPath: post['filePath'] ?? '',
          coverPath: imageUrl,
        ),
      );
    }

    if (type == 'Literature') {
      return GestureDetector(
        onTap: () => _showPostDetails(context, post),
        child: Container(
          height: 180,
          margin: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Center(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book,
                      size: 42,
                      color: _kPink.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text(context.tr.literature,
                      style: TextStyle(
                          color: theme.hintColor, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Tap to read',
                      style: TextStyle(
                          color: _kPink,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ]),
          ),
        ),
      );
    }

    if (type == 'Video' || type == 'Reel' || type == 'Reels') {
      return SizedBox(
        height: 240,
        child: VideoPlayerWidget(
          videoPath: post['filePath'] ?? '',
          coverPath: post['coverPath'],
          autoPlay: false,
          showPlayButton: true,
          showEnlargeButton: false,
          onPlayStateChanged: (playing) {
            if (mounted) setState(() => _isVideoPlaying = playing);
          },
        ),
      );
    }

    // Image
    if (imageUrl.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _showPostDetails(context, post),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 180,
            color: theme.dividerColor.withValues(alpha: 0.3),
            child: Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 40, color: theme.hintColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedLockedPlaceholder(ThemeData theme) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.visibility_off_outlined,
              color: theme.hintColor, size: 32),
          const SizedBox(height: 6),
          Text(context.tr.followToSeeContent,
              style:
              TextStyle(color: theme.hintColor, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildFeedSubscribeBanner() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            if (widget.onUserAction != null) {
              await widget.onUserAction!(effectiveUser, 'Subscribe');
              await _refreshUserData();
            }
          },
          icon: const Icon(Icons.lock_outline, size: 16),
          label: const Text('Subscribe to Unlock'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  // ── Existing helpers below (unchanged) ──────────────────────────────────

  void _prefillRatings(List<Map<String, dynamic>> posts) {
    selectedRatings.clear();
    for (final post in posts) {
      final postId = post['id'];
      final rating =
          post['my_rating'] ?? post['user_rating'] ?? post['rating'];
      if (postId != null && rating != null) {
        selectedRatings[postId] =
            int.tryParse(rating.toString()) ?? 0;
      }
    }
    if (mounted) setState(() {});
  }

  void _showPostDetails(
      BuildContext context, Map<String, dynamic> initialPost) {
    _refreshUserData();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          StatefulBuilder(builder: (context, setModalState) {
            final latestPost = widget.posts.firstWhere(
                    (p) => p['id'] == initialPost['id'],
                orElse: () => initialPost);
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) => Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20))),
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(context.tr.contentDetails,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 14),
                      _buildPostDetailCard(latestPost,
                          scrollController: controller,
                          setModalState: setModalState),
                    ]),
              ),
            );
          }),
    );
  }

  Widget _buildPostDetailCard(Map<String, dynamic> post,
      {ScrollController? scrollController,
        StateSetter? setModalState}) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const CircleAvatar(
                    backgroundColor: Color(0xFFDB2777),
                    child: Icon(Icons.person,
                        color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (post['author'] != null &&
                                  post['author'] != widget.currentUser.name &&
                                  widget.onUserTap != null) {
                                try {
                                  final author = widget.users.firstWhere(
                                          (u) =>
                                      u.name == post['author'] ||
                                          u.username == post['author'],
                                      orElse: () => widget.currentUser);
                                  if (author.name != widget.currentUser.name)
                                    widget.onUserTap!(author);
                                } catch (e) {}
                              }
                            },
                            child: Text(
                                post['author'] == widget.currentUser.name
                                    ? context.tr.you
                                    : (post['author'] ?? context.tr.unknown),
                                style:
                                const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(post['type'] ?? '',
                              style: TextStyle(
                                  fontSize: 12, color: theme.hintColor)),
                        ])),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color:
                      const Color(0xFFDB2777).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                      post['price'] ?? context.tr.free,
                      style: const TextStyle(
                          color: Color(0xFFDB2777),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                if (effectiveUser.username ==
                    widget.currentUser.username)
                  Theme(
                    data: theme.copyWith(
                        popupMenuTheme: PopupMenuThemeData(
                            color: const Color(0xFF475569),
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12)))),
                    child: PopupMenuButton<String>(
                      offset: const Offset(0, 30),
                      icon: Icon(Icons.more_vert,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          size: 20),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.pop(context);
                          widget.onPostAction(post, 'edit');
                        } else if (value == 'delete') {
                          Navigator.pop(context);
                          widget.onPostDeleted != null
                              ? widget.onPostDeleted!(post)
                              : widget.onPostAction(post, 'Delete');
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              const Icon(Icons.edit_outlined,
                                  size: 20, color: Colors.white70),
                              const SizedBox(width: 8),
                              Text(context.tr.editPost,
                                  style: const TextStyle(
                                      color: Colors.white))
                            ])),
                        PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              const Icon(Icons.delete_outline,
                                  size: 20,
                                  color: Color(0xFFD32F2F)),
                              const SizedBox(width: 8),
                              Text(context.tr.deletePost,
                                  style: const TextStyle(
                                      color: Color(0xFFD32F2F)))
                            ])),
                      ],
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
              if (post['filePath'] != null) ...[
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildPostMedia(post)),
                const SizedBox(height: 15),
              ],
              Row(crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: _buildFilteredText(
                            post['title'] ?? context.tr.untitled,
                            const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                            maxLines: 2)),
                  ]),
              if (post['content'] != null &&
                  post['content'].toString().trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildFilteredText(
                    post['content'] ?? "",
                    TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5),
                    maxLines: 2),
              ],
              const SizedBox(height: 20),
              const Divider(),
              Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final key =
                            post['id']?.toString() ?? '';
                        if (key.isEmpty) return;
                        final wasLiked =
                        _likedPostIds.contains(key);
                        final postIndex = _posts.indexWhere(
                                (p) => p['id'].toString() == key);
                        setState(() {
                          if (wasLiked) {
                            _likedPostIds.remove(key);
                            if (postIndex != -1) {
                              final current =
                              (_posts[postIndex]
                              ['likeCount'] ??
                                  1) as num;
                              _posts[postIndex]['likeCount'] =
                                  (current - 1)
                                      .clamp(0,
                                      double.infinity)
                                      .toInt();
                              post['likeCount'] =
                              _posts[postIndex]['likeCount'];
                            }
                          } else {
                            _likedPostIds.add(key);
                            if (postIndex != -1) {
                              final current =
                              (_posts[postIndex]
                              ['likeCount'] ??
                                  0) as num;
                              _posts[postIndex]['likeCount'] =
                                  current.toInt() + 1;
                              post['likeCount'] =
                              _posts[postIndex]['likeCount'];
                            }
                          }
                        });
                        widget.onPostAction(post, 'Like');
                        final pid = post['id'] is int
                            ? post['id'] as int
                            : int.tryParse(
                            post['id'].toString());
                        if (pid != null) {
                          try {
                            final prefs =
                            await SharedPreferences
                                .getInstance();
                            final token =
                                prefs.getString('auth_token') ??
                                    '';
                            final dio = Dio();
                            dio.options.baseUrl =
                            'https://openzippers.com/api/v1/';
                            dio.options.headers = {
                              'Accept': 'application/json',
                              'Authorization': 'Bearer $token',
                            };
                            final response = await dio.post(
                              'zippfans/likes/post',
                              data: {'post_id': pid},
                              options: Options(
                                  validateStatus: (s) =>
                                  s != null && s < 600),
                            );
                            if (response.statusCode == 200 &&
                                response.data is Map) {
                              final data =
                              response.data['data'];
                              if (data is Map && mounted) {
                                setState(() {
                                  final isLiked =
                                      data['is_liked'] == true;
                                  isLiked
                                      ? _likedPostIds.add(key)
                                      : _likedPostIds.remove(key);
                                  if (postIndex != -1 &&
                                      data['likes_count'] !=
                                          null) {
                                    _posts[postIndex]
                                    ['likeCount'] =
                                    data['likes_count'];
                                    post['likeCount'] =
                                    data['likes_count'];
                                  }
                                });
                              }
                            }
                          } catch (e) {
                            debugPrint(
                                '=== LIKE EXCEPTION: $e');
                            setState(() {
                              wasLiked
                                  ? _likedPostIds.add(key)
                                  : _likedPostIds.remove(key);
                            });
                          }
                        }
                      },
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _likedPostIds.contains(
                                  post['id']?.toString() ??
                                      '')
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _kPink,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                                "${post['likeCount'] ?? 0}",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                    fontSize: 13)),
                          ]),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _openCommentsSheet(post);
                      },
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                color:
                                Theme.of(context).hintColor,
                                size: 20),
                            const SizedBox(width: 4),
                            Text(
                                "${_getCommentCount(post)}",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                    fontSize: 13)),
                          ]),
                    ),
                    const SizedBox(width: 20),
                    Builder(builder: (context) {
                      final int pid = post['id'] is int
                          ? post['id']
                          : int.tryParse(
                          post['id'].toString()) ??
                          0;
                      final ra = ref.watch(ratingProvider(pid));
                      return ra.when(
                        data: (r) {
                          final avg = r.data.averageRating;
                          final userRating =
                              r.data.userRating ?? 0;
                          return GestureDetector(
                            onTap: () =>
                                _showRatingDialog(post),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      userRating > 0
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                      avg.toStringAsFixed(1),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                          fontSize: 13)),
                                ]),
                          );
                        },
                        loading: () =>
                        const SizedBox(width: 40, height: 20),
                        error: (_, __) => GestureDetector(
                          onTap: () => _showRatingDialog(post),
                          child: const Icon(Icons.star_border,
                              color: Colors.amber, size: 20),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding:
                const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Comments (${_getCommentCount(post)})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              CommentSection(
                key: ValueKey('profile_cs_${post['id']}'),
                post: post,
                currentUser: widget.currentUser,
                users: widget.users,
                enableComments: true,
                onPostAction: (p, a, {extraData}) async {
                  if (a == 'SubmitComment' && extraData != null) {
                    final text =
                    (extraData['text'] ?? '').toString().trim();
                    final rawParentId = extraData['parentId'];
                    if (text.isEmpty) return;
                    int? parentIdInt;
                    if (rawParentId != null) {
                      if (rawParentId is int &&
                          rawParentId != 0) {
                        parentIdInt = rawParentId;
                      } else {
                        final parsed = int.tryParse(
                            rawParentId.toString());
                        if (parsed != null && parsed != 0)
                          parentIdInt = parsed;
                      }
                    }
                    final postId = p['id'] is int
                        ? p['id'] as int
                        : int.tryParse(p['id'].toString());
                    if (postId == null) return;
                    try {
                      final prefs =
                      await SharedPreferences.getInstance();
                      final token =
                          prefs.getString('auth_token') ?? '';
                      if (token.isEmpty) return;
                      final dio = Dio();
                      dio.options.baseUrl =
                      'https://openzippers.com/api/v1/';
                      dio.options.headers = {
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      };
                      final response = await dio.post(
                        'zippfans/comments',
                        data: {
                          'post_id': postId,
                          'content': text,
                          'comment': text,
                          if (parentIdInt != null)
                            'parent_id': parentIdInt,
                        },
                        options: Options(
                            validateStatus: (s) =>
                            s != null && s < 500),
                      );
                      if (response.statusCode == 200 ||
                          response.statusCode == 201) {
                        final existing = List.from(
                            p['comments'] as List? ?? []);
                        final newComment = <String, dynamic>{
                          'id': DateTime.now()
                              .millisecondsSinceEpoch,
                          'author': widget.currentUser.name,
                          'avatar': widget.currentUser.avatar,
                          'text': text,
                          'time': 'Just now',
                          'parentId': parentIdInt,
                          'timestamp': DateTime.now(),
                          'likes': <String>[],
                        };
                        existing.insert(0, newComment);
                        p['comments'] = existing;
                        final newCount = existing.length;
                        p['commentsCount'] = newCount;
                        p['comments_count'] = newCount;
                        final idx = _posts.indexWhere(
                                (pp) => pp['id'] == p['id']);
                        if (idx != -1) {
                          _posts[idx]['commentsCount'] = newCount;
                          _posts[idx]['comments'] = existing;
                        }
                        post['commentsCount'] = newCount;
                        post['comments_count'] = newCount;
                        post['comments'] = existing;
                        if (setModalState != null)
                          setModalState(() {});
                        else if (mounted) setState(() {});
                      } else {
                        final msg = response.data is Map
                            ? (response.data['message'] ??
                            'Failed to post')
                            : 'Error ${response.statusCode}';
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                              SnackBar(content: Text(msg)));
                        }
                      }
                    } catch (e) {
                      debugPrint('Comment submit error: $e');
                    }
                    return;
                  }
                  widget.onPostAction(p, a, extraData: extraData);
                  if (setModalState != null) setModalState(() {});
                  else if (mounted) setState(() {});
                },
                onUserTap: widget.onUserTap,
              ),
            ]),
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
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
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
          ]
        ]),
      ),
    );
  }

  Widget _buildPostMedia(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final String type = post['type'];
    final String path = post['filePath'];
    if (!_isUnlocked(post)) return _buildLockedOverlay(context, post);
    if (kIsWeb) {
      return Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey[200],
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getIconForType(type), size: 50, color: Colors.grey),
                const SizedBox(height: 10),
                Text(context.tr.mediaPreviewNotAvailable,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12))
              ]));
    }
    if (type == 'Image') {
      if (path.startsWith('http')) {
        return Image.network(path,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, _, _) => Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(context.tr.mediaPreviewNotAvailable,
                          style: const TextStyle(color: Colors.grey))
                    ])));
      }
      return Image.file(File(path),
          fit: BoxFit.cover, width: double.infinity);
    } else if (type == 'Video' ||
        type == 'Reel' ||
        type == 'Reels') {
      return SizedBox(
          height: 450,
          width: double.infinity,
          child: VideoPlayerWidget(
            videoPath: path,
            coverPath: post['coverPath'],
            autoPlay: true,
            showPlayButton: false,
            showEnlargeButton: true,
            onPlayStateChanged: (isPlaying) {
              if (mounted)
                setState(() => _isVideoPlaying = isPlaying);
            },
          ));
    } else if (type == 'Song') {
      return AudioPlayerWidget(
          audioPath: path,
          coverPath: post['imageUrl'] ?? post['coverPath']);
    } else if (type == 'Literature') {
      return Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.cardColor,
              border: Border.all(color: theme.dividerColor)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: path.startsWith('http')
                  ? SfPdfViewer.network(path)
                  : SfPdfViewer.file(File(path))));
    }
    return const SizedBox();
  }

  Widget _buildLockedOverlay(
      BuildContext context, Map<String, dynamic> post) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.black, borderRadius: BorderRadius.circular(12)),
      child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1)),
                    child: const Icon(Icons.lock_outline,
                        size: 32, color: Colors.white)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (widget.onUserAction != null) {
                      await widget.onUserAction!(
                          effectiveUser, 'Subscribe');
                      await _refreshUserData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: const Text("Subscribe to Unlock",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ])),
    );
  }

  int _countAllComments(List<dynamic> comments) {
    int total = 0;
    for (var c in comments) {
      total++;
      if (c['replies'] is List) {
        total += _countAllComments(c['replies'] as List);
      }
    }
    return total;
  }

  void _showInfoDialog(Map<String, dynamic> post) {
    showDialog(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: theme.cardColor,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child:
                FutureBuilder<Map<String, String>>(
                  future: _getContentMetadata(post),
                  builder: (context, snapshot) {
                    final metadata = snapshot.data ?? {};
                    final isLoading = snapshot.connectionState ==
                        ConnectionState.waiting;
                    String dateStr = context.tr.notAvailable;
                    if (post['date'] != null) {
                      DateTime dt = post['date'] is DateTime
                          ? post['date']
                          : (DateTime.tryParse(
                          post['date'].toString()) ??
                          DateTime.now());
                      dateStr =
                      "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
                    }
                    return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(context.tr.contentDetails,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                        FontWeight.bold)),
                                IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 20),
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    padding: EdgeInsets.zero,
                                    constraints:
                                    const BoxConstraints()),
                              ]),
                          const Divider(),
                          const SizedBox(height: 20),
                          _buildDetailRow(Icons.favorite_border,
                              context.tr.likes,
                              "${post['likeCount'] ?? 0}"),
                          _buildDetailRow(
                              Icons.chat_bubble_outline,
                              context.tr.comments,
                              "${_getCommentCount(post)}"),
                          _buildDetailRow(Icons.image_outlined,
                              context.tr.type,
                              post['type'] ?? context.tr.post),
                          if (isLoading)
                            const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10),
                                child: Center(
                                    child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child:
                                        CircularProgressIndicator(
                                            strokeWidth: 2))))
                          else ...[
                            _buildDetailRow(
                                Icons.aspect_ratio,
                                context.tr.sizeLabel,
                                metadata['size'] ??
                                    context.tr.notAvailable),
                            _buildDetailRow(
                                Icons.crop,
                                context.tr.dimension,
                                metadata['dimension'] ??
                                    context.tr.notAvailable),
                          ],
                          _buildDetailRow(
                              Icons.calendar_today_outlined,
                              context.tr.uploadedOn,
                              dateStr),
                        ]);
                  },
                )),
          );
        });
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: theme.hintColor),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: theme.hintColor, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ]));
  }

  Future<Map<String, String>> _getContentMetadata(
      Map<String, dynamic> post) async {
    final Map<String, String> result = {
      'size': 'N/A',
      'dimension': 'N/A'
    };
    final filePath = post['filePath'] as String?;
    if (post['width'] != null && post['height'] != null)
      result['dimension'] =
      "${post['width']} x ${post['height']}";
    if (filePath == null || filePath.isEmpty) return result;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final len = await file.length();
        if (len < 1024)
          result['size'] = "$len B";
        else if (len < 1024 * 1024)
          result['size'] =
          "${(len / 1024).toStringAsFixed(1)} KB";
        else
          result['size'] =
          "${(len / (1024 * 1024)).toStringAsFixed(1)} MB";
        if (result['dimension'] == 'N/A') {
          final String type =
          (post['type'] ?? '').toString().toLowerCase();
          if (type == 'image') {
            final completer = Completer<ui.Image>();
            final stream = FileImage(file)
                .resolve(const ImageConfiguration());
            late ImageStreamListener listener;
            listener = ImageStreamListener(
                  (ImageInfo info, bool _) {
                if (!completer.isCompleted)
                  completer.complete(info.image);
              },
              onError: (e, _) {
                if (!completer.isCompleted)
                  completer.completeError(e);
              },
            );
            stream.addListener(listener);
            try {
              final uiImage = await completer.future;
              stream.removeListener(listener);
              result['dimension'] =
              "${uiImage.width} x ${uiImage.height}";
            } catch (e) {
              stream.removeListener(listener);
            }
          } else if (type == 'video' ||
              type == 'reel' ||
              type == 'reels') {
            try {
              final controller =
              VideoPlayerController.file(file);
              await controller.initialize();
              final size = controller.value.size;
              if (size.width > 0 && size.height > 0)
                result['dimension'] =
                "${size.width.toInt()} x ${size.height.toInt()}";
              await controller.dispose();
            } catch (e) {}
          }
        }
      }
    } catch (e) {}
    return result;
  }

  void _deleteAlbum(Map<String, dynamic> album) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr.deleteAlbum),
          content: Text(context.tr.deleteAlbumConfirmation),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                if (album['id'] != null)
                  await _dbHelper.deleteAlbum(album['id']);
                setState(() => _albums.remove(album));
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(context.tr.albumDeleted),
                          backgroundColor:
                          const Color(0xFFDB2777)));
              },
              child: Text(context.tr.delete),
            ),
          ],
        ));
  }

  void _addAlbumToCart(Map<String, dynamic> album) async {
    if (isMe) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr.ownPostsNoCart),
            backgroundColor: Colors.orange));
      return;
    }
    try {
      final cartItem = Map<String, dynamic>.from(album);
      cartItem['type'] = 'Album';
      if (album['cover'] != null) {
        cartItem['image'] = album['cover'];
        cartItem['coverPath'] = album['cover'];
      }
      await _dbHelper.addToCart(cartItem, widget.currentUser.username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr.itemAddedToCart),
            backgroundColor: Colors.green));
        if (widget.cartItemsNotifier != null) {
          final updatedCart = await _dbHelper
              .getCartItems(widget.currentUser.username);
          widget.cartItemsNotifier!.value = updatedCart;
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
            Text(context.tr.errorAddingToCart(e.toString())),
            backgroundColor: Colors.red));
    }
  }

  void _showAlbumDetailsDialog(Map<String, dynamic> album) {
    showDialog(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final width = MediaQuery.of(context).size.width;
          final isDesktop = width > 800;
          final tracks = (album['media'] as List).where((t) {
            final type =
            (t['type'] ?? '').toString().toLowerCase();
            return type == 'song' ||
                type == 'video' ||
                type == 'reel' ||
                type == 'reels';
          }).toList();
          return Dialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: isDesktop ? 700 : width * 0.95,
              height:
              MediaQuery.of(context).size.height * 0.7,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr.albumDetails,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  Navigator.pop(context)),
                        ])),
                Expanded(
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                            width: 140,
                                            height: 140,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                                image: album['cover'] != null &&
                                                    album['cover']
                                                        .toString()
                                                        .isNotEmpty
                                                    ? DecorationImage(
                                                    image: album['cover']
                                                        .startsWith(
                                                        'http')
                                                        ? NetworkImage(
                                                        album['cover'])
                                                        : FileImage(File(album[
                                                    'cover']))
                                                    as ImageProvider,
                                                    fit: BoxFit.cover)
                                                    : null,
                                                color: Colors.grey[800]),
                                            child: (album['cover'] == null ||
                                                album['cover'].isEmpty)
                                                ? const Icon(Icons.album,
                                                size: 60,
                                                color: Colors.white54)
                                                : null),
                                        const SizedBox(width: 24),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      album['title'] ??
                                                          context.tr.unknownAlbum,
                                                      style: TextStyle(
                                                          fontSize: 24,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          color: theme.textTheme
                                                              .titleLarge?.color),
                                                      maxLines: 2,
                                                      overflow:
                                                      TextOverflow.ellipsis),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                      context.tr.tracksCount(
                                                          tracks.length),
                                                      style: TextStyle(
                                                          color: theme.hintColor,
                                                          fontSize: 14)),
                                                  const SizedBox(height: 20),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      if (tracks.isNotEmpty) {
                                                        Navigator.pop(context);
                                                        _playAlbum(album,
                                                            allAlbums: _albums);
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.play_arrow,
                                                        size: 20),
                                                    label: Text(
                                                        context.tr.playAlbum),
                                                    style:
                                                    ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                        const Color(
                                                            0xFFDB2777),
                                                        foregroundColor:
                                                        Colors.white,
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 24,
                                                            vertical: 12)),
                                                  ),
                                                ])),
                                      ])),
                              const SizedBox(height: 32),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Text(context.tr.tracks,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                itemCount: tracks.length,
                                itemBuilder: (context, index) {
                                  final track = tracks[index];
                                  return ListTile(
                                    leading: Text('${index + 1}',
                                        style: TextStyle(
                                            color: theme.hintColor)),
                                    title: Text(
                                        track['title'] ??
                                            context.tr.untitled,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        _localizeType(
                                            track['type'] ?? '')),
                                    trailing: Icon(
                                        Icons.play_circle_outline,
                                        color: theme.hintColor),
                                    onTap: () {
                                      Navigator.pop(context);
                                      AlbumPlayerDialog.show(context, album,
                                          initialIndex: index,
                                          allAlbums: _albums);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ]))),
              ]),
            ),
          );
        });
  }

  void _playAlbum(Map<String, dynamic> album,
      {List<Map<String, dynamic>>? allAlbums}) {
    final bool isOwner =
        album['author'] == widget.currentUser.username ||
            album['author'] == widget.currentUser.name;
    final bool isPrivate =
        album['isPrivate'] == 1 || album['isPrivate'] == true;
    final bool hasPrice = album['price'] != null &&
        album['price'].toString().isNotEmpty &&
        album['price'] != '0' &&
        album['price'] != 'Free';
    if (isOwner) {
      AlbumPlayerDialog.show(context, album,
          allAlbums: allAlbums,
          currentAlbumIndex:
          allAlbums != null ? allAlbums.indexOf(album) : -1);
    } else if (isPrivate) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("This album is private."),
          backgroundColor: Colors.red));
    } else if (hasPrice && !effectiveUser.isSubscribed) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Unlock Album"),
            content: Text(
                "This album requires a subscription to ${effectiveUser.name}.\nPrice: ${album['price']}"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.tr.cancel)),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _addAlbumToCart(album);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white),
                  child: const Text("Add to Cart")),
            ],
          ));
    } else {
      AlbumPlayerDialog.show(context, album,
          allAlbums: allAlbums,
          currentAlbumIndex:
          allAlbums != null ? allAlbums.indexOf(album) : -1);
    }
  }

  void _showCreateAlbumDialog(
      {Map<String, dynamic>? existingAlbum}) {
    final userMedia = widget.posts.where((p) {
      final type = p['type'];
      final isAuthor = p['author'] == widget.currentUser.name ||
          p['author'] == widget.currentUser.username;
      return isAuthor &&
          (type == 'Song' ||
              type == 'Video' ||
              type == 'Reel' ||
              type == 'Reels');
    }).toList();
    final List<Map<String, dynamic>> selectedMedia = [];
    if (existingAlbum != null) {
      for (var track in (existingAlbum['media'] as List)) {
        if ((track['type'] ?? '').toString().toLowerCase() ==
            'image') continue;
        final matching = userMedia.firstWhere(
                (m) => m['id'] == track['id'],
            orElse: () =>
            Map<String, dynamic>.from(track as Map));
        selectedMedia.add(matching);
      }
    }
    String title = existingAlbum?['title'] ?? '';
    bool isPublic = !(existingAlbum != null &&
        (existingAlbum['isPrivate'] == 1 ||
            existingAlbum['isPrivate'] == true));
    String price =
    (existingAlbum?['price'] ?? "0.00").toString();
    String? coverPath = existingAlbum?['cover'];
    final titleController =
    TextEditingController(text: title);
    final priceController =
    TextEditingController(text: price);
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            final width = MediaQuery.of(context).size.width;
            final isDesktop = width > 800;
            return Dialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: isDesktop ? 800 : width * 0.95,
                height:
                MediaQuery.of(context).size.height * 0.85,
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                existingAlbum != null
                                    ? context.tr.editAlbum
                                    : context.tr.createAlbum,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            IconButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                icon: const Icon(Icons.close,
                                    color: Colors.white70)),
                          ]),
                      const SizedBox(height: 24),
                      Expanded(
                          child: SingleChildScrollView(
                              child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(context.tr.albumTitle,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    const SizedBox(height: 8),
                                    TextField(
                                        controller: titleController,
                                        onChanged: (val) => title = val,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                            hintText:
                                            context.tr.enterAlbumTitle,
                                            hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.3)),
                                            filled: true,
                                            fillColor:
                                            const Color(0xFF334155),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                                borderSide:
                                                BorderSide.none),
                                            contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12))),
                                    const SizedBox(height: 20),
                                    Row(children: [
                                      Text("Visibility",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 13)),
                                      const SizedBox(width: 12),
                                      Switch(
                                          value: isPublic,
                                          onChanged: (val) => setState(
                                                  () => isPublic = val),
                                          activeTrackColor:
                                          const Color(0xFF22C55E),
                                          activeThumbColor: Colors.white,
                                          inactiveThumbColor:
                                          Colors.white70,
                                          inactiveTrackColor: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                          isPublic ? "Public" : "Private",
                                          style: TextStyle(
                                              color: isPublic
                                                  ? Colors.white
                                                  : Colors.white54,
                                              fontSize: 13)),
                                    ]),
                                    const SizedBox(height: 20),
                                    Text("Price",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    const SizedBox(height: 8),
                                    TextField(
                                        controller: priceController,
                                        onChanged: (val) => price = val,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        keyboardType:
                                        const TextInputType
                                            .numberWithOptions(
                                            decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}'))
                                        ],
                                        decoration: InputDecoration(
                                            hintText: "0.00",
                                            hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.3)),
                                            filled: true,
                                            fillColor:
                                            const Color(0xFF334155),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                                borderSide:
                                                BorderSide.none),
                                            contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12),
                                            isDense: true)),
                                    const SizedBox(height: 32),
                                    Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A)
                                                .withOpacity(0.5),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.05))),
                                        child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    Text("Select Media",
                                                        style: const TextStyle(
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            color:
                                                            Colors.white70,
                                                            fontSize: 13)),
                                                    TextButton(
                                                        onPressed: () =>
                                                            setState(() =>
                                                                selectedMedia
                                                                    .clear()),
                                                        child: Text(
                                                            context.tr
                                                                .deselectAll,
                                                            style: const TextStyle(
                                                                color: Color(
                                                                    0xFFDB2777),
                                                                fontSize: 12))),
                                                  ]),
                                              const SizedBox(height: 12),
                                              Container(
                                                  height: 150,
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF334155)
                                                          .withOpacity(0.5),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          8)),
                                                  child: userMedia.isEmpty
                                                      ? Center(
                                                      child: Text(
                                                          context.tr
                                                              .noMediaFound,
                                                          style: const TextStyle(
                                                              color: Colors
                                                                  .white54)))
                                                      : ListView.separated(
                                                    padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                    itemCount:
                                                    userMedia.length,
                                                    separatorBuilder:
                                                        (_, _) =>
                                                    const SizedBox(
                                                        height: 8),
                                                    itemBuilder:
                                                        (context, index) {
                                                      final item =
                                                      userMedia[index];
                                                      final isSelected =
                                                      selectedMedia.any(
                                                              (m) =>
                                                          m['id'] ==
                                                              item[
                                                              'id']);
                                                      return InkWell(
                                                        onTap: () =>
                                                            setState(() {
                                                              if (isSelected) {
                                                                selectedMedia
                                                                    .removeWhere(
                                                                        (m) =>
                                                                    m['id'] ==
                                                                        item[
                                                                        'id']);
                                                              } else {
                                                                selectedMedia
                                                                    .add(item);
                                                                if (coverPath ==
                                                                    null) {
                                                                  final c = item[
                                                                  'coverPath'] ??
                                                                      item[
                                                                      'covers'] ??
                                                                      item[
                                                                      'image'] ??
                                                                      item[
                                                                      'filePath'];
                                                                  if (c != null)
                                                                    coverPath =
                                                                        c.toString();
                                                                }
                                                              }
                                                            }),
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(8),
                                                        child: Container(
                                                          padding:
                                                          const EdgeInsets
                                                              .all(8),
                                                          decoration: BoxDecoration(
                                                              color: isSelected
                                                                  ? const Color(
                                                                  0xFFDB2777)
                                                                  .withOpacity(
                                                                  0.1)
                                                                  : Colors
                                                                  .transparent,
                                                              borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                  8),
                                                              border: Border.all(
                                                                  color: isSelected
                                                                      ? const Color(
                                                                      0xFFDB2777)
                                                                      : Colors
                                                                      .transparent)),
                                                          child: Row(
                                                              children: [
                                                                Icon(
                                                                    isSelected
                                                                        ? Icons
                                                                        .check_box
                                                                        : Icons
                                                                        .check_box_outline_blank,
                                                                    color: isSelected
                                                                        ? const Color(
                                                                        0xFFDB2777)
                                                                        : Colors
                                                                        .white54,
                                                                    size: 20),
                                                                const SizedBox(
                                                                    width: 12),
                                                                Expanded(
                                                                    child: Column(
                                                                        crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                        children: [
                                                                          Text(
                                                                              item['title'] ??
                                                                                  context
                                                                                      .tr
                                                                                      .untitled,
                                                                              style: const TextStyle(
                                                                                  color: Colors
                                                                                      .white,
                                                                                  fontSize:
                                                                                  13)),
                                                                          Text(
                                                                              _localizeType(
                                                                                  item['type'] ??
                                                                                      ''),
                                                                              style: TextStyle(
                                                                                  color: Colors.white.withOpacity(
                                                                                      0.5),
                                                                                  fontSize:
                                                                                  11)),
                                                                        ])),
                                                              ]),
                                                        ),
                                                      );
                                                    },
                                                  )),
                                            ])),
                                    const SizedBox(height: 40),
                                  ]))),
                      Row(
                          mainAxisAlignment:
                          MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                child: const Text("Cancel",
                                    style: TextStyle(
                                        color: Colors.white70))),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: (title.isNotEmpty &&
                                  selectedMedia.isNotEmpty)
                                  ? () {
                                if (existingAlbum != null) {
                                  _updateAlbum(
                                      existingAlbum,
                                      title,
                                      price,
                                      coverPath,
                                      !isPublic,
                                      selectedMedia.toList());
                                } else {
                                  _createAlbum(
                                      title,
                                      price,
                                      coverPath,
                                      !isPublic,
                                      selectedMedia.toList());
                                }
                                Navigator.pop(context);
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFFDB2777),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12)),
                              child: Text(existingAlbum != null
                                  ? context.tr.updateAlbum
                                  : context.tr.createAlbum),
                            ),
                          ]),
                    ]),
              ),
            );
          });
        });
  }

  Future<void> _loadPostsFromApiSilent() async {
    try {
      if (!mounted) return;
      final authRepo = ref.read(authRepositoryProvider);
      final username = effectiveUser.username;
      if (username.isEmpty) return;
      final apiResponse = await authRepo.getUserByUsername(username);
      if (apiResponse.success && apiResponse.data != null && mounted) {
        final posts = apiResponse.data!.posts ?? [];
        final normalized = posts.map((p) {
          final raw = Map<String, dynamic>.from(p as Map);
          final map = PostHelper.normalizePost(raw);
          map['id'] = raw['id'];
          map['commentsCount'] =
              raw['comments_count'] ?? raw['commentsCount'] ?? 0;
          map['likeCount'] =
              raw['likes_count'] ?? raw['likeCount'] ?? raw['like_count'] ?? 0;
          map['imageUrl'] =
              raw['image'] ?? raw['imageUrl'] ?? raw['thumbnail'] ?? '';
          map['filePath'] = raw['video_url'] ??
              raw['audio_url'] ??
              raw['literature_url'] ??
              raw['image'] ??
              '';
          map['coverPath'] =
              raw['preview_url'] ?? raw['cover'] ?? raw['image'] ?? '';
          map['is_liked'] = raw['is_liked'];
          return map;
        }).toList();

        if (mounted) {
          setState(() {
            for (final updated in normalized) {
              final id = updated['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              final existingIdx = _posts.indexWhere(
                    (p) => p['id']?.toString() == id,
              );
              if (existingIdx != -1) {
                final localCount =
                (_posts[existingIdx]['commentsCount'] ?? 0) as num;
                final serverCount =
                (updated['commentsCount'] ?? 0) as num;
                if (serverCount > localCount) {
                  _posts[existingIdx]['commentsCount'] =
                  updated['commentsCount'];
                }
                _posts[existingIdx]['likeCount'] = updated['likeCount'];
              }
              if (updated['is_liked'] == true ||
                  updated['is_liked'] == 1) {
                _likedPostIds.add(id);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('_loadPostsFromApiSilent error: $e');
    }
  }

  void _createAlbum(String title, String price, String? coverPath,
      bool isPrivate, List<Map<String, dynamic>> media) async {
    final newAlbum = {
      'author': widget.currentUser.username,
      'title': title,
      'price': price,
      'isPrivate': isPrivate ? 1 : 0,
      'cover': coverPath ??
          'https://picsum.photos/seed/${title.hashCode}_album/400/300',
      'trackCount': media.length,
      'year': DateTime.now().year.toString(),
      'media': media,
    };
    final id = await _dbHelper.insertAlbum(newAlbum);
    newAlbum['id'] = id;
    setState(() => _albums.add(newAlbum));
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr.albumCreated(title)),
          backgroundColor: const Color(0xFFDB2777)));
  }

  void _updateAlbum(
      Map<String, dynamic> album,
      String title,
      String price,
      String? coverPath,
      bool isPrivate,
      List<Map<String, dynamic>> media) async {
    setState(() {
      album['title'] = title;
      album['price'] = price;
      album['isPrivate'] = isPrivate ? 1 : 0;
      album['cover'] = coverPath ??
          album['cover'] ??
          'https://picsum.photos/seed/${title.hashCode}_album/400/300';
      album['trackCount'] = media.length;
      album['media'] = media;
    });
    await _dbHelper.updateAlbum(album);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr.albumUpdated),
          backgroundColor: const Color(0xFFDB2777)));
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  DashedBorderPainter(
      {this.color = Colors.black,
        this.strokeWidth = 2.0,
        this.gap = 5.0});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12)));
    canvas.drawPath(_createDashedPath(path, gap, gap), paint);
  }

  Path _createDashedPath(Path source, double advance, double gap) {
    final pathMetrics = source.computeMetrics();
    Path dest = Path();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        double len = draw ? advance : gap;
        if (draw)
          dest.addPath(
              metric.extractPath(distance, distance + len), Offset.zero);
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.gap != gap;
}