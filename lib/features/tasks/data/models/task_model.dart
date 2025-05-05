import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? priority;

  @HiveField(5)
  String? project;

  @HiveField(6)
  List<String>? tags;

  @HiveField(7)
  int? estimatedPomodoros;

  @HiveField(8)
  int? completedPomodoros;

  @HiveField(9)
  String? category;

  @HiveField(10)
  bool? isPomodoroActive;

  @HiveField(11)
  int? remainingPomodoroSeconds;

  @HiveField(12)
  bool? isCompleted;

  @HiveField(13)
  List<Map<String, dynamic>>? subtasks;

  @HiveField(14)
  String? userId;

  @HiveField(15)
  DateTime? createdAt; // Thêm trường createdAt để lưu thời gian tạo task

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
    this.isPomodoroActive = false,
    this.remainingPomodoroSeconds,
    this.isCompleted = false,
    this.subtasks,
    this.userId,
    this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String?,
      note: json['note'] as String?,
      dueDate: json['dueDate'] != null ? (json['dueDate'] as Timestamp).toDate() : null,
      priority: json['priority'] as String?,
      project: json['project'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      estimatedPomodoros: json['estimatedPomodoros'] as int?,
      completedPomodoros: json['completedPomodoros'] as int?,
      category: json['category'] as String?,
      isPomodoroActive: json['isPomodoroActive'] as bool? ?? false,
      remainingPomodoroSeconds: json['remainingPomodoroSeconds'] as int?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      subtasks: (json['subtasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority,
      'project': project,
      'tags': tags,
      'estimatedPomodoros': estimatedPomodoros,
      'completedPomodoros': completedPomodoros,
      'category': category,
      'isPomodoroActive': isPomodoroActive,
      'remainingPomodoroSeconds': remainingPomodoroSeconds,
      'isCompleted': isCompleted,
      'subtasks': subtasks,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

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
    String? category,
    bool? isPomodoroActive,
    int? remainingPomodoroSeconds,
    bool? isCompleted,
    List<Map<String, dynamic>>? subtasks,
    String? userId,
    DateTime? createdAt,
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
      isPomodoroActive: isPomodoroActive ?? this.isPomodoroActive,
      remainingPomodoroSeconds: remainingPomodoroSeconds ?? this.remainingPomodoroSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}