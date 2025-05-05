import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../data/models/task_model.dart';

class TaskRepository {
  final Box<Task> taskBox;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  TaskRepository({required this.taskBox});

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
      createdAt: DateTime.now(),
    );
    await taskBox.put(newId, task);
    // Không đồng bộ ngay lên Firestore, sẽ đồng bộ định kỳ qua BackupService
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
    // Không đồng bộ ngay lên Firestore, sẽ đồng bộ định kỳ qua BackupService
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

    // Xóa task khỏi Hive
    await taskBox.delete(task.id);

    // Kiểm tra xem task đã được đồng bộ lên Firestore chưa
    final syncInfoBox = await Hive.openBox<DateTime>('sync_info');
    final lastSync = syncInfoBox.get('lastSync');
    final createdAt = task.createdAt;

    if (lastSync != null && createdAt != null && createdAt.isBefore(lastSync)) {
      // Task đã được đồng bộ, xóa trên Firestore
      try {
        final query = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('tasks')
            .where('id', isEqualTo: task.id)
            .get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.delete();
        }
      } catch (e) {
        print('Lỗi khi xóa task trên Firestore: $e');
        // Không throw lỗi, vì task đã được xóa khỏi Hive
      }
    }
    // Nếu task chưa được đồng bộ (lastSync == null hoặc createdAt > lastSync), không cần xóa trên Firestore
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
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}