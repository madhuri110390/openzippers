import 'package:flutter/material.dart';
import '../screens/cart_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';

class TopSearchBar extends StatefulWidget {
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
  });

  @override
  State<TopSearchBar> createState() => _TopSearchBarState();
}

class _TopSearchBarState extends State<TopSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const pink = Color(0xFFDB2777);

    return Container(
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ── Logo / Home tap ──────────────────────────────────────────
            GestureDetector(
              onTap: widget.onHomeTap,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.bolt_rounded,
                  color: pink,
                  size: 28,
                ),
              ),
            ),

            // ── Search Field ─────────────────────────────────────────────
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasText
                        ? pink
                        : (isDark ? pink.withValues(alpha: 0.45) : Colors.transparent),
                    width: _hasText ? 1.5 : 1.0,
                  ),
                  boxShadow: _hasText
                      ? [
                    BoxShadow(
                      color: pink.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : [],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),

                child: Row(
                  children: [

                    Icon(
                      Icons.search_rounded,
                      color: _hasText ? pink : theme.hintColor,
                      size: 22,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: widget.onChanged,
                        onTap: widget.onTap,
                        cursorColor: pink,
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

                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    if (_hasText)
                      GestureDetector(

                        onTap: () {

                          _controller.clear();

                          widget.onChanged?.call('');

                        },

                        child: Container(

                          height: 22,
                          width: 22,

                          alignment: Alignment.center,

                          decoration: BoxDecoration(
                            color: theme.hintColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // ── Create Icon (Artists only) ────────────────────────────────
            if (widget.currentUser?.isArtist == true)
              _NavIconButton(
                icon: Icons.add_box_outlined,
                isDark: isDark,
                tooltip: context.tr.createPost,
                onPressed: widget.onCreateTap,
              ),

            // ── Cart Icon with badge ──────────────────────────────────────
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: widget.cartItemsNotifier ?? ValueNotifier([]),
              builder: (context, cartItems, _) {
                final count = cartItems.fold(
                    0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
                return _BadgedIconButton(
                  icon: Icons.shopping_cart_outlined,
                  badgeCount: count,
                  isDark: isDark,
                  onPressed: () {
                    if (widget.cartItemsNotifier == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr.cartNotAvailable),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartScreen(
                          cartItemsNotifier: widget.cartItemsNotifier,
                          onIncrement: widget.onIncrementCart,
                          onDecrement: widget.onDecrementCart,
                          onRemove: widget.onRemoveCart,
                          validateItemExists: widget.validateCartItemExists,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // ── Notification Bell with badge ──────────────────────────────
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: widget.notificationsNotifier ?? ValueNotifier([]),
              builder: (context, notifications, _) {
                final unreadCount =
                    notifications.where((n) => n['isRead'] != true).length;
                return _BadgedIconButton(
                  icon: Icons.notifications_outlined,
                  badgeCount: unreadCount,
                  isDark: isDark,
                  onPressed: () {
                    final currentUser = widget.currentUser;
                    final onNotificationsUpdated = widget.onNotificationsUpdated;
                    final notificationsNotifier = widget.notificationsNotifier;

                    if (currentUser != null && onNotificationsUpdated != null) {
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.tr.notificationsNotAvailable)),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 1000;
}

// ── Reusable nav icon (no badge) ────────────────────────────────────────────
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
    const pink = Color(0xFFDB2777);
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(
        icon,
        color: isDark ? pink : theme.hintColor,
        size: 24,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }
}

// ── Reusable badged icon ─────────────────────────────────────────────────────
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
    const pink = Color(0xFFDB2777);
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: isDark ? pink : theme.hintColor,
            size: 24,
          ),
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
                color: pink,
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