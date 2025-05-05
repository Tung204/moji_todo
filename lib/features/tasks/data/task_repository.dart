import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../data/models/task_model.dart';

class TaskRepository {
  final Box<Task> taskBox;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  TaskRepository({required this.taskBox}) {
    _initializeSampleTasks();
  }

  Future<void> _initializeSampleTasks() async {
    if (taskBox.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Người dùng chưa đăng nhập, không tạo task mẫu.');
        return;
      }
      final sampleTask = Task(
        id: 1,
        title: 'Design User Interface (UI)',
        dueDate: DateTime.now(),
        priority: 'High',
        project: 'Pomodoro App',
        tags: ['Design', 'Work', 'Productive'],
        estimatedPomodoros: 6,
        completedPomodoros: 2,
        isCompleted: false,
        userId: user.uid,
      );
      await addTask(sampleTask);
    }
  }

  Future<List<Task>> getTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể lấy danh sách task.');
    }
    final tasks = taskBox.values.toList();
    return tasks.where((task) => task.userId == user.uid).toList();
  }

  Future<void> addTask(Task task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể thêm task.');
    }

    final newId = taskBox.isEmpty ? 1 : (taskBox.values.last.id ?? 0) + 1;
    task = task.copyWith(
      id: newId,
      userId: user.uid,
    );
    await taskBox.put(newId, task);
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(newId.toString())
        .set(task.toJson());
  }

  Future<void> updateTask(Task task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể cập nhật task.');
    }
    if (task.id == null) {
      throw Exception('Task ID cannot be null');
    }
    if (task.userId != user.uid) {
      throw Exception('Bạn không có quyền cập nhật task này.');
    }
    await taskBox.put(task.id!, task);
    final query = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('id', isEqualTo: task.id)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update(task.toJson());
    } else {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(task.id.toString())
          .set(task.toJson());
    }
  }

  Future<void> deleteTask(Task task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể xóa task.');
    }
    if (task.id == null) {
      throw Exception('Task ID cannot be null');
    }
    if (task.userId != user.uid) {
      throw Exception('Bạn không có quyền xóa task này.');
    }
    await taskBox.delete(task.id);
    final query = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('id', isEqualTo: task.id)
        .get();
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
      'userId': userId,
    };
  }
}