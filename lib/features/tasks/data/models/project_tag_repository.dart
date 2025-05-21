import 'package:firebase_auth/firebase_auth.dart'; // THÊM ĐỂ LẤY USER ID
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/task_cubit.dart';
import '../models/project_model.dart';
import '../models/tag_model.dart';

class ProjectTagRepository {
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final FirebaseAuth _auth = FirebaseAuth.instance; // THÊM INSTANCE CỦA FirebaseAuth

  ProjectTagRepository({
    required this.projectBox,
    required this.tagBox,
  });

  // HÀM HELPER ĐỂ LẤY USER ID HIỆN TẠI
  String? get _currentUserId => _auth.currentUser?.uid;

  // HÀM HELPER ĐỂ THEO DÕI THAY ĐỔI CỤC BỘ
  Future<void> _trackModification(String boxName) async {
    try {
      final appStatusBox = await Hive.openBox('app_status');
      await appStatusBox.put('lastModified_$boxName', DateTime.now().toIso8601String());
      // print('Tracked modification for $boxName at ${DateTime.now()}');
      // Không cần đóng appStatusBox ở đây nếu nó còn được dùng thường xuyên
    } catch (e) {
      print('Error tracking modification for $boxName: $e');
      // Xử lý lỗi nếu cần, ví dụ không thể mở box
    }
  }

  // --- PROJECT METHODS ---

  Future<void> addProject(Project project) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể thêm project.');
    }
    // Đảm bảo project có userId đúng, hoặc gán nếu chưa có (quan trọng khi project được tạo từ nơi khác)
    final projectToAdd = project.userId == null || project.userId != userId
        ? project.copyWith(userId: userId)
        : project;

    // Hive tự động tạo key kiểu int nếu bạn dùng projectBox.add()
    // Nếu project.id đã có giá trị từ Uuid và bạn muốn dùng nó làm key,
    // thì nên dùng projectBox.put(projectToAdd.id, projectToAdd)
    // Tuy nhiên, để nhất quán với việc dùng key tự tăng của Hive hoặc key từ Firebase sau này,
    // việc để Hive tự quản lý key (khi add) hoặc dùng key rõ ràng (khi put) là cần xem xét.
    // Hiện tại, giả sử project.id là key mong muốn và nó là String.
    await projectBox.put(projectToAdd.id, projectToAdd);
    await _trackModification('projects');
  }

  Future<void> updateProject(dynamic key, Project updatedProjectData) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final existingProject = projectBox.get(key);
    if (existingProject == null || existingProject.userId != userId) {
      throw Exception('Project không tồn tại hoặc bạn không có quyền sửa.');
    }
    // Đảm bảo updatedProjectData cũng có userId đúng
    final projectToPut = updatedProjectData.copyWith(userId: userId);
    await projectBox.put(key, projectToPut);
    await _trackModification('projects');
  }

  Future<void> archiveProjectByKey(dynamic key) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final project = projectBox.get(key);
    if (project != null && project.userId == userId) {
      final archivedProject = project.copyWith(isArchived: true, userId: userId);
      await projectBox.put(key, archivedProject);
      await _trackModification('projects');
    } else {
      throw Exception('Project không tồn tại hoặc bạn không có quyền lưu trữ.');
    }
  }

  Future<void> restoreProjectByKey(dynamic key) async { // Đổi tên từ restoreProject để nhận key
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final project = projectBox.get(key);
    if (project != null && project.userId == userId) {
      final restoredProject = project.copyWith(isArchived: false, userId: userId);
      await projectBox.put(key, restoredProject);
      await _trackModification('projects');
    } else {
      throw Exception('Project không tồn tại hoặc bạn không có quyền khôi phục.');
    }
  }

  Future<void> deleteProjectByKey(dynamic key, BuildContext context) async { // Đổi tên để nhận key
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final projectToDelete = projectBox.get(key);
    if (projectToDelete != null && projectToDelete.userId == userId) {
      if (context.mounted) {
        // Cập nhật TaskCubit nếu cần
        // await context.read<TaskCubit>().updateTasksOnProjectDeletion(projectToDelete.id); // Sử dụng id của project
      }
      await projectBox.delete(key);
      await _trackModification('projects');
    } else {
      throw Exception('Project không tồn tại hoặc bạn không có quyền xóa.');
    }
  }

  List<Project> getProjects() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return projectBox.values.where((project) => project.userId == userId && !project.isArchived).toList();
  }

  List<Project> getArchivedProjects() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return projectBox.values.where((project) => project.userId == userId && project.isArchived).toList();
  }

  // --- TAG METHODS ---

  Future<void> addTag(Tag tag) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể thêm tag.');
    }
    final tagToAdd = tag.userId == null || tag.userId != userId
        ? tag.copyWith(userId: userId)
        : tag;
    await tagBox.put(tagToAdd.id, tagToAdd); // Giả sử tag.id là key mong muốn
    await _trackModification('tags');
  }

  Future<void> updateTag(dynamic key, Tag updatedTagData) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final existingTag = tagBox.get(key);
    if (existingTag == null || existingTag.userId != userId) {
      throw Exception('Tag không tồn tại hoặc bạn không có quyền sửa.');
    }
    final tagToPut = updatedTagData.copyWith(userId: userId);
    await tagBox.put(key, tagToPut);
    await _trackModification('tags');
  }

  Future<void> archiveTagByKey(dynamic key) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final tag = tagBox.get(key);
    if (tag != null && tag.userId == userId) {
      final archivedTag = tag.copyWith(isArchived: true, userId: userId);
      await tagBox.put(key, archivedTag);
      await _trackModification('tags');
    } else {
      throw Exception('Tag không tồn tại hoặc bạn không có quyền lưu trữ.');
    }
  }

  Future<void> restoreTagByKey(dynamic key) async { // Đổi tên để nhận key
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final tag = tagBox.get(key);
    if (tag != null && tag.userId == userId) {
      final restoredTag = tag.copyWith(isArchived: false, userId: userId);
      await tagBox.put(key, restoredTag);
      await _trackModification('tags');
    } else {
      throw Exception('Tag không tồn tại hoặc bạn không có quyền khôi phục.');
    }
  }

  Future<void> deleteTagByKey(dynamic key, BuildContext context) async { // Đổi tên để nhận key
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final tagToDelete = tagBox.get(key);
    if (tagToDelete != null && tagToDelete.userId == userId) {
      if (context.mounted) {
        // Cập nhật TaskCubit nếu cần
        // await context.read<TaskCubit>().updateTasksOnTagDeletion(tagToDelete.id); // Sử dụng id của tag
      }
      await tagBox.delete(key);
      await _trackModification('tags');
    } else {
      throw Exception('Tag không tồn tại hoặc bạn không có quyền xóa.');
    }
  }

  List<Tag> getTags() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return tagBox.values.where((tag) => tag.userId == userId && !tag.isArchived).toList();
  }

  List<Tag> getArchivedTags() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return tagBox.values.where((tag) => tag.userId == userId && tag.isArchived).toList();
  }

// XÓA CÁC PHƯƠNG THỨC DÙNG boxIndex VÌ ÍT AN TOÀN HƠN VÀ GÂY NHẦM LẪN
// Future<void> archiveProjectWithBoxIndex(int boxIndex) async { ... }
// Future<void> archiveTagWithBoxIndex(int boxIndex) async { ... }
// Các hàm restore/delete cũ dùng indexInArchivedList cũng đã được thay bằng key
}