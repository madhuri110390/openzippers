import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../screens/cart_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';
import '../viewmodels/search_viewmodel.dart';

const _kPink = Color(0xFFDB2777);

class TopSearchBar extends ConsumerStatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onThemeTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onFaqTap;
  final ValueNotifier<List<Map<String, dynamic>>>? cartItemsNotifier;
  final Function(int)? onIncrementCart;
  final Function(int)? onDecrementCart;
  final Function(int)? onRemoveCart;
  final Future<bool> Function(Map<String, dynamic>)? validateCartItemExists;
  final ValueNotifier<List<Map<String, dynamic>>>? notificationsNotifier;
  final Function(List<Map<String, dynamic>>)? onNotificationsUpdated;
  final MockUser? currentUser;
  final Function(Map<String, dynamic>)? onNotificationTap;
  final VoidCallback? onCreateTap;
  final Function(MockUser)? onUserTap;

  const TopSearchBar({
    super.key,
    this.onChanged,
    this.onTap,
    this.onSettingsTap,
    this.onThemeTap,
    this.onHomeTap,
    this.onLogoutTap,
    this.onFaqTap,
    this.cartItemsNotifier,
    this.onIncrementCart,
    this.onDecrementCart,
    this.onRemoveCart,
    this.validateCartItemExists,
    this.notificationsNotifier,
    this.onNotificationsUpdated,
    this.currentUser,
    this.onNotificationTap,
    this.onCreateTap,
    this.onUserTap,
  });

  @override
  ConsumerState<TopSearchBar> createState() => _TopSearchBarState();
}

class _TopSearchBarState extends ConsumerState<TopSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _focusNode.addListener(() {
      setState(() => _showDropdown = _focusNode.hasFocus && _hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {
      _hasText = false;
      _showDropdown = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchState = ref.watch(searchProvider);

    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Container(
            color: theme.appBarTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onHomeTap,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.bolt_rounded, color: _kPink, size: 28),
                    ),
                  ),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.15)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasText
                              ? _kPink
                              : (isDark
                              ? _kPink.withValues(alpha: 0.45)
                              : Colors.transparent),
                          width: _hasText ? 1.5 : 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: _hasText ? _kPink : theme.hintColor,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onChanged: (val) {
                                widget.onChanged?.call(val);
                                setState(() => _showDropdown =
                                    val.isNotEmpty && _focusNode.hasFocus);
                                if (val.isNotEmpty) {
                                  ref.read(searchProvider.notifier).searchUsers(val);
                                } else {
                                  ref.read(searchProvider.notifier).clear();
                                }
                              },
                              onTap: widget.onTap,
                              cursorColor: _kPink,
                              cursorWidth: 2,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: context.tr.searchUsers,
                                hintStyle: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_hasText)
                            GestureDetector(
                              onTap: _clearSearch,
                              child: Container(
                                height: 22,
                                width: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.hintColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close,
                                    size: 14, color: theme.hintColor),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (widget.currentUser?.isArtist == true)
                    _NavIconButton(
                      icon: Icons.add_box_outlined,
                      isDark: isDark,
                      tooltip: context.tr.createPost,
                      onPressed: widget.onCreateTap,
                    ),
                  Consumer(
                    builder: (context, ref, _) {
                      final cartAsync = ref.watch(cartProvider);
                      final count = cartAsync.whenOrNull(
                        data: (response) => response.data.data.itemCount,
                      ) ?? 0;
                      return _BadgedIconButton(
                        icon: Icons.shopping_cart_outlined,
                        badgeCount: count,
                        isDark: isDark,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CartScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable:
                    widget.notificationsNotifier ?? ValueNotifier([]),
                    builder: (context, notifications, _) {
                      final unreadCount =
                          notifications.where((n) => n['isRead'] != true).length;
                      return _BadgedIconButton(
                        icon: Icons.notifications_outlined,
                        badgeCount: unreadCount,
                        isDark: isDark,
                        onPressed: () {
                          final currentUser = widget.currentUser;
                          final onNotificationsUpdated =
                              widget.onNotificationsUpdated;
                          final notificationsNotifier = widget.notificationsNotifier;
                          if (currentUser != null &&
                              onNotificationsUpdated != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ValueListenableBuilder<List<Map<String, dynamic>>>(
                              valueListenable:
                              notificationsNotifier ?? ValueNotifier([]),
                              builder: (context, currentNotifications, _) {
                                return NotificationsScreen(
                                  notifications: currentNotifications,
                                  onBack: () => Navigator.pop(context),
                                  onNotificationsUpdated: onNotificationsUpdated,
                                  currentUser: currentUser,
                                  onNotificationTap: widget.onNotificationTap,
                                );
                              },
                              ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Floating dropdown ────────────────────────────────────────
          if (_showDropdown && _hasText)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                color: theme.cardColor,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: searchState.isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: _kPink, strokeWidth: 2),
                    ),
                  )
                      : searchState.users.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.person_search_outlined,
                            color: theme.hintColor, size: 20),
                        const SizedBox(width: 10),
                        Text('No users found',
                            style: TextStyle(color: theme.hintColor)),
                      ],
                    ),
                  )
                      : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          'USERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.hintColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      ...searchState.users.take(6).map<Widget>((user) {
                        return InkWell(
                          onTap: () {
                            _clearSearch();
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
                            widget.onUserTap?.call(mockUser);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: theme
                                          .textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 13, color: theme.hintColor),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final String? tooltip;
  final VoidCallback? onPressed;

  const _NavIconButton({
    required this.icon,
    required this.isDark,
    this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, color: isDark ? _kPink : theme.hintColor, size: 24),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }
}

class _BadgedIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final bool isDark;
  final VoidCallback? onPressed;

  const _BadgedIconButton({
    required this.icon,
    required this.badgeCount,
    required this.isDark,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: isDark ? _kPink : theme.hintColor, size: 24),
          onPressed: onPressed,
          splashRadius: 20,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: _kPink,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: badgeCount > 99 ? 24 : (badgeCount > 9 ? 20 : 16),
                minHeight: badgeCount > 9 ? 18 : 16,
              ),
              child: Center(
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}