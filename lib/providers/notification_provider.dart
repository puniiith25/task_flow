import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = [];

  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadMockNotifications();
  }

  void _loadMockNotifications() {
    final now = DateTime.now();
    _notifications = [
      NotificationItem(
        id: 'notif-1',
        title: 'Task Overdue: Design TaskFlow Mockup',
        body: 'Your task was scheduled for 2 hours ago. Make sure to update its status!',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: 'notif-2',
        title: 'Daily Task Check-in',
        body: 'Good morning! You have 3 pending tasks scheduled for today.',
        timestamp: now.subtract(const Duration(hours: 12)),
        isRead: true,
      ),
      NotificationItem(
        id: 'notif-3',
        title: 'Welcome to TaskFlow',
        body: 'Get started by creating categories, selecting priorities, and scheduling reminders.',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  /// Add a new notification programmatically
  void addNotification(String title, String body) {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, newItem);
    notifyListeners();
  }

  /// Toggle single notification read status
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  /// Clear all notification history
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
