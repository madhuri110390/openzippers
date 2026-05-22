import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';

class SuggestionsScreen extends StatefulWidget {
  final List<MockUser> users;
  final MockUser currentUser;
  final Function(MockUser, String)? onUserAction;
  
  const SuggestionsScreen({
    super.key, 
    required this.users, 
    required this.currentUser,
    this.onUserAction,
  });

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    

    final filteredUsers = widget.users.where((u) => u.username != widget.currentUser.username).toList();
    

    final suggestedUsers = filteredUsers.where((u) => u.type != 'following' && !u.isSubscribed).take(10).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Suggestions",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    "Discover creators you might like",
                    style: TextStyle(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 380,
              child: PageView.builder(
                controller: _pageController,
                itemCount: suggestedUsers.length,
                itemBuilder: (context, index) {
                  final user = suggestedUsers[index];
                  return _buildSuggestionSlide(user);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Text(
                "Recent Activities",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                    final user = filteredUsers[index % filteredUsers.length];
                    final isFollowing = user.type == 'following';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user.avatar),
                      ),
                      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.username, style: TextStyle(color: theme.hintColor)),
                      trailing: (!isFollowing && !user.isSubscribed) || (isFollowing && !user.isSubscribed) ? ElevatedButton(
                        onPressed: () {
                          widget.onUserAction?.call(user, isFollowing ? 'Unfollow' : 'Follow');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? theme.dividerColor : const Color(0xFFDB2777),
                          foregroundColor: isFollowing ? theme.textTheme.bodyMedium?.color : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(isFollowing ? context.tr.following : context.tr.follow, style: const TextStyle(fontSize: 12)),
                      ) : null,
                    );
                },
                childCount: filteredUsers.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSuggestionSlide(MockUser user) {
    final theme = Theme.of(context);
    final isFollowing = user.type == 'following';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 5, // Increased flex for image
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                user.avatar,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFDB2777).withOpacity(0.1),
                  child: const Icon(Icons.person, size: 80, color: Color(0xFFDB2777)),
                ),
              ),
            ),
          ),
          // Wrap info in a layout that handles overflow
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.username,
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: !user.isSubscribed ? ElevatedButton(
                        onPressed: () {
                          widget.onUserAction?.call(user, isFollowing ? 'Unfollow' : 'Follow');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? theme.dividerColor : const Color(0xFFDB2777),
                          foregroundColor: isFollowing ? theme.textTheme.bodyMedium?.color : Colors.white,
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isFollowing ? context.tr.following : context.tr.follow, style: const TextStyle(fontSize: 13)),
                      ) : const SizedBox(),
                    ),
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
