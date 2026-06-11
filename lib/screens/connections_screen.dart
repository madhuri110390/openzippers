import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';
import '../providers/block_provider.dart';
import '../providers/connections_provider.dart';
import '../providers/follow_provider.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  final List<MockUser> users;
  final String searchQuery;
  final List<Map<String, dynamic>> posts;
  final Function(Map<String, dynamic>, String) onPostAction;
  final Function(MockUser, String)? onUserAction;
  final Function(MockUser)? onUserTap;
  final String username;
  final String? highlightUser;

  const ConnectionsScreen({
    super.key,
    required this.users,
    required this.username,
    required this.posts,
    required this.onPostAction,
    this.searchQuery = "",
    this.onUserAction,
    this.onUserTap,
    this.highlightUser,
  });

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  int _selectedTabIndex = 0;
  final Set<int> _loadingFollowIds = {};
  final Set<int> _loadingBlockIds = {};

  // Local override maps — instantly reflect API results before server refetch
  final Map<int, bool> _followOverrides = {};
  final Map<int, bool> _blockOverrides = {};

  @override
  void initState() {
    super.initState();
    _checkHighlightUser();
  }

  @override
  void didUpdateWidget(ConnectionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightUser != oldWidget.highlightUser) {
      _checkHighlightUser();
    }
  }

  void _checkHighlightUser() {
    if (widget.highlightUser != null) {
      try {
        final user = widget.users.firstWhere(
              (u) =>
          u.username.toLowerCase() == widget.highlightUser!.toLowerCase() ||
              u.name.toLowerCase() == widget.highlightUser!.toLowerCase(),
        );
        if (user.type == 'follower' || user.type == 'mutual') {
          setState(() => _selectedTabIndex = 0);
        } else if (user.type == 'following') {
          setState(() => _selectedTabIndex = 1);
        } else if (user.type == 'blocked') {
          setState(() => _selectedTabIndex = 2);
        }
      } catch (_) {}
    }
  }

  bool _isBlockedNow(dynamic u) =>
      _blockOverrides[u.id as int] ?? (u.isBlocked == true);

  bool _isFollowingNow(dynamic u) =>
      _followOverrides[u.id as int] ?? (u.isFollowing == true);

  bool _wasOriginallyFollowerOnly(dynamic u, List<dynamic> allFollowing) =>
      !allFollowing.any((f) => (f.id as int) == (u.id as int));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.username.trim().isEmpty) {
      return const Scaffold(body: Center(child: Text("Username missing")));
    }

    final connectionsAsync = ref.watch(connectionsProvider(widget.username));

    return connectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        debugPrint('CONNECTIONS ERROR: $e\n$st');
        return Center(
            child: Text("Error: $e",
                style: const TextStyle(color: Colors.red)));
      },
      data: (response) {
        // Server lists
        final allFollowers = response.data.followers;
        final allFollowing = response.data.following;
        final serverBlocked = response.data.blocked;

        // ── Followers: not blocked, not just-followed-back ──
        final followers = allFollowers.where((u) {
          if (_isBlockedNow(u)) return false;
          final weJustFollowedBack = _followOverrides[u.id as int] == true &&
              _wasOriginallyFollowerOnly(u, allFollowing);
          return !weJustFollowedBack;
        }).toList();

        // ── Following: original + just-followed-back, minus blocked ──
        final Map<int, dynamic> followingMap = {};
        for (final u in allFollowing) {
          if (!_isBlockedNow(u)) followingMap[u.id as int] = u;
        }
        for (final u in allFollowers) {
          if (!_isBlockedNow(u) &&
              _followOverrides[u.id as int] == true &&
              _wasOriginallyFollowerOnly(u, allFollowing)) {
            followingMap[u.id as int] = u;
          }
        }
        final following = followingMap.values.toList();

        // ── Blocked: server blocked list + local overrides added,
        //            minus anyone we just unblocked locally ──
        final Map<int, dynamic> blockedMap = {};
        // Start with server blocked list
        for (final u in serverBlocked) {
          blockedMap[u.id as int] = u;
        }
        // Add anyone we just blocked from followers/following
        for (final u in [...allFollowers, ...allFollowing]) {
          if (_blockOverrides[u.id as int] == true) {
            blockedMap[u.id as int] = u;
          }
        }
        // Remove anyone we just unblocked
        _blockOverrides.forEach((id, isBlocked) {
          if (!isBlocked) blockedMap.remove(id);
        });
        final blocked = blockedMap.values.toList();

        final users = _selectedTabIndex == 0
            ? followers
            : _selectedTabIndex == 1
            ? following
            : blocked;

        return Container(
          color: const Color(0xFF081120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text("Connections",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  "Manage your followers, following and blocked users",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                ),
                const SizedBox(height: 24),
                // ── Tab bar ──────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF18263D),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildTab(theme, "Followers",
                              response.data.counts.followers.toString(),
                              _selectedTabIndex == 0, 0)),
                      Expanded(
                          child: _buildTab(theme, "Following",
                              response.data.counts.following.toString(),
                              _selectedTabIndex == 1, 1)),
                      Expanded(
                          child: _buildTab(theme, "Blocked",
                              (blocked.length).toString(),
                              _selectedTabIndex == 2, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // ── User list ────────────────────────────────────────────────
                Expanded(
                  child: users.isEmpty
                      ? Center(
                    child: Text(
                      _selectedTabIndex == 0
                          ? "No followers yet"
                          : _selectedTabIndex == 1
                          ? "Not following anyone"
                          : "No blocked users",
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 15),
                    ),
                  )
                      : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final id = user.id as int;
                      final isFollowLoading =
                      _loadingFollowIds.contains(id);
                      final isBlockLoading =
                      _loadingBlockIds.contains(id);
                      final isFollowing = _isFollowingNow(user);
                      final isBlocked = _isBlockedNow(user);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFF16243B),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white10)),
                        child: Row(
                          children: [
                            CircleAvatar(
                                radius: 28,
                                backgroundImage:
                                NetworkImage(user.avatarUrl)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(user.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text("@${user.username}",
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Follow/Unfollow — hidden in Blocked tab
                                if (_selectedTabIndex != 2) ...[
                                  _actionButton(
                                    label: isFollowing
                                        ? "Unfollow"
                                        : "Follow Back",
                                    color: isFollowing
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFDB2777),
                                    isLoading: isFollowLoading,
                                    onTap: () =>
                                        _handleFollow(user, allFollowing),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                // Block / Unblock
                                // In Blocked tab always show Unblock
                                _actionButton(
                                  label: (_selectedTabIndex == 2 || isBlocked)
                                      ? "Unblock"
                                      : "Block",
                                  color: (_selectedTabIndex == 2 || isBlocked)
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFFFF2D2D),
                                  isLoading: isBlockLoading,
                                  onTap: () => _handleBlock(user),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Follow handler ──────────────────────────────────────────────────────────
  Future<void> _handleFollow(dynamic user, List<dynamic> allFollowing) async {
    final id = user.id as int;
    if (_loadingFollowIds.contains(id)) return;
    setState(() => _loadingFollowIds.add(id));
    try {
      final res = await ref.read(followProvider.notifier).toggleFollow(id);
      if (res != null && mounted) {
        final didFollow = res.data.isFollowing;
        final wasFollowerOnly = _wasOriginallyFollowerOnly(user, allFollowing);
        setState(() {
          _followOverrides[id] = didFollow;
          if (didFollow && wasFollowerOnly) _selectedTabIndex = 1;
        });
        // Invalidate so server refetch gets correct list
        ref.invalidate(connectionsProvider(widget.username));
        // Clear override after short delay — server data is now the truth
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _followOverrides.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(didFollow
                ? "Followed successfully"
                : "Unfollowed successfully")));
      }
    } catch (e, st) {
      debugPrint('FOLLOW ERROR: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loadingFollowIds.remove(id));
    }
  }

  // ── Block handler ───────────────────────────────────────────────────────────
  Future<void> _handleBlock(dynamic user) async {
    final id = user.id as int;
    if (_loadingBlockIds.contains(id)) return;
    setState(() => _loadingBlockIds.add(id));
    try {
      final res = await ref.read(blockProvider.notifier).toggleBlock(id);
      if (res != null && mounted) {
        final didBlock = res.data.isBlocked;
        setState(() {
          _blockOverrides[id] = didBlock;
          if (didBlock) _selectedTabIndex = 2;
          if (!didBlock && _selectedTabIndex == 2) _selectedTabIndex = 0;
        });
        // Invalidate so server refetch gets correct list
        ref.invalidate(connectionsProvider(widget.username));
        // Clear override after short delay — server data is now the truth
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _blockOverrides.remove(id));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.message)));
      }
    } catch (e, st) {
      debugPrint('BLOCK ERROR: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loadingBlockIds.remove(id));
    }
  }

  // ── Reusable button ─────────────────────────────────────────────────────────
  Widget _actionButton({
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 44,
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey.shade700 : color,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
            : Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Tab builder ─────────────────────────────────────────────────────────────
  Widget _buildTab(
      ThemeData theme, String label, String count, bool isActive, int index) {
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF352848) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: const Color(0xFFDB2777), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForTab(label),
                size: 16,
                color: isActive ? const Color(0xFFFF4DA6) : Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? const Color(0xFFFF4DA6) : Colors.white,
                    fontSize: 12,
                    fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDB2777)
                      : theme.dividerColor,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(count,
                  style: TextStyle(
                      color: isActive ? Colors.white : theme.hintColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  IconData _getIconForTab(String label) {
    switch (label) {
      case "Followers":
        return Icons.group;
      case "Following":
        return Icons.person_add_alt;
      case "Blocked":
        return Icons.block;
      default:
        return Icons.folder;
    }
  }
}