import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

abstract class TaskRepository {
  Stream<List<TaskModel>> getTasks(String userId);
  Future<void> addTask(String userId, TaskModel task);
  Future<void> updateTask(String userId, TaskModel task);
  Future<void> deleteTask(String userId, String taskId);
}

class TaskRepositoryImpl implements TaskRepository {
  final StreamController<List<TaskModel>> _tasksStreamController =
      StreamController<List<TaskModel>>.broadcast();
  
  List<TaskModel> _cachedTasks = [];
  String? _currentUserId;

  TaskRepositoryImpl() {
    // Stream controller initialization
  }

  Future<void> _loadLocalTasks(String userId) async {
    _currentUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJson = prefs.getString('tasks_$userId');
      if (tasksJson != null) {
        final List<dynamic> decodedList = jsonDecode(tasksJson);
        _cachedTasks = decodedList.map((item) {
          return TaskModel.fromJson(Map<String, dynamic>.from(item), item['id'] ?? '');
        }).toList();
      } else {
        _cachedTasks = [];
      }
      _sortTasks();
      _tasksStreamController.add(_cachedTasks);
    } catch (_) {
      _cachedTasks = [];
      _tasksStreamController.add(_cachedTasks);
    }
  }

  Future<void> _saveLocalTasks() async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final listToEncode = _cachedTasks.map((t) {
        final map = t.toJson();
        map['id'] = t.id; // Include id since json representation needs it
        return map;
      }).toList();
      await prefs.setString('tasks_$_currentUserId', jsonEncode(listToEncode));
    } catch (_) {}
  }

  void _sortTasks() {
    _cachedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Stream<List<TaskModel>> getTasks(String userId) {
    _loadLocalTasks(userId);
    return _tasksStreamController.stream;
  }

  @override
  Future<void> addTask(String userId, TaskModel task) async {
    if (_currentUserId != userId) {
      await _loadLocalTasks(userId);
    }
    _cachedTasks.add(task);
    _sortTasks();
    _tasksStreamController.add(_cachedTasks);
    await _saveLocalTasks();
  }

  @override
  Future<void> updateTask(String userId, TaskModel task) async {
    if (_currentUserId != userId) {
      await _loadLocalTasks(userId);
    }
    final index = _cachedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _cachedTasks[index] = task;
      _sortTasks();
      _tasksStreamController.add(_cachedTasks);
      await _saveLocalTasks();
    } else {
      throw Exception('Task not found.');
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    if (_currentUserId != userId) {
      await _loadLocalTasks(userId);
    }
    _cachedTasks.removeWhere((t) => t.id == taskId);
    _tasksStreamController.add(_cachedTasks);
    await _saveLocalTasks();
  }
}

class TaskException implements Exception {
  final String message;
  TaskException(this.message);

  @override
  String toString() => message;
}
