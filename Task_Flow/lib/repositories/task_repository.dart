import 'dart:async';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

abstract class TaskRepository {
  Stream<List<TaskModel>> getTasks(String userId);
  Future<void> addTask(String userId, TaskModel task);
  Future<void> updateTask(String userId, TaskModel task);
  Future<void> deleteTask(String userId, String taskId);
}

class TaskRepositoryImpl implements TaskRepository {
  final FirestoreService _firestoreService = FirestoreService();

  TaskRepositoryImpl();

  @override
  Stream<List<TaskModel>> getTasks(String userId) {
    return _firestoreService.getTasks(userId);
  }

  @override
  Future<void> addTask(String userId, TaskModel task) async {
    await _firestoreService.addTask(userId, task);
  }

  @override
  Future<void> updateTask(String userId, TaskModel task) async {
    await _firestoreService.updateTask(userId, task);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    await _firestoreService.deleteTask(userId, taskId);
  }
}

class TaskException implements Exception {
  final String message;
  TaskException(this.message);

  @override
  String toString() => message;
}
