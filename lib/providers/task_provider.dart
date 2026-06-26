import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _taskRepository;
  
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;
  Timer? _overdueCheckTimer;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TaskProvider(this._taskRepository);

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _overdueCheckTimer?.cancel();
    super.dispose();
  }

  /// Initialize tasks list with stream bindings
  void initialize(String userId) {
    _userId = userId;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    _tasksSubscription?.cancel();
    _tasksSubscription = _taskRepository.getTasks(userId).listen(
      (tasksList) {
        _tasks = tasksList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        
        // Immediate check for overdue tasks
        _checkOverdueTasks(tasksList);
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    // Start background checker
    _startOverdueCheckTimer();
  }

  /// Reset provider states when logging out
  void clear() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    _overdueCheckTimer?.cancel();
    _overdueCheckTimer = null;
    _tasks = [];
    _userId = null;
    _errorMessage = null;
  }

  void _startOverdueCheckTimer() {
    _overdueCheckTimer?.cancel();
    _overdueCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkOverdueTasks(_tasks);
    });
  }

  /// Check for overdue tasks and write notifications to Firestore in real-time
  Future<void> _checkOverdueTasks(List<TaskModel> tasksList) async {
    if (_userId == null || tasksList.isEmpty) return;
    
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final notifiedTasks = prefs.getStringList('notified_overdue_tasks') ?? [];
      final List<String> newNotifiedTasks = List.from(notifiedTasks);
      
      bool updated = false;

      for (var task in tasksList) {
        // If task is uncompleted and due date is in the past
        if (!task.completed && task.dueDate.isBefore(now)) {
          if (!notifiedTasks.contains(task.id)) {
            final title = 'Task Overdue: ${task.title}';
            final body = 'Your task in category "${task.category}" was scheduled for ${task.dueDate.toLocal()} and has passed its deadline.';

            // 1. Show immediate local banner notification
            await NotificationService().showImmediateLocalNotification(
              title: title,
              body: body,
            );

            // 2. Write to Firestore notifications collection so it syncs to Notification Center
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_userId)
                .collection('notifications')
                .add({
                  'title': title,
                  'body': body,
                  'timestamp': DateTime.now().toUtc().toIso8601String(),
                  'isRead': false,
                });

            newNotifiedTasks.add(task.id);
            updated = true;
          }
        }
      }

      if (updated) {
        await prefs.setStringList('notified_overdue_tasks', newNotifiedTasks);
      }
    } catch (e) {
      debugPrint('Error checking/syncing overdue tasks: $e');
    }
  }

  /// Create a new task
  Future<TaskModel?> addTask({
    required String title,
    required String description,
    required String category,
    required String priority,
    required DateTime dueDate,
  }) async {
    if (_userId == null) return null;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newTask = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      dueDate: dueDate,
      completed: false,
      createdAt: DateTime.now(),
    );

    try {
      await _taskRepository.addTask(_userId!, newTask);
      
      // Schedule local notification reminder if enabled
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('task_reminder_enabled') ?? true) {
        await NotificationService().scheduleTaskNotification(newTask);
      }
      
      _isLoading = false;
      return newTask;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update task attributes
  Future<bool> updateTask(TaskModel updatedTask) async {
    if (_userId == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskRepository.updateTask(_userId!, updatedTask);
      
      // Update local notification reminder state
      final prefs = await SharedPreferences.getInstance();
      
      // If task is uncompleted and rescheduled to the future, remove from notified_overdue_tasks
      if (!updatedTask.completed && updatedTask.dueDate.isAfter(DateTime.now())) {
        final notifiedTasks = prefs.getStringList('notified_overdue_tasks') ?? [];
        if (notifiedTasks.contains(updatedTask.id)) {
          notifiedTasks.remove(updatedTask.id);
          await prefs.setStringList('notified_overdue_tasks', notifiedTasks);
        }
      }
      
      if (prefs.getBool('task_reminder_enabled') ?? true) {
        await NotificationService().scheduleTaskNotification(updatedTask);
      } else {
        await NotificationService().cancelTaskNotification(updatedTask.id);
      }
      
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle task completion flag
  Future<bool> toggleTaskComplete(TaskModel task) async {
    final updated = task.copyWith(completed: !task.completed);
    return await updateTask(updated);
  }

  /// Delete a task
  Future<bool> deleteTask(String taskId) async {
    if (_userId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskRepository.deleteTask(_userId!, taskId);
      
      // Cancel scheduled local notification reminder
      await NotificationService().cancelTaskNotification(taskId);
      
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
