import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';

class BackupService {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BackupService(this.taskBox, this.syncInfoBox);

  // Đồng bộ task lên Firestore
  Future<void> backupToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    // Lấy danh sách task của người dùng hiện tại
    final tasks = taskBox.values.where((task) => task.userId == user.uid).toList();
    final tasksJson = tasks.map((task) => task.toJson()).toList();

    // Lưu từng task vào /users/{userId}/tasks
    for (var task in tasks) {
      if (task.id != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tasks')
            .doc(task.id.toString())
            .set(task.toJson(), SetOptions(merge: true));
      }
    }

    // Cập nhật thời gian đồng bộ cuối cùng
    await syncInfoBox.put('lastSync', DateTime.now());
  }

  // Khôi phục task từ Firestore
  Future<void> restoreFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();

    if (snapshot.docs.isNotEmpty) {
      final tasks = snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList();

      // Xóa task cũ của người dùng hiện tại
      final keysToDelete = <dynamic>[];
      for (int i = 0; i < taskBox.length; i++) {
        final task = taskBox.getAt(i);
        if (task != null && task.userId == user.uid) {
          keysToDelete.add(taskBox.keyAt(i));
        }
      }
      for (var key in keysToDelete) {
        await taskBox.delete(key);
      }

      // Thêm task mới từ Firestore
      for (var task in tasks) {
        await taskBox.add(task);
      }
    } else {
      throw Exception('Không tìm thấy dữ liệu sao lưu trên Firestore');
    }
  }

  // Xóa dữ liệu sao lưu trên Firestore
  Future<void> deleteFirestoreBackup() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Lấy thời gian đồng bộ cuối cùng
  Future<DateTime?> getLastBackupTime() async {
    return syncInfoBox.get('lastSync');
  }

  // Xuất dữ liệu task ra JSON cục bộ
  Future<String> exportToLocalJson() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final tasks = taskBox.values.where((task) => task.userId == user.uid).toList();
    final tasksJson = tasks.map((task) => task.toJson()).toList();
    final jsonString = jsonEncode({'tasks': tasksJson});

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/moji_todo_backup.json');
    await file.writeAsString(jsonString);

    return file.path;
  }
}