// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../models/mock_data.dart';
// import '../widgets/media_player_widgets.dart';
// import '../widgets/comments_bottom_sheet.dart';
// import '../helpers/translations.dart';
// import 'package:path/path.dart' as p;
//
// class ReelsScreen extends StatefulWidget {
//   final List<Map<String, dynamic>> posts;
//   final MockUser currentUser;
//   final List<MockUser> users;
//   final Function(Map<String, dynamic>, String, {dynamic extraData})? onPostAction;
//   final Function(MockUser)? onUserTap;
//   final List<Map<String, dynamic>> readPosts;
//   final List<Map<String, dynamic>> watchedPosts;
//   final List<Map<String, dynamic>> bookmarkedPosts;
//     final bool isActive;
//     final int? startPostId;
//     final bool showImages;
//     final bool enableComments;
//
//     const ReelsScreen({
//       super.key,
//       required this.posts,
//       required this.currentUser,
//       required this.users,
//       this.onPostAction,
//       this.onUserTap,
//       this.readPosts = const [],
//       this.watchedPosts = const [],
//       this.bookmarkedPosts = const [],
//       this.isActive = true,
//       this.startPostId,
//       this.showImages = false,
//       this.enableComments = true,
//     });
//
//   @override
//   State<ReelsScreen> createState() => ReelsScreenState();
// }
//
// class ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
//   int _currentIndex = 0;
//   late final PageController _pageController; // Changed to late
//   final Map<int, GlobalKey> _videoKeys = {};
//   final bool _isChangePage = false; // Note: original was _isChangingPage? Let's check.
//   // Line 40 in view was: bool _isChangingPage = false;
//   // I should keep that name or update. I'll stick to _isChangingPage to avoid breaking other code.
//   bool _isChangingPage = false;
//   final Set<int> _previewingPosts = {};
//   bool _isPlaying = true; // Track playing state to adjust UI overlay
//   bool _isCommentsOpen = false; // Track if comments are open
//   final Set<String> _likedPostIds = {}; // Local state for liked posts to ensure immediate UI updates
//
//   List<Map<String, dynamic>> get _reelsPosts {
//
//     return widget.posts.where((post) {
//       final type = post['type']?.toString() ?? '';
//
//       // Also include mislabeled "Image" posts IF they are actually video files
//       // (This covers the user's "recovered" post)
//       if (type == 'Image') {
//          final path = post['filePath'] as String? ??
//                       post['image'] as String? ??
//                       post['media'] as String?;
//          if (path != null) {
//             final lower = path.toLowerCase();
//             if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv')) {
//                return true;
//             }
//          }
//          return widget.showImages; // Controlled by flag for "short view" from profile
//       }
//
//       return type == 'Video' || type == 'Reel' || type == 'Reels';
//     }).toList();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     int initialIndex = 0;
//     if (widget.startPostId != null) {
//        final foundIndex = _reelsPosts.indexWhere((p) => p['id'] == widget.startPostId);
//        if (foundIndex != -1) {
//          initialIndex = foundIndex;
//        }
//     }
//     _currentIndex = initialIndex;
//     _pageController = PageController(initialPage: _currentIndex);
//
//     for (int i = 0; i < _reelsPosts.length; i++) {
//       _videoKeys[i] = GlobalKey();
//     }
//
//     // Initialize liked posts from readPosts (assuming readPosts tracks initial state as per existing logic)
//     for (var p in widget.readPosts) {
//       final key = "${p['title']}_${p['author']}";
//       _likedPostIds.add(key);
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     if (!mounted) return;
//
//     try {
//       if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
//
//       } else if (state == AppLifecycleState.resumed) {
//
//         if (_currentIndex < _reelsPosts.length) {
//
//           setState(() {
//
//           });
//         }
//       } else if (state == AppLifecycleState.detached) {
//
//       }
//     } catch (e) {
//       debugPrint("Error handling app lifecycle: $e");
//
//     }
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   bool _isFree(dynamic price) {
//     if (price == null) return true;
//     final p = price.toString().toLowerCase().replaceAll('\$', '').trim();
//     return p == 'free' || p == '0' || p == '0.00';
//   }
//
//   bool _isOwnPost(Map<String, dynamic> post) {
//     final postAuthor = post['author']?.toString().trim().toLowerCase() ?? '';
//     final currentName = widget.currentUser.name.toString().trim().toLowerCase() ?? '';
//     final currentUsername = widget.currentUser.username.toString().trim().toLowerCase() ?? '';
//
//     if (postAuthor.isEmpty) return false;
//     if (postAuthor == 'you') return true;
//     if (currentUsername.isNotEmpty && postAuthor == currentUsername) return true;
//
//     String stripRole(String name) {
//       return name.replaceAll(RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false), '')
//                  .replaceAll(' ', '')
//                  .trim().toLowerCase();
//     }
//
//     final postAuthorClean = stripRole(postAuthor);
//     final currentNameClean = stripRole(currentName);
//     final currentUsernameClean = stripRole(currentUsername);
//
//     return (postAuthorClean.isNotEmpty && postAuthorClean == currentNameClean) ||
//            (postAuthorClean.isNotEmpty && postAuthorClean == currentUsernameClean);
//   }
//
//   bool _isSubscribedToAuthor(String author) {
//     if (author.isEmpty) return false;
//     final authorLower = author.toLowerCase().trim();
//     if (authorLower == 'you') return true;
//
//     String clean(String s) => s.replaceAll(RegExp(r'\s*\((Artist|User)\)\s*', caseSensitive: false), '').replaceAll(' ', '').trim().toLowerCase();
//     final targetClean = clean(author);
//
//     try {
//       final userIdx = widget.users.indexWhere((u) => clean(u.name) == targetClean || clean(u.username) == targetClean);
//       if (userIdx != -1) {
//         return widget.users[userIdx].isSubscribed;
//       }
//     } catch (_) {}
//     return false;
//   }
//
//   bool _isUnlocked(Map<String, dynamic> post) {
//     if (_isOwnPost(post)) return true;
//     if (_isFree(post['price'])) return true;
//
//     final author = post['author']?.toString() ?? '';
//     return _isSubscribedToAuthor(author);
//   }
//
//   void _cleanupOldVideos(int currentIndex) {
//     if (!mounted) return;
//     try {
//
//       final keysToRemove = <int>[];
//       _videoKeys.forEach((key, value) {
//         if ((key - currentIndex).abs() > 3) {
//           keysToRemove.add(key);
//         }
//       });
//
//       for (final key in keysToRemove) {
//         _videoKeys.remove(key);
//       }
//
//
//       for (int i = currentIndex - 1; i <= currentIndex + 1; i++) {
//         if (i >= 0 && i < _reelsPosts.length && !_videoKeys.containsKey(i)) {
//           _videoKeys[i] = GlobalKey();
//         }
//       }
//     } catch (e) {
//       debugPrint("Error cleaning up videos: $e");
//
//     }
//   }
//
//   String _getDisplayTitle(Map<String, dynamic> post) {
//     String title = post['title']?.toString() ?? '';
//     if (title.isEmpty || title.toLowerCase() == 'untitled') {
//       final path = post['filePath']?.toString();
//       if (path != null && path.isNotEmpty) {
//         title = p.basenameWithoutExtension(path).replaceAll('_', ' ').replaceAll('-', ' ');
//       } else {
//         title = 'Untitled';
//       }
//     }
//     return title;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     if (_reelsPosts.isEmpty) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         extendBodyBehindAppBar: true,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           automaticallyImplyLeading: false,
//         ),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.video_library_outlined, size: 80, color: Colors.white54),
//               const SizedBox(height: 20),
//               Text(
//                 context.tr.noReelsAvailable,
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 context.tr.createOrFollowToSeeReels,
//                 style: TextStyle(color: theme.hintColor),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//       ),
//       body: PageView.builder(
//         controller: _pageController,
//         scrollDirection: Axis.vertical,
//         physics: const ClampingScrollPhysics(),
//         onPageChanged: (index) {
//           if (!mounted || _isChangingPage) return;
//
//           try {
//             _isChangingPage = true;
//
//
//             setState(() {
//               _currentIndex = index;
//             });
//
//
//             for (int i = index - 1; i <= index + 1; i++) {
//               if (i >= 0 && i < _reelsPosts.length && !_videoKeys.containsKey(i)) {
//                 _videoKeys[i] = GlobalKey();
//               }
//             }
//
//
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) {
//                 try {
//                   _cleanupOldVideos(index);
//                 } catch (e) {
//                   debugPrint("Error in cleanup callback: $e");
//                 } finally {
//                   _isChangingPage = false;
//                 }
//               } else {
//                 _isChangingPage = false;
//               }
//             });
//           } catch (e) {
//             debugPrint("Error in onPageChanged: $e");
//             _isChangingPage = false;
//           }
//         },
//         itemCount: _reelsPosts.length,
//         itemBuilder: (context, index) {
//
//           if (!_videoKeys.containsKey(index)) {
//             _videoKeys[index] = GlobalKey();
//           }
//
//           try {
//             return _buildReelItem(_reelsPosts[index], theme, index);
//           } catch (e) {
//             debugPrint("Error building reel item at index $index: $e");
//
//             return Container(
//               color: Colors.black,
//               child: const Center(
//                 child: Icon(Icons.error_outline, color: Colors.white54),
//               ),
//             );
//           }
//         },
//       ),
//     );
//   }
//
//   Widget _buildLockedOverlay(BuildContext context, Map<String, dynamic> post) {
//     final price = post['price']?.toString() ?? 'Free';
//     final previewPath = post['previewPath'] as String?;
//     final type = post['type']?.toString() ?? '';
//     final isVideo = type == 'Video' || type == 'Reel' || type == 'Reels';
//
//     String displayPrice = price;
//     if (!price.startsWith(context.tr.currencySymbol) && !price.toLowerCase().contains('free')) {
//       displayPrice = "${context.tr.currencySymbol}$price";
//     }
//
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(0),
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: Colors.black.withOpacity(0.8),
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.rectangle,
//                   borderRadius: BorderRadius.circular(12),
//                   color: Colors.white.withOpacity(0.1),
//                 ),
//                 child: const Icon(Icons.lock_outline, size: 32, color: Colors.white),
//               ),
//               const SizedBox(height: 16),
//
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//
//                   // Removed preview button
//
//                   ElevatedButton(
//                     onPressed: () => widget.onPostAction?.call(post, 'unlock'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFDB2777),
//                       foregroundColor: Colors.white,
//                       elevation: 5,
//                       shadowColor: const Color(0xFFDB2777).withOpacity(0.4),
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                     child: Text(
//                       context.tr.unlockPost,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildReelItem(Map<String, dynamic> post, ThemeData theme, int index) {
//     final path = post['filePath'] as String?;
//     final coverPath = post['coverPath'] as String?;
//
//
//     final videoKey = _videoKeys[index] ?? ValueKey('reel_${path}_$index');
//
//
//     final isPaid = !_isFree(post['price']);
//     final isOwnPost = _isOwnPost(post);
//
//     final postId = post['id'] as int?;
//
//     return Container(
//       color: Colors.black,
//       width: double.infinity,
//       height: double.infinity,
//       constraints: const BoxConstraints.expand(),
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//
//           if (path != null && path.isNotEmpty)
//             Positioned.fill(
//               child: (isPaid && !_isOwnPost(post) && !_isUnlocked(post))
//                   ? Stack(
//                           children: [
//                             // Show cover image or placeholder
//                             if (coverPath != null && coverPath.isNotEmpty)
//                                (coverPath.startsWith('http'))
//                                   ? Image.network(
//                                       coverPath,
//                                       width: double.infinity,
//                                       height: double.infinity,
//                                       fit: BoxFit.cover,
//                                       errorBuilder: (_, _, _) => Container(
//                                         color: Colors.black,
//                                         child: const Center(child: Icon(Icons.image_outlined, size: 60, color: Colors.grey)),
//                                       ),
//                                     )
//                                   : Image.file(
//                                       File(coverPath),
//                                       width: double.infinity,
//                                       height: double.infinity,
//                                       fit: BoxFit.cover,
//                                       errorBuilder: (_, _, _) => Container(
//                                         color: Colors.black,
//                                         child: const Center(child: Icon(Icons.image_outlined, size: 60, color: Colors.grey)),
//                                       ),
//                                     )
//                             else if (path.isNotEmpty && (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')))
//                                path.startsWith('http')
//                                   ? Image.network(path, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
//                                       errorBuilder: (_, _, _) => Container(
//                                         color: Colors.black,
//                                         child: const Center(child: Icon(Icons.image_outlined, size: 60, color: Colors.grey)),
//                                       ),
//                                     )
//                                   : Image.file(File(path), width: double.infinity, height: double.infinity, fit: BoxFit.cover)
//                             else
//                               Container(
//                                 color: Colors.black,
//                                 child: const Center(
//                                   child: Icon(Icons.videocam_outlined, size: 60, color: Colors.grey),
//                                 ),
//                               ),
//                             // Proper locked overlay
//                             Positioned.fill(
//                               child: _buildLockedOverlay(context, post),
//                             ),
//                           ],
//                         )
//                   : (post['type'] == 'Image')
//                       ? (path.startsWith('http')
//                           ? Image.network(path, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
//                               errorBuilder: (_, _, _) => Container(
//                                 color: Colors.black,
//                                 child: const Center(child: Icon(Icons.image_outlined, size: 60, color: Colors.grey)),
//                               ),
//                             )
//                           : Image.file(File(path), width: double.infinity, height: double.infinity, fit: BoxFit.cover))
//                       : VideoPlayerWidget(
//                             key: videoKey,
//                             videoPath: path,
//                             coverPath: coverPath,
//                             autoPlay: true,
//                             showControls: false, // Disable default controls to rely on internal custom controls (bottom bar)
//                             showEnlargeButton: true, // Enable zoom/fullscreen button
//                             allowCustomControls: true,
//                           fit: BoxFit.cover,
//                           onEnlargeTap: () {
//                              // Enter Full Screen Mode with Playlist Support
//                              Navigator.of(context).push(
//                                MaterialPageRoute(
//                                  builder: (context) => FullScreenVideoPlayer(
//                                    tracks: _reelsPosts,
//                                    initialIndex: index,
//                                  ),
//                                ),
//                              );
//                           },
//                           onPlayStateChanged: (playing) {
//                             if (index == _currentIndex && mounted) {
//                                if (_isPlaying != playing) {
//                                  setState(() => _isPlaying = playing);
//                                }
//                             }
//                           },
//                         ),
//
//             )
//           else
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.video_library_outlined, size: 80, color: Colors.white54),
//                   const SizedBox(height: 10),
//                   Text(context.tr.videoNotAvailable, style: TextStyle(color: Colors.white54)),
//                 ],
//               ),
//             ),
//
//
//           Positioned(
//             top: 0,
//             left: 0,
//             child: SafeArea(
//               child: Container(
//                 padding: const EdgeInsets.only(left: 12, top: 8, right: 12), // Minimal padding, left-aligned
//                 // No decoration - remove gradient overlay
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min, // Only take as much space as needed
//                   children: [
//                     Builder(
//                       builder: (context) {
//                         String avatarPath = '';
//                         ImageProvider? imageProvider;
//                         bool showFallback = false;
//
//                         try {
//                           final author = widget.users.firstWhere(
//                             (u) => u.name == post['author'],
//                             orElse: () => widget.currentUser,
//                           );
//                           avatarPath = author.avatar;
//
//                           if (avatarPath.isEmpty) {
//                             showFallback = true;
//                           } else if (avatarPath.startsWith('http')) {
//                             imageProvider = NetworkImage(avatarPath);
//                           } else if (avatarPath.startsWith('assets/')) {
//                             imageProvider = AssetImage(avatarPath);
//                           } else {
//                             try {
//                               final file = File(avatarPath);
//                               if (file.existsSync()) {
//                                 imageProvider = FileImage(file);
//                               } else {
//                                 showFallback = true;
//                               }
//                             } catch (e) {
//                               debugPrint("Error checking file existence: $e");
//                               showFallback = true;
//                             }
//                           }
//                         } catch (e) {
//                           debugPrint("Error finding user: $e");
//                           showFallback = true;
//                         }
//
//                         return GestureDetector(
//                           onTap: () {
//                             // Find the user and call onUserTap callback
//                             try {
//                               final author = widget.users.firstWhere(
//                                 (u) => u.name == post['author'],
//                                 orElse: () => widget.currentUser,
//                               );
//                               widget.onUserTap?.call(author);
//                             } catch (e) {
//                               debugPrint("Error finding user for profile navigation: $e");
//                             }
//                           },
//                           child: CircleAvatar(
//                             radius: 20,
//                             backgroundColor: const Color(0xFFDB2777).withOpacity(0.3),
//                             backgroundImage: imageProvider,
//                             child: showFallback
//                               ? const Icon(Icons.person, color: Colors.white, size: 20)
//                               : null,
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(width: 12),
//                     GestureDetector(
//                       onTap: () {
//
//                         try {
//                           final author = widget.users.firstWhere(
//                             (u) => u.name == post['author'],
//                             orElse: () => widget.currentUser,
//                           );
//                           widget.onUserTap?.call(author);
//                         } catch (e) {
//                           debugPrint("Error finding user for profile navigation: $e");
//                         }
//                       },
//                       child: Text(
//                         _isOwnPost(post) ? context.tr.you : (post['author']?.toString() ?? context.tr.unknown),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//
//                     if (_isOwnPost(post))
//                       PopupMenuButton<String>(
//                         icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
//                         color: Theme.of(context).cardColor,
//                         onSelected: (value) {
//                           if (value == 'delete') {
//                             _showDeletePostDialog(context, post);
//                           } else if (value == 'edit') {
//                             widget.onPostAction?.call(post, 'edit');
//                           }
//                         },
//                         itemBuilder: (context) => [
//                           PopupMenuItem<String>(
//                             value: 'edit',
//                             child: Row(
//                               children: [
//                                 Icon(Icons.edit_outlined, color: const Color(0xFFDB2777), size: 20),
//                                 SizedBox(width: 8),
//                                 Text(context.tr.editPost, style: const TextStyle(color: Color(0xFFDB2777))),
//                               ],
//                             ),
//                           ),
//                           PopupMenuItem<String>(
//                             value: 'delete',
//                             child: Row(
//                               children: [
//                                 Icon(Icons.delete_outline, color: const Color(0xFFD32F2F), size: 20),
//                                 SizedBox(width: 8),
//                                 Text(context.tr.deletePost, style: const TextStyle(color: Color(0xFFD32F2F))),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 padding: EdgeInsets.fromLTRB(12, 8, 12, _isPlaying ? 8 : 110), // Push up when paused to make room for controls
//
//
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: [
//                         // Like button
//                         Builder(
//                           builder: (context) {
//                             final key = "${post['title']}_${post['author']}";
//                             final isLiked = _likedPostIds.contains(key);
//
//                             return _buildReelActionButton(
//                               icon: isLiked ? Icons.favorite : Icons.favorite_border,
//                               count: post['likeCount'] ?? 0,
//                               color: const Color(0xFFDB2777), // Fixed Pink color
//                               onTap: () {
//                                 setState(() {
//                                   if (isLiked) {
//                                     _likedPostIds.remove(key);
//                                   } else {
//                                     _likedPostIds.add(key);
//                                   }
//                                 });
//                                 widget.onPostAction?.call(post, 'Like');
//                               },
//                             );
//                           }
//                         ),
//                         const SizedBox(width: 24), // Proper spacing between buttons
//                         // Comment button
//                         _buildReelActionButton(
//                           icon: _isCommentsOpen ? Icons.chat_bubble : Icons.chat_bubble_outline,
//                           count: _countRootComments(post['comments'] as List?),
//                           color: Colors.blue,
//                           onTap: () {
//                              // Toggle standard logic
//                              _showComments(context, post);
//
//                           },
//                         ),
//                         const SizedBox(width: 24), // Proper spacing between buttons
//                         // Rating button
//                         Builder(
//                           builder: (context) {
//                              final double avgRating = (post['averageRating'] is num) ? (post['averageRating'] as num).toDouble() : 0.0;
//                              final int totalRatings = (post['totalRatings'] ?? post['ratingCount'] ?? 0) as int;
//
//                              return GestureDetector(
//                                onTap: () => widget.onPostAction?.call(post, 'Rate'),
//                                child: Column(
//                                  mainAxisSize: MainAxisSize.min,
//                                  children: [
//                                    Icon(
//                                      widget.watchedPosts.any((p) => p['title'] == post['title'] && p['author'] == post['author'])
//                                        ? Icons.star
//                                        : Icons.star_border,
//                                      color: Colors.amber,
//                                      size: 28
//                                    ),
//                                    const SizedBox(height: 6), // Increased spacing
//                                    Text(
//                                      avgRating > 0 ? avgRating.toStringAsFixed(1) : (totalRatings > 0 ? _formatCount(totalRatings) : ''),
//                                      style: const TextStyle(
//                                        color: Colors.white,
//                                        fontSize: 11, // Reduced font size
//                                        fontWeight: FontWeight.bold,
//                                      ),
//                                    ),
//                                  ],
//                                ),
//                              );
//                            }
//                         ),
//                       ],
//                     ),
//                     // Post Title and Description below action buttons
//                     if (_getDisplayTitle(post).isNotEmpty) ...[
//                       const SizedBox(height: 12),
//                       Text(
//                         _getDisplayTitle(post),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                     if (post['content'] != null && post['content'].toString().trim().isNotEmpty) ...[
//                       const SizedBox(height: 6),
//                       Text(
//                         post['content'].toString(),
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 14,
//                         ),
//                         maxLines: 3,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 20,
//             right: 16,
//             child: GestureDetector(
//               behavior: HitTestBehavior.opaque,
//               onTap: () => Navigator.pop(context),
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.3),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReelActionButton({
//     required IconData icon,
//     required int count,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 28),
//           const SizedBox(height: 4),
//           Text(
//             count > 0 ? _formatCount(count) : '',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatCount(int count) {
//     if (count >= 1000000) {
//       return '${(count / 1000000).toStringAsFixed(1)}M';
//     } else if (count >= 1000) {
//       return '${(count / 1000).toStringAsFixed(1)}K';
//     }
//     return count.toString();
//   }
//
//   void scrollToReelComment(int postId, {String? commentAuthor, String? commentText, dynamic commentId}) {
//     final index = _reelsPosts.indexWhere((p) => p['id']?.toString() == postId.toString());
//     if (index != -1) {
//       if (_currentIndex != index) {
//         _pageController.jumpToPage(index);
//       }
//
//       // Open comments after frame
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//          if (mounted) {
//              String? targetKey;
//              if (commentId != null) {
//                // Exact match using ID
//                final post = _reelsPosts[index];
//                final comments = (post['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
//                // Find comment to extract exact text/author if needed, though usually passed
//                final foundComment = comments.firstWhere((c) => c['id'] == commentId, orElse: () => {});
//
//                final text = (foundComment.isNotEmpty ? foundComment['text'] : commentText)?.toString().trim() ?? "";
//                final author = (foundComment.isNotEmpty ? foundComment['author'] : commentAuthor) ?? "";
//
//                targetKey = "${postId}_${author}_${text}_$commentId";
//              } else if (commentAuthor != null && commentText != null) {
//                 targetKey = "${postId}_${commentAuthor}_${commentText.trim()}";
//              }
//              _showComments(context, _reelsPosts[index], targetCommentKey: targetKey);
//          }
//       });
//     }
//   }
//
//   void _showComments(BuildContext context, Map<String, dynamic> post, {String? targetCommentKey}) {
//      setState(() => _isCommentsOpen = true);
//
//      // Determine current post data (in case of updates)
//      final postId = post['id'] as int?;
//      final index = postId != null ? _reelsPosts.indexWhere((p) => p['id'] == postId) : -1;
//      final currentPost = index != -1 ? _reelsPosts[index] : post;
//
//      showModalBottomSheet(
//        context: context,
//        isScrollControlled: true,
//        backgroundColor: Colors.transparent,
//        barrierColor: Colors.black.withOpacity(0.01), // Transparent barrier but captures dismissing taps
//        useSafeArea: true,
//        builder: (context) => DraggableScrollableSheet(
//           initialChildSize: 0.75, // Start at 75% height
//           minChildSize: 0.5,
//           maxChildSize: 0.95,
//           builder: (_, controller) => CommentsBottomSheet(
//             post: currentPost,
//             currentUser: widget.currentUser,
//             onPostAction: (p, a, {extraData}) {
//                // Forward action to parent
//                widget.onPostAction?.call(p, a, extraData: extraData);
//
//                // If action modified the post, force a rebuild of ReelsScreen to update icons
//                if (mounted) setState(() {});
//             },
//             allUsers: widget.users,
//             scrollController: controller,
//             allowComments: widget.enableComments, // Pass it down
//           ),
//        ),
//      ).then((_) {
//        if (mounted) {
//          setState(() {
//             _isCommentsOpen = false;
//          });
//        }
//      });
//   }
//
//   int _countRootComments(List<dynamic>? comments) {
//     if (comments == null || comments.isEmpty) return 0;
//     int count = 0;
//     for (var comment in comments) {
//       if (comment is Map && comment.isNotEmpty) {
//
//         final parentId = comment['parentId'];
//
//         final isRoot = (parentId == null ||
//                         parentId == 0 ||
//                         parentId == '' ||
//                         (parentId is String && parentId.isEmpty));
//
//         if (isRoot && comment['text'] != null && comment['text'].toString().trim().isNotEmpty) {
//           count++;
//         }
//       }
//     }
//     return count;
//   }
//
//
//   void _showDeletePostDialog(BuildContext context, Map<String, dynamic> post) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(context.tr.deletePost),
//         content: Text(context.tr.deletePostConfirm),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text(context.tr.cancel),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//
//               if (widget.onPostAction != null) {
//                 widget.onPostAction!(post, 'DeletePost');
//               }
//             },
//             child: Text(context.tr.delete, style: const TextStyle(color: Color(0xFFDB2777))),
//           ),
//         ],
//       ),
//     );
//   }
// }
