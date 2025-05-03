import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';

class BackupService {
  final Box<Task> taskBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BackupService(this.taskBox);

  Future<void> backupToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final tasks = taskBox.values.toList();
    final tasksJson = tasks.map((task) => task.toJson()).toList();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({'tasks': tasksJson}, SetOptions(merge: true));
  }

  Future<void> restoreFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final tasksJson = doc.data()?['tasks'] as List<dynamic>;
      final tasks = tasksJson.map((json) => Task(
        id: json['id'],
        title: json['title'],
        note: json['note'],
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        priority: json['priority'],
        project: json['project'],
        tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
        estimatedPomodoros: json['estimatedPomodoros'],
        completedPomodoros: json['completedPomodoros'],
        category: json['category'],
      )).toList();

      await taskBox.clear();
      for (var task in tasks) {
        await taskBox.add(task);
      }
    } else {
      throw Exception('Không tìm thấy dữ liệu sao lưu trên Firestore');
    }
  }

  Future<void> deleteFirestoreBackup() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    await _firestore.collection('users').doc(user.uid).delete();
  }
  Future<DateTime?> getLastBackupTime() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final timestamp = doc.data()?['lastBackup'] as Timestamp?;
      return timestamp?.toDate();
    }
    return null;
  }
  Future<String> exportToLocalJson() async {
    final tasks = taskBox.values.toList();
    final tasksJson = tasks.map((task) => task.toJson()).toList();
    final jsonString = jsonEncode({'tasks': tasksJson});

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/moji_todo_backup.json');
    await file.writeAsString(jsonString);

    return file.path;
  }
}