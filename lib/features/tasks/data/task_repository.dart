import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../data/models/task_model.dart';

class TaskRepository {
  final Box<Task> taskBox;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  TaskRepository({required this.taskBox});

  Future<List<Task>> getTasks() async {
    return taskBox.values.toList();
  }

  Future<void> addTask(Task task) async {
    final newId = taskBox.isEmpty ? 1 : (taskBox.values.last.id ?? 0) + 1;
    task = task.copyWith(id: newId);
    await taskBox.put(newId, task);
    await firestore.collection('tasks').doc(newId.toString()).set(task.toJson());
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) {
      throw Exception('Task ID cannot be null');
    }
    await taskBox.put(task.id!, task);
    final query = await firestore.collection('tasks').where('id', isEqualTo: task.id).get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update(task.toJson());
    } else {
      await firestore.collection('tasks').doc(task.id.toString()).set(task.toJson());
    }
  }

  Future<void> deleteTask(Task task) async {
    if (task.id == null) {
      throw Exception('Task ID cannot be null');
    }
    await taskBox.delete(task.id);
    final query = await firestore.collection('tasks').where('id', isEqualTo: task.id).get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
  }
}

extension TaskExtension on Task {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
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
    };
  }
}