import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? title;

  @HiveField(2)
  String? note;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  String? priority; // e.g., "High", "Medium", "Low"

  @HiveField(5)
  String? project;

  @HiveField(6)
  List<String>? tags;

  @HiveField(7)
  int? estimatedPomodoros;

  @HiveField(8)
  int? completedPomodoros;

  @HiveField(9) // Thêm trường category
  String? category;

  Task({
    this.id,
    this.title,
    this.note,
    this.dueDate,
    this.priority,
    this.project,
    this.tags,
    this.estimatedPomodoros,
    this.completedPomodoros,
    this.category,
  });
  // Thêm phương thức copyWith
  Task copyWith({
    int? id,
    String? title,
    String? note,
    DateTime? dueDate,
    String? priority,
    String? project,
    List<String>? tags,
    int? estimatedPomodoros,
    int? completedPomodoros,
    String? category, // Thêm trường category để hỗ trợ phân loại task
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      project: project ?? this.project,
      tags: tags ?? this.tags,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      category: category ?? this.category,
    );
  }
}