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

  // RENAMED: từ project thành projectId
  @HiveField(5)
  String? projectId;

  // RENAMED: từ tags thành tagIds
  @HiveField(6)
  List<String>? tagIds;

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
  DateTime? createdAt;

  @HiveField(16)
  String? originalCategory;

  @HiveField(17)
  DateTime? completionDate; // Giữ lại trường này

  Task({
    this.id,
    this.title,
    this.note,
    this.dueDate,
    this.priority,
    this.projectId, // MODIFIED
    this.tagIds,    // MODIFIED
    this.estimatedPomodoros,
    this.completedPomodoros,
    this.category,
    this.isPomodoroActive = false,
    this.remainingPomodoroSeconds,
    this.isCompleted = false,
    this.subtasks,
    this.userId,
    this.createdAt,
    this.originalCategory,
    this.completionDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String?,
      note: json['note'] as String?,
      dueDate: json['dueDate'] != null ? (json['dueDate'] as Timestamp).toDate() : null,
      priority: json['priority'] as String?,
      projectId: json['projectId'] as String?, // MODIFIED (key trong JSON cũng đổi thành projectId)
      tagIds: (json['tagIds'] as List<dynamic>?)?.cast<String>(), // MODIFIED (key trong JSON cũng đổi thành tagIds)
      estimatedPomodoros: json['estimatedPomodoros'] as int?,
      completedPomodoros: json['completedPomodoros'] as int?,
      category: json['category'] as String?,
      isPomodoroActive: json['isPomodoroActive'] as bool? ?? false,
      remainingPomodoroSeconds: json['remainingPomodoroSeconds'] as int?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      subtasks: (json['subtasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      originalCategory: json['originalCategory'] as String?,
      completionDate: json['completionDate'] != null ? (json['completionDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority,
      'projectId': projectId, // MODIFIED (key trong JSON cũng đổi thành projectId)
      'tagIds': tagIds,       // MODIFIED (key trong JSON cũng đổi thành tagIds)
      'estimatedPomodoros': estimatedPomodoros,
      'completedPomodoros': completedPomodoros,
      'category': category,
      'isPomodoroActive': isPomodoroActive,
      'remainingPomodoroSeconds': remainingPomodoroSeconds,
      'isCompleted': isCompleted,
      'subtasks': subtasks,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'originalCategory': originalCategory,
      'completionDate': completionDate != null ? Timestamp.fromDate(completionDate!) : null,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? note,
    DateTime? dueDate,
    String? priority,
    String? projectId, // MODIFIED
    List<String>? tagIds, // MODIFIED
    int? estimatedPomodoros,
    int? completedPomodoros,
    String? category,
    bool? isPomodoroActive,
    int? remainingPomodoroSeconds,
    bool? isCompleted,
    List<Map<String, dynamic>>? subtasks,
    String? userId,
    DateTime? createdAt,
    String? originalCategory,
    DateTime? completionDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId, // MODIFIED
      tagIds: tagIds ?? this.tagIds,          // MODIFIED
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      category: category ?? this.category,
      isPomodoroActive: isPomodoroActive ?? this.isPomodoroActive,
      remainingPomodoroSeconds: remainingPomodoroSeconds ?? this.remainingPomodoroSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      originalCategory: originalCategory ?? this.originalCategory,
      completionDate: completionDate ?? this.completionDate,
    );
  }
}