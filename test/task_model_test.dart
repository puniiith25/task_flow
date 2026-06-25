import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task_model.dart';

void main() {
  group('TaskModel Serialization Tests', () {
    test('fromJson should parse correctly', () {
      final now = DateTime.now();
      final json = {
        'title': 'Test Title',
        'description': 'Test Description',
        'category': 'Work',
        'priority': 'High',
        'dueDate': now.toIso8601String(),
        'completed': true,
        'createdAt': now.toIso8601String(),
      };

      final task = TaskModel.fromJson(json, 'test-id-123');

      expect(task.id, 'test-id-123');
      expect(task.title, 'Test Title');
      expect(task.description, 'Test Description');
      expect(task.category, 'Work');
      expect(task.priority, 'High');
      expect(task.completed, true);
      expect(task.dueDate.toIso8601String(), now.toIso8601String());
    });

    test('toJson should convert correctly', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'test-id-123',
        title: 'Test Title',
        description: 'Test Description',
        category: 'Work',
        priority: 'High',
        dueDate: now,
        completed: false,
        createdAt: now,
      );

      final json = task.toJson();

      expect(json['title'], 'Test Title');
      expect(json['description'], 'Test Description');
      expect(json['category'], 'Work');
      expect(json['priority'], 'High');
      expect(json['completed'], false);
      expect(json['dueDate'], now.toIso8601String());
      expect(json['createdAt'], now.toIso8601String());
    });
  });
}
