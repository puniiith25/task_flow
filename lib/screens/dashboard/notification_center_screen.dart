import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/notification_provider.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('d MMM, h:mm a').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final notifications = notifProvider.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'mark_read') {
                  notifProvider.markAllAsRead();
                } else if (val == 'clear') {
                  notifProvider.clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_chat_read_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Clear all', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = notifications[index];
                
                // Customize leading icon based on title keywords
                IconData iconData = Icons.notifications_none_rounded;
                Color iconColor = AppTheme.primarySeedColor;
                
                if (item.title.contains('Overdue')) {
                  iconData = Icons.warning_amber_rounded;
                  iconColor = Colors.redAccent;
                } else if (item.title.contains('Welcome')) {
                  iconData = Icons.celebration_rounded;
                  iconColor = AppTheme.secondaryColor;
                }

                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  onDismissed: (direction) {
                    notifProvider.deleteNotification(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notification deleted'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: ListTile(
                    onTap: () {
                      notifProvider.markAsRead(item.id);
                    },
                    tileColor: item.isRead 
                        ? Colors.transparent 
                        : (isDark ? const Color(0xFF374151).withValues(alpha: 0.2) : AppTheme.primarySeedColor.withValues(alpha: 0.05)),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatTime(item.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'No notifications to show here.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
