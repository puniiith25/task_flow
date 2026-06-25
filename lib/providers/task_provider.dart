import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _taskRepository;
  final NotificationService _notificationService;
  
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TaskProvider(this._taskRepository, this._notificationService);

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  /// Initialize tasks list with local stream bindings
  void initialize(String userId, bool isMockMode) {
    _userId = userId;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    _tasksSubscription?.cancel();
    _tasksSubscription = _taskRepository.getTasks(userId).listen(
      (tasksList) async {
        // If it's a new user and there are no tasks, seed with demo tasks
        if (tasksList.isEmpty) {
          _tasksSubscription?.cancel(); // Temporary pause subscription to seed
          await _seedDemoTasks(userId);
          initialize(userId, isMockMode); // Re-initialize to fetch seeded data
          return;
        }

        _tasks = tasksList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Reset provider states when logging out
  void clear() {
    _tasksSubscription?.cancel();
    _tasksSubscription = null;
    _tasks = [];
    _userId = null;
    _errorMessage = null;
  }

  /// Seed the repository with demo tasks on first run
  Future<void> _seedDemoTasks(String userId) async {
    final now = DateTime.now();
    final demoTasks = [
      TaskModel(
        id: 'seed-1',
        title: 'Design TaskFlow Layouts',
        description: 'Complete the Material 3 navigation structures and card components.',
        category: 'Work',
        priority: 'High',
        dueDate: now.add(const Duration(hours: 2)),
        completed: false,
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      TaskModel(
        id: 'seed-2',
        title: 'Grocery Shopping',
        description: 'Buy organic tomatoes, spinach, milk, and whole-wheat bread.',
        category: 'Shopping',
        priority: 'Low',
        dueDate: now.add(const Duration(days: 1)),
        completed: true,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      TaskModel(
        id: 'seed-3',
        title: 'Evening Jogging',
        description: 'Cardio run for 4 kilometers around the park trail.',
        category: 'Health',
        priority: 'Medium',
        dueDate: now.add(const Duration(hours: 8)),
        completed: false,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      TaskModel(
        id: 'seed-4',
        title: 'Read Coding Guidelines',
        description: 'Go through standard clean architecture documentation to review design tokens.',
        category: 'Personal',
        priority: 'Medium',
        dueDate: now.add(const Duration(days: 3)),
        completed: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    for (var task in demoTasks) {
      await _taskRepository.addTask(userId, task);
    }
  }

  /// Create a new task
  Future<bool> addTask({
    required String title,
    required String description,
    required String category,
    required String priority,
    required DateTime dueDate,
  }) async {
    if (_userId == null) return false;
    
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

    // Schedule local notification reminder
    if (dueDate.isAfter(DateTime.now())) {
      await _notificationService.scheduleTaskReminder(
        taskId: newTask.id,
        title: 'Task Due: ${newTask.title}',
        body: newTask.description.isNotEmpty ? newTask.description : 'Your task is due now!',
        scheduledTime: dueDate,
      );
    }

    try {
      await _taskRepository.addTask(_userId!, newTask);
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      await _notificationService.cancelTaskReminder(newTask.id);
      return false;
    }
  }

  /// Update task attributes
  Future<bool> updateTask(TaskModel updatedTask) async {
    if (_userId == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Re-schedule reminder notification
    await _notificationService.cancelTaskReminder(updatedTask.id);
    if (!updatedTask.completed && updatedTask.dueDate.isAfter(DateTime.now())) {
      await _notificationService.scheduleTaskReminder(
        taskId: updatedTask.id,
        title: 'Task Due: ${updatedTask.title}',
        body: updatedTask.description.isNotEmpty ? updatedTask.description : 'Your task is due now!',
        scheduledTime: updatedTask.dueDate,
      );
    }

    try {
      await _taskRepository.updateTask(_userId!, updatedTask);
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

    // Cancel notification
    await _notificationService.cancelTaskReminder(taskId);

    try {
      await _taskRepository.deleteTask(_userId!, taskId);
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
