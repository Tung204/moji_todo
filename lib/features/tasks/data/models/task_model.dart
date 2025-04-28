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
  });
}