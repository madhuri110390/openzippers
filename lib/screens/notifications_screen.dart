import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';

class NotificationsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onBack;
  final Function(List<Map<String, dynamic>>) onNotificationsUpdated;
  final MockUser currentUser;
  final Function(Map<String, dynamic>)? onNotificationTap;

  const NotificationsScreen({
    super.key,
    required this.notifications,
    required this.onBack,
    required this.onNotificationsUpdated,
    required this.currentUser,
    this.onNotificationTap,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _localNotifications = [];

  bool _listsEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      final n1 = list1[i];
      final n2 = list2[i];
      // Compare key fields
      if (n1['type'] != n2['type'] || 
          n1['message'] != n2['message']) {
        return false;
      }
      // Check read status
      if (n1['isRead'] != n2['isRead']) return false;

      // Properly compare timestamps (DateTime objects need special handling)
      final ts1 = n1['timestamp'];
      final ts2 = n2['timestamp'];
      DateTime? dt1, dt2;
      
      if (ts1 is DateTime) {
        dt1 = ts1;
      } else if (ts1 is String) {
        dt1 = DateTime.tryParse(ts1);
      } else if (ts1 != null) {
        dt1 = DateTime.tryParse(ts1.toString());
      }
      
      if (ts2 is DateTime) {
        dt2 = ts2;
      } else if (ts2 is String) {
        dt2 = DateTime.tryParse(ts2);
      } else if (ts2 != null) {
        dt2 = DateTime.tryParse(ts2.toString());
      }
      
      if (dt1 == null && dt2 == null) continue;
      if (dt1 == null || dt2 == null) return false;
      if (dt1.compareTo(dt2) != 0) return false;
    }
    return true;
  }

  void _sortNotifications() {
    _localNotifications.sort((a, b) {
      try {
        DateTime? timestampA;
        DateTime? timestampB;
        
        final tsA = a['timestamp'];
        final tsB = b['timestamp'];
        
        if (tsA is DateTime) {
          timestampA = tsA;
        } else if (tsA is String) {
          timestampA = DateTime.tryParse(tsA);
        } else if (tsA != null) {
          timestampA = DateTime.tryParse(tsA.toString());
        }
        
        if (tsB is DateTime) {
          timestampB = tsB;
        } else if (tsB is String) {
          timestampB = DateTime.tryParse(tsB);
        } else if (tsB != null) {
          timestampB = DateTime.tryParse(tsB.toString());
        }
        
        // If both are null, maintain order
        if (timestampA == null && timestampB == null) return 0;
        
        // Put nulls at the end (oldest)
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;
        
        // Newest first (descending order) - most recent timestamp comes first
        // timestampB.compareTo(timestampA) means:
        // if timestampB > timestampA, return positive (B comes before A)
        final comparison = timestampB.compareTo(timestampA);
        return comparison;
      } catch (e) {
        // On error, maintain original order
        return 0;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _localNotifications = List.from(widget.notifications);
    _sortNotifications();
  }

  @override
  void didUpdateWidget(NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always update local notifications when widget updates
    // Check if notifications actually changed
    if (widget.notifications.length != _localNotifications.length ||
        !_listsEqual(widget.notifications, _localNotifications)) {
      _localNotifications = List.from(widget.notifications);
      _sortNotifications(); // Sort immediately when notifications update
      // Force rebuild to show updated list
      if (mounted) {
        setState(() {});
      }
    } else {
      // Even if lists are equal, ensure they're sorted correctly
      _sortNotifications();
      if (mounted) {
        setState(() {});
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'reply':
        return Icons.reply;
      case 'cart':
        return Icons.shopping_cart;
      case 'tip':
        return Icons.monetization_on;
      case 'subscription':
        return Icons.person_add;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return const Color(0xFFDB2777);
      case 'comment':
        return Colors.blue;
      case 'reply':
        return Colors.green;
      case 'cart':
        return const Color(0xFFDB2777);
      case 'tip':
        return Colors.amber;
      case 'subscription':
        return Colors.purple;
      case 'message':
        return Colors.teal;
      default:
        return const Color(0xFFDB2777);
    }
  }

  String _getNotificationTitle(BuildContext context, String type) {
    switch (type) {
      case 'like':
        return context.tr.likedYourPost;
      case 'comment':
        return context.tr.commentedOnYourPost;
      case 'reply':
        return context.tr.repliedToYourComment;
      case 'cart':
        return context.tr.itemAddedToCart;
      case 'tip':
        return context.tr.tipReceived;
      case 'subscription':
        return context.tr.newSubscriber;
      case 'message':
        return context.tr.newMessage;
      default:
        return context.tr.notification;
    }
  }

  void _clearNotifications() {
    if (_localNotifications.isEmpty && widget.notifications.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          context.tr.clearAll,
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          context.tr.clearAllNotifications,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _localNotifications = [];
              });
              widget.onNotificationsUpdated([]);
            },
            child: Text(
              context.tr.delete,
              style: const TextStyle(color: Color(0xFFDB2777)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Always use the latest notifications from widget and ensure they're sorted
    // Update local notifications if they differ (check length first for performance)
    if (widget.notifications.length != _localNotifications.length) {
      _localNotifications = List.from(widget.notifications);
      _sortNotifications(); // Sort immediately
    } else if (!_listsEqual(widget.notifications, _localNotifications)) {
      _localNotifications = List.from(widget.notifications);
      _sortNotifications(); // Sort immediately
    } else {
      // Even if equal, ensure sorting is correct
      _sortNotifications();
    }
    
    // Ensure notifications are properly sorted (newest first)
    final notifications = _localNotifications.isNotEmpty ? _localNotifications : widget.notifications;
    
    // Normalize all timestamps to DateTime objects for consistent display
    final normalizedNotifications = notifications.map((n) {
      final normalized = Map<String, dynamic>.from(n);
      if (normalized['timestamp'] is! DateTime) {
        final ts = normalized['timestamp'];
        if (ts is String) {
          normalized['timestamp'] = DateTime.tryParse(ts) ?? DateTime.now();
        } else if (ts != null) {
          normalized['timestamp'] = DateTime.tryParse(ts.toString()) ?? DateTime.now();
        } else {
          // Try alternative keys commonly found in mocks/API
          final altTs = normalized['time'] ?? normalized['date'] ?? normalized['created_at'];
          if (altTs != null) {
             if (altTs is String) {
                normalized['timestamp'] = DateTime.tryParse(altTs) ?? DateTime.now();
             } else {
                normalized['timestamp'] = DateTime.now();
             }
          } else {
             normalized['timestamp'] = DateTime.now();
          }
        }
      }
      return normalized;
    }).toList();
    
    // Ensure normalized notifications are sorted (newest first)
    // Sort in descending order: newest timestamp comes first (index 0)
    normalizedNotifications.sort((a, b) {
      try {
        final tsA = a['timestamp'] as DateTime?;
        final tsB = b['timestamp'] as DateTime?;
        if (tsA == null && tsB == null) return 0;
        if (tsA == null) return 1; // Put nulls at end
        if (tsB == null) return -1; // Put nulls at end
        
        // Compare: if tsB > tsA, return positive (B comes before A = newest first)
        // This ensures the latest notification is at index 0 (top of list)
        final comparison = tsB.compareTo(tsA);
        return comparison;
      } catch (e) {
        debugPrint("Error sorting normalized notifications: $e");
        return 0;
      }
    });
    
    // Debug: Print first few timestamps to verify sorting
    if (normalizedNotifications.isNotEmpty) {
      debugPrint("Notification order check - First (should be newest): ${normalizedNotifications[0]['timestamp']}");
      if (normalizedNotifications.length > 1) {
        debugPrint("Notification order check - Second: ${normalizedNotifications[1]['timestamp']}");
      }
    }
    
    final unreadCount = normalizedNotifications.where((n) => n['isRead'] != true).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
          color: theme.textTheme.bodyLarge?.color,
        ),
        title: Text(
          context.tr.notifications,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '$unreadCount ${context.tr.unread}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          if (normalizedNotifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: context.tr.clearAll,
              onPressed: _clearNotifications,
              color: theme.textTheme.bodyLarge?.color,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: normalizedNotifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: theme.hintColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr.noNotifications,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.allCaughtUp,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              // Ensure we're displaying from index 0 (newest first)
              // ListView.builder displays items in order: index 0 is first (top)
              itemCount: normalizedNotifications.length,
              itemBuilder: (context, index) {
                // Index 0 should be the newest notification (after sorting)
                final notification = normalizedNotifications[index];
                final isRead = notification['isRead'] == true;
                final type = notification['type'] as String? ?? 'notification';
                
                // Dynamic Title and Message Generation
                String title;
                String message;
                final tr = context.tr;

                switch (type) {
                  case 'like':
                    final likerName = notification['user'] as String? ?? '';
                    final postTitle = notification['postTitle'] as String? ?? '';
                    final count = notification['likeCount'] as int? ?? 0;
                    
                    if (likerName.isNotEmpty) {
                      title = "$likerName ${tr.likedYourPost.toLowerCase()}";
                      message = postTitle.isNotEmpty ? postTitle : (notification['message'] as String? ?? '');
                    } else {
                      title = tr.likedYourPost;
                      if (count > 1 && postTitle.isNotEmpty) {
                         message = tr.likeNotification(count, postTitle);
                      } else {
                         message = notification['message'] as String? ?? '';
                      }
                    }
                    break;
                  case 'comment':
                     title = tr.commentedOnYourPost;
                     final author = notification['commentAuthor'] as String? ?? '';
                     final comment = notification['commentText'] as String? ?? '';
                     // Use specific author if we have it, otherwise fallback to generic message
                     if (author.isNotEmpty && comment.isNotEmpty) {
                       final commentPreview = comment.length > 50 ? '${comment.substring(0, 50)}...' : comment;
                       message = tr.commentNotification(author, commentPreview);
                     } else {
                       message = notification['message'] as String? ?? '';
                     }
                    break;
                  case 'reply':
                     title = tr.repliedToYourComment;
                     final author = notification['commentAuthor'] as String? ?? '';
                     final comment = notification['commentText'] as String? ?? '';
                     if (author.isNotEmpty && comment.isNotEmpty) {
                       final commentPreview = comment.length > 50 ? '${comment.substring(0, 50)}...' : comment;
                       message = tr.replyNotification(author, commentPreview);
                     } else {
                        message = notification['message'] as String? ?? '';
                     }
                    break;
                  case 'cart':
                    title = tr.itemAddedToCart;
                    message = notification['message'] as String? ?? '';
                    break;
                  default:
                    title = _getNotificationTitle(context, type);
                    message = notification['message'] as String? ?? '';
                }

                
                // Properly parse timestamp - handle DateTime, String, or null
                DateTime timestamp;
                final ts = notification['timestamp'];
                if (ts is DateTime) {
                  timestamp = ts;
                } else if (ts is String) {
                  timestamp = DateTime.tryParse(ts) ?? DateTime.now();
                } else if (ts != null) {
                  timestamp = DateTime.tryParse(ts.toString()) ?? DateTime.now();
                } else {
                  timestamp = DateTime.now();
                }
                
                final timeAgo = _getTimeAgo(timestamp);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isRead ? theme.cardColor : theme.cardColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRead
                          ? theme.dividerColor.withValues(alpha: 0.5)
                          : const Color(0xFFDB2777).withValues(alpha: 0.3),
                      width: isRead ? 1 : 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Handle the notification tap (handler will close screen and navigate)
                      widget.onNotificationTap?.call(notification);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(type).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(type),
                          color: _getNotificationColor(type),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: _buildMessageSpans(context, message, type, notification),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                          if (!isRead) ...[
                             const SizedBox(height: 6),
                             Container(
                               width: 8,
                               height: 8,
                               decoration: const BoxDecoration(
                                 color: Color(0xFFDB2777),
                                 shape: BoxShape.circle,
                               ),
                             )
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final tr = context.tr;

    // Handle future dates (clock skew or immediate creation) - show "Just now"
    if (difference.isNegative || difference.inSeconds < 5) {
      return tr.justNow;
    }

    // Facebook/Instagram style time formatting
    if (difference.inDays > 7) {
      final monthName = tr.monthShort(timestamp.month);
      if (difference.inDays > 365) {
        return '$monthName ${timestamp.day}, ${timestamp.year}';
      } else {
        return '$monthName ${timestamp.day}';
      }
    } else if (difference.inDays > 0) {
      return '${difference.inDays}${tr.dayShort}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${tr.hourShort}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${tr.minuteShort}';
    } else {
      return '${difference.inSeconds}s';
    }
  }

  List<InlineSpan> _buildMessageSpans(BuildContext context, String message, String type, Map<String, dynamic> notification) {
    List<InlineSpan> spans = [];
    final pinkStyle = const TextStyle(color: Color(0xFFDB2777), fontWeight: FontWeight.bold);
    
    // Helper to find and highlight a name in the message
    void highlightName(String name) {
       final lowerMessage = message.toLowerCase();
       final lowerName = name.toLowerCase();
       final startIndex = lowerMessage.indexOf(lowerName);
       
       if (startIndex != -1) {
          if (startIndex > 0) {
             spans.add(TextSpan(text: message.substring(0, startIndex)));
          }
          spans.add(TextSpan(text: message.substring(startIndex, startIndex + name.length), style: pinkStyle));
          if (startIndex + name.length < message.length) {
             spans.add(TextSpan(text: message.substring(startIndex + name.length)));
          }
       } else {
          spans.add(TextSpan(text: message));
       }
    }

    if (type == 'comment' || type == 'reply') {
       final author = notification['commentAuthor'] as String?;
       if (author != null && author.isNotEmpty) {
           highlightName(author);
           return spans;
       }
    } else if (type == 'subscription') {
       final user = notification['user'] as String?;
       if (user != null && user.isNotEmpty) {
           highlightName(user);
           return spans;
       } else {
           // Try parsing from message if user field not present in some legacy mocks
           final parts = message.split(" has subscribed");
           if (parts.length > 1) {
              highlightName(parts.first);
              return spans;
           }
       }
    } else if (type == 'message') {
       final user = notification['user'] as String?;
       if (user != null && user.isNotEmpty) {
           highlightName(user);
           return spans;
       } else {
           // Try parsing from message "You have a new unread message from X."
           final parts = message.split("from ");
           if (parts.length > 1) {
              final possibleName = parts.last.replaceAll('.', '').trim();
              highlightName(possibleName);
              return spans;
           }
       }
    }
    
    // Default fallback
    spans.add(TextSpan(text: message));
    return spans;
  }
}



