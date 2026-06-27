import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

/// Service responsible for managing notifications, including local due date reminders
/// and Firebase Cloud Messaging (FCM) push notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isFirebaseMessagingAvailable = false;

  // Stream controller to broadcast incoming foreground push notifications to providers
  final StreamController<Map<String, String>> _fcmMessageStreamController =
      StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get fcmMessageStream =>
      _fcmMessageStreamController.stream;

  /// Initialize local notifications and Firebase Cloud Messaging if available
  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Timezones for scheduled notifications
    tz.initializeTimeZones();

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationClicked,
    );

    // Create android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'taskflow_reminders',
      'Task Reminders',
      description: 'Scheduled reminders for task due dates and updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Setup Firebase Messaging if Firebase was initialized successfully
    _checkFirebaseMessagingAvailability();

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully.');
  }

  void _checkFirebaseMessagingAvailability() {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseMessagingAvailable = true;
        _setupFirebaseMessaging();
      } else {
        _isFirebaseMessagingAvailable = false;
        debugPrint('Firebase is not initialized. Running notifications in Offline Mode.');
      }
    } catch (e) {
      _isFirebaseMessagingAvailable = false;
      debugPrint('FCM is unavailable: $e. Running notifications in Offline Mode.');
    }
  }

  void _setupFirebaseMessaging() {
    // Listen to messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground message received: ${message.messageId}');
      
      final title = message.notification?.title ?? message.data['title'] ?? 'TaskFlow Alert';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      
      // Trigger a local notification banner since FCM won't show it automatically in foreground
      showImmediateLocalNotification(
        title: title,
        body: body,
      );

      // Stream it so NotificationProvider can add it to the notification center list
      _fcmMessageStreamController.add({
        'title': title,
        'body': body,
      });
    });

    // Listen to message clicks when app runs in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message clicked: ${message.messageId}');
    });

    // Check if app was opened from a terminated state via a notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM App opened from terminated state by notification: ${message.messageId}');
      }
    });
  }

  /// Request permissions for local alerts & FCM pushes
  Future<void> requestPermissions() async {
    if (kIsWeb) {
      if (_isFirebaseMessagingAvailable) {
        try {
          final messaging = FirebaseMessaging.instance;
          await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
        } catch (e) {
          debugPrint('FCM requestPermission error: $e');
        }
      }
      return;
    }

    // 1. Request Local Notifications Permission
    if (Platform.isIOS || Platform.isMacOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }

    // 2. Request FCM permissions
    if (_isFirebaseMessagingAvailable) {
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
      } catch (e) {
        debugPrint('FCM requestPermission error: $e');
      }
    }
  }

  /// Retrieve the current Firebase Messaging Token
  Future<String?> getDeviceToken() async {
    if (!_isFirebaseMessagingAvailable) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error fetching FCM Token: $e');
      return null;
    }
  }

  /// Trigger an immediate local notification
  Future<void> showImmediateLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'taskflow_reminders',
      'Task Reminders',
      channelDescription: 'Scheduled reminders for task due dates and updates',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a unique ID based on millisecond timestamp
    final id = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
    await _localNotifications.show(id, title, body, platformDetails);
  }

  /// Schedules a local notification at the task due date
  Future<void> scheduleTaskNotification(TaskModel task) async {
    // Ensure task due date is in the future
    if (task.completed || task.dueDate.isBefore(DateTime.now())) {
      // If completed or date is past, make sure we don't schedule or we cancel
      await cancelTaskNotification(task.id);
      return;
    }

    final int notificationId = task.id.hashCode & 0x7FFFFFFF;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'taskflow_reminders',
      'Task Reminders',
      channelDescription: 'Scheduled reminders for task due dates and updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Use absolute UTC time to schedule reliably across timezones
      final utcTime = tz.TZDateTime.from(task.dueDate.toUtc(), tz.UTC);

      await _localNotifications.zonedSchedule(
        notificationId,
        'Task Due: ${task.title}',
        task.description.isNotEmpty
            ? task.description
            : 'Your task is scheduled for now.',
        utcTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('Scheduled notification for task "${task.title}" at ${task.dueDate} (ID: $notificationId)');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Cancel a scheduled task notification
  Future<void> cancelTaskNotification(String taskId) async {
    final int notificationId = taskId.hashCode & 0x7FFFFFFF;
    await _localNotifications.cancel(notificationId);
    debugPrint('Cancelled notification for task ID: $taskId (ID: $notificationId)');
  }

  /// Schedules a recurring daily check-in notification at 9:00 AM
  Future<void> scheduleDailyCheckIn() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_checkin',
      'Daily Check-in',
      channelDescription: 'Daily task reminder check-in at 9:00 AM',
      importance: Importance.defaultImportance,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cancel first to avoid duplicates
    await _localNotifications.cancel(9999);

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    try {
      final utcTime = tz.TZDateTime.from(scheduledTime.toUtc(), tz.UTC);

      await _localNotifications.zonedSchedule(
        9999, // Static ID for daily check-in
        'Daily Task Check-in',
        'Good morning! You have tasks waiting for you today. Let\'s get productive!',
        utcTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Daily match at this time!
      );
      debugPrint('Scheduled recurring daily check-in at 9:00 AM');
    } catch (e) {
      debugPrint('Error scheduling daily check-in: $e');
    }
  }

  /// Cancel daily check-in notification
  Future<void> cancelDailyCheckIn() async {
    await _localNotifications.cancel(9999);
    debugPrint('Cancelled recurring daily check-in');
  }

  void _onLocalNotificationClicked(NotificationResponse response) {
    debugPrint('Local Notification clicked: ${response.payload}');
  }
}
