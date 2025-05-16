import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/data/models/project_model.dart';
import '../../features/tasks/data/models/tag_model.dart';

class BackupService {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BackupService(this.taskBox, this.syncInfoBox, this.projectBox, this.tagBox);

  Future<DateTime?> getLastBackupTime() async {
    return syncInfoBox.get('lastSync');
  }

  Future<void> backupToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Người dùng chưa đăng nhập, không thể đồng bộ.');
      return;
    }

    // Đồng bộ tasks
    final tasks = taskBox.values.toList();
    for (var task in tasks) {
      try {
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
      } catch (e) {
        print('Lỗi khi đồng bộ task ${task.id}: $e');
      }
    }

    // Đồng bộ projects
    final projects = projectBox.values.toList();
    for (var project in projects) {
      try {
        final query = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('projects')
            .where('id', isEqualTo: project.id)
            .get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'id': project.id,
            'name': project.name,
            'color': project.color.value,
            'isArchived': project.isArchived,
          });
        } else {
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('projects')
              .doc(project.id)
              .set({
            'id': project.id,
            'name': project.name,
            'color': project.color.value,
            'isArchived': project.isArchived,
          });
        }
      } catch (e) {
        print('Lỗi khi đồng bộ project ${project.id}: $e');
      }
    }

    // Đồng bộ tags
    final tags = tagBox.values.toList();
    for (var tag in tags) {
      try {
        final query = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('tags')
            .where('id', isEqualTo: tag.id)
            .get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'id': tag.id,
            'name': tag.name,
            'backgroundColor': tag.backgroundColor.value,
            'textColor': tag.textColor.value,
            'isArchived': tag.isArchived,
          });
        } else {
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('tags')
              .doc(tag.id)
              .set({
            'id': tag.id,
            'name': tag.name,
            'backgroundColor': tag.backgroundColor.value,
            'textColor': tag.textColor.value,
            'isArchived': tag.isArchived,
          });
        }
      } catch (e) {
        print('Lỗi khi đồng bộ tag ${tag.id}: $e');
      }
    }

    // Xóa dữ liệu không còn trong Hive trên Firestore
    await _cleanUpFirestore(user.uid, 'tasks', tasks.map((t) => t.id.toString()).toList());
    await _cleanUpFirestore(user.uid, 'projects', projects.map((p) => p.id).toList());
    await _cleanUpFirestore(user.uid, 'tags', tags.map((t) => t.id).toList());

    // Cập nhật thời gian đồng bộ cuối cùng
    await syncInfoBox.put('lastSync', DateTime.now());
  }

  Future<void> savePomodoroSession({
    required String taskId,
    required DateTime startTime,
    required DateTime endTime,
    required bool isWorkSession,
    required String soundUsed,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Người dùng chưa đăng nhập, không thể lưu phiên Pomodoro.');
      return;
    }
    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('pomodoro_sessions')
          .add({
        'taskId': taskId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'isWorkSession': isWorkSession,
        'soundUsed': soundUsed,
      });
      print('Lưu phiên Pomodoro thành công: taskId=$taskId, startTime=$startTime');
    } catch (e) {
      print('Lỗi khi lưu phiên Pomodoro: $e');
    }
  }

  Future<void> restoreFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    // Khôi phục tasks
    final taskSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();
    if (taskSnapshot.docs.isNotEmpty) {
      final tasks = taskSnapshot.docs.map((doc) => Task.fromJson(doc.data())).toList();

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
    }

    // Khôi phục projects
    final projectSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();
    if (projectSnapshot.docs.isNotEmpty) {
      final projects = projectSnapshot.docs.map((doc) => Project(
        id: doc.data()['id'],
        name: doc.data()['name'],
        color: Color(doc.data()['color']),
        isArchived: doc.data()['isArchived'] ?? false,
      )).toList();

      // Xóa project cũ
      await projectBox.clear();
      // Thêm project từ Firestore
      for (var project in projects) {
        await projectBox.add(project);
      }
    }

    // Khôi phục tags
    final tagSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('tags')
        .get();
    if (tagSnapshot.docs.isNotEmpty) {
      final tags = tagSnapshot.docs.map((doc) => Tag(
        id: doc.data()['id'],
        name: doc.data()['name'],
        backgroundColor: Color(doc.data()['backgroundColor']),
        textColor: Color(doc.data()['textColor']),
        isArchived: doc.data()['isArchived'] ?? false,
      )).toList();

      // Xóa tag cũ
      await tagBox.clear();
      // Thêm tag từ Firestore
      for (var tag in tags) {
        await tagBox.add(tag);
      }
    }

    if (taskSnapshot.docs.isEmpty && projectSnapshot.docs.isEmpty && tagSnapshot.docs.isEmpty) {
      throw Exception('Không tìm thấy dữ liệu sao lưu trên Firestore');
    }
  }

  Future<void> deleteFirestoreBackup() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    // Xóa tasks
    final taskSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();
    for (var doc in taskSnapshot.docs) {
      await doc.reference.delete();
    }

    // Xóa projects
    final projectSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();
    for (var doc in projectSnapshot.docs) {
      await doc.reference.delete();
    }

    // Xóa tags
    final tagSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('tags')
        .get();
    for (var doc in tagSnapshot.docs) {
      await doc.reference.delete();
    }

    // Xóa pomodoro_sessions
    final sessionSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('pomodoro_sessions')
        .get();
    for (var doc in sessionSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _cleanUpFirestore(String userId, String collectionName, List<String> currentKeys) async {
    final collection = await firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .get();
    for (var doc in collection.docs) {
      final key = doc.id;
      if (!currentKeys.contains(key)) {
        await doc.reference.delete();
      }
    }
  }

  Future<String> exportToLocalJson() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final tasks = taskBox.values.where((task) => task.userId == user.uid).toList();
    final projects = projectBox.values.toList();
    final tags = tagBox.values.toList();

    final jsonData = {
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'projects': projects.map((project) => {
        'id': project.id,
        'name': project.name,
        'color': project.color.value,
        'isArchived': project.isArchived,
      }).toList(),
      'tags': tags.map((tag) => {
        'id': tag.id,
        'name': tag.name,
        'backgroundColor': tag.backgroundColor.value,
        'textColor': tag.textColor.value,
        'isArchived': tag.isArchived,
      }).toList(),
    };

    final jsonString = jsonEncode(jsonData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/moji_todo_backup.json');
    await file.writeAsString(jsonString);

    return file.path;
  }
}