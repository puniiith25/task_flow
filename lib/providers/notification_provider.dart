import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json, String documentId) {
    return NotificationItem(
      id: documentId,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  String? _userId;
  StreamSubscription<List<NotificationItem>>? _notificationsSubscription;
  StreamSubscription<Map<String, String>>? _fcmSubscription;

  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _listenToFCMIncomingMessages();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _fcmSubscription?.cancel();
    super.dispose();
  }

  /// Initialize real-time sync with Firestore for notifications
  void initialize(String userId) {
    _userId = userId;
    _notificationsSubscription?.cancel();
    
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationItem.fromJson(doc.data(), doc.id);
          }).toList();
        })
        .listen((items) {
          _notifications = items;
          notifyListeners();
        }, onError: (e) {
          debugPrint('Error loading notifications: $e');
        });
  }

  /// Reset provider state when logging out
  void clear() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    _notifications = [];
    _userId = null;
  }

  /// Listen to real-time foreground messages streamed from NotificationService
  void _listenToFCMIncomingMessages() {
    _fcmSubscription?.cancel();
    _fcmSubscription = NotificationService().fcmMessageStream.listen((messageData) {
      addNotification(
        messageData['title'] ?? 'New Alert',
        messageData['body'] ?? '',
      );
    });
  }

  /// Add a new notification in Firestore (e.g. from due date alarm or push message)
  Future<void> addNotification(String title, String body) async {
    if (_userId == null) return;
    
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .doc();

      final newItem = NotificationItem(
        id: docRef.id,
        title: title,
        body: body,
        timestamp: DateTime.now(),
      );

      await docRef.set(newItem.toJson());
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  /// Toggle single notification read status
  Future<void> markAsRead(String id) async {
    if (_userId == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null || _notifications.isEmpty) return;
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false);
          
      final querySnapshot = await collection.get();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Clear all notification history
  Future<void> clearAll() async {
    if (_userId == null || _notifications.isEmpty) return;
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('notifications');
          
      final querySnapshot = await collection.get();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }
}
