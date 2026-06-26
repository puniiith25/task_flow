import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of all tasks for a specific user
  Stream<List<TaskModel>> getTasks(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Adds a task to Firestore
  Future<void> addTask(String userId, TaskModel task) async {
    final map = task.toJson();
    await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .set(map);
  }

  /// Updates an existing task in Firestore
  Future<void> updateTask(String userId, TaskModel task) async {
    final map = task.toJson();
    await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .update(map);
  }

  /// Deletes a task from Firestore
  Future<void> deleteTask(String userId, String taskId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
}
