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
  String _localSearchQuery = "";

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
          (u) => u.username.toLowerCase() == widget.highlightUser!.toLowerCase() || 
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.username.trim().isEmpty) {
      return const Scaffold(body: Center(child: Text("Username missing")));
    }

    final connectionsAsync = ref.watch(connectionsProvider(widget.username));
    
    return connectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Failed to load connections", style: TextStyle(color: Colors.red))),
      data: (response) {
        final followers = response.data.followers;
        final following = response.data.following;
        final blocked = []; // Assuming blocked is handled elsewhere or empty for now

        final users = _selectedTabIndex == 0 ? followers : _selectedTabIndex == 1 ? following : blocked;

        return Container(
          color: const Color(0xFF081120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text("Connections", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Manage your followers, following and blocked users", 
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF18263D), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(child: _buildTab(theme, "Followers", followers.length.toString(), _selectedTabIndex == 0, 0)),
                      Expanded(child: _buildTab(theme, "Following", following.length.toString(), _selectedTabIndex == 1, 1)),
                      Expanded(child: _buildTab(theme, "Blocked", "0", _selectedTabIndex == 2, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFF16243B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 28, backgroundImage: NetworkImage(user.avatarUrl)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text("@${user.username}", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              children: [
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final res = await ref.read(followProvider.notifier).toggleFollow(user.id);
                                      if (res != null && mounted) {
                                        setState(() { user.isFollowing = res.data.isFollowing; });
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data.isFollowing ? "Followed successfully" : "Unfollowed successfully")));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (user.isFollowing ?? false) ? const Color(0xFF475569) : const Color(0xFFDB2777),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text((user.isFollowing ?? false) ? "Unfollow" : "Follow Back", style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final res = await ref.read(blockProvider.notifier).toggleBlock(user.id);
                                      if (res != null && mounted) {
                                        setState(() { user.isBlocked = res.data.isBlocked; });
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (user.isBlocked ?? false) ? Colors.grey : const Color(0xFFFF2D2D),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text((user.isBlocked ?? false) ? "Unblock" : "Block", style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
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

  Widget _buildTab(ThemeData theme, String label, String count, bool isActive, int index) {
    return InkWell(
      onTap: () => setState(() { _selectedTabIndex = index; _localSearchQuery = ""; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF352848) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? Border.all(color: const Color(0xFFDB2777), width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForTab(label), size: 16, color: isActive ? const Color(0xFFFF4DA6) : Colors.white),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: isActive ? const Color(0xFFFF4DA6) : Colors.white, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isActive ? const Color(0xFFDB2777) : theme.dividerColor, borderRadius: BorderRadius.circular(10)),
              child: Text(count, style: TextStyle(color: isActive ? Colors.white : theme.hintColor, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  IconData _getIconForTab(String label) {
    switch (label) {
      case "Followers": return Icons.group;
      case "Following": return Icons.person_add_alt;
      case "Blocked": return Icons.block;
      default: return Icons.folder;
    }
  }
}
