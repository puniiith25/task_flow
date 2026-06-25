class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category; // e.g., Work, Personal, Shopping, Health, Others
  final String priority; // Low, Medium, High
  final DateTime dueDate;
  final bool completed;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    this.completed = false,
    required this.createdAt,
  });

  /// Factory constructor to create a TaskModel from JSON document map
  factory TaskModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parseDate(dynamic date) {
      if (date is String) {
        return DateTime.parse(date);
      } else if (date is int) {
        return DateTime.fromMillisecondsSinceEpoch(date);
      }
      return DateTime.now();
    }

    return TaskModel(
      id: documentId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Others',
      priority: json['priority'] ?? 'Medium',
      dueDate: parseDate(json['dueDate']),
      completed: json['completed'] ?? false,
      createdAt: parseDate(json['createdAt']),
    );
  }

  /// Converts the TaskModel instance to a Map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this TaskModel with modified fields
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    DateTime? dueDate,
    bool? completed,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
