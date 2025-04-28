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
    final newId = taskBox.isEmpty ? 1 : taskBox.values.last.id! + 1;
    task = task..id = newId;
    await taskBox.put(newId, task);
    await firestore.collection('tasks').add(task.toJson());
  }

  Future<void> updateTask(Task task) async {
    if (task.id != null) {
      await taskBox.put(task.id!, task);
      final query = await firestore.collection('tasks').where('id', isEqualTo: task.id).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(task.toJson());
      }
    }
  }

  Future<void> deleteTask(int id) async {
    await taskBox.delete(id);
    final query = await firestore.collection('tasks').where('id', isEqualTo: id).get();
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
    };
  }
}