import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../data/models/task_model.dart';
import '../data/models/project_model.dart';
import '../data/models/tag_model.dart';

class TaskRepository {
  final Box<Task> taskBox;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // THÊM INSTANCE CỦA FirebaseAuth

  TaskRepository({
    required this.taskBox,
    required this.projectBox,
    required this.tagBox,
  }) {
    // Bỏ _initializeSampleTasks() ra khỏi constructor nếu bạn muốn nó được gọi
    // một cách có kiểm soát hơn, ví dụ sau khi người dùng đăng nhập và dữ liệu đã được khôi phục.
    // Hoặc, đảm bảo _initializeSampleTasks chỉ chạy nếu taskBox thực sự trống SAU KHI đã lọc theo user.
    // Hiện tại, nó sẽ chạy nếu taskBox (toàn cục) trống, có thể tạo task mẫu cho user đầu tiên mở app.
    // _initializeSampleTasks(); // Xem xét lại thời điểm gọi hàm này
  }

  // HÀM HELPER ĐỂ LẤY USER ID HIỆN TẠI
  String? get _currentUserId => _auth.currentUser?.uid;

  // HÀM HELPER ĐỂ THEO DÕI THAY ĐỔI CỤC BỘ
  Future<void> _trackModification(String boxName) async {
    try {
      final appStatusBox = await Hive.openBox('app_status');
      await appStatusBox.put('lastModified_$boxName', DateTime.now().toIso8601String());
      // print('Tracked modification for $boxName at ${DateTime.now()}');
    } catch (e) {
      print('Error tracking modification for $boxName: $e');
    }
  }

  Future<void> initializeSampleTasksForCurrentUser() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('Người dùng chưa đăng nhập, không tạo task mẫu.');
      return;
    }

    // Chỉ tạo task mẫu nếu người dùng hiện tại chưa có task nào
    final userTasks = taskBox.values.where((task) => task.userId == userId).toList();
    if (userTasks.isNotEmpty) {
      print('Người dùng đã có task, không tạo task mẫu.');
      return;
    }

    String? sampleProjectId;
    try {
      // Lấy project mẫu CỦA NGƯỜI DÙNG HIỆN TẠI (nếu có)
      final defaultProject = projectBox.values.firstWhere(
            (p) => p.name == 'Pomodoro App' && p.userId == userId,
      );
      sampleProjectId = defaultProject.id;
    } catch (e) {
      print('Không tìm thấy project "Pomodoro App" của người dùng $userId cho sample task. Lỗi: $e');
    }

    List<String> sampleTagIds = [];
    final List<String> sampleTagNames = ['Design', 'Work', 'Productive'];
    for (String tagName in sampleTagNames) {
      try {
        // Lấy tag mẫu CỦA NGƯỜI DÙNG HIỆN TẠI (nếu có)
        final defaultTag = tagBox.values.firstWhere(
              (t) => t.name == tagName && t.userId == userId,
        );
        sampleTagIds.add(defaultTag.id);
      } catch (e) {
        print('Không tìm thấy tag "$tagName" của người dùng $userId cho sample task. Lỗi: $e');
      }
    }

    final sampleTask = Task(
      title: 'Design User Interface (UI)',
      dueDate: DateTime.now(),
      priority: 'High',
      projectId: sampleProjectId,
      tagIds: sampleTagIds,
      estimatedPomodoros: 6,
      completedPomodoros: 2,
      isCompleted: false,
      userId: userId, // userId đã được gán ở đây
      createdAt: DateTime.now(),
    );
    await addTask(sampleTask); // addTask sẽ tự xử lý việc gán ID và lưu
    print('Sample task initialized for user $userId.');
  }


  Future<List<Task>> getTasks() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('Người dùng chưa đăng nhập, trả về danh sách task rỗng.');
      return [];
    }
    return taskBox.values.where((task) => task.userId == userId).toList();
  }

  Future<void> addTask(Task task) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể thêm task.');
    }

    // Đảm bảo task có userId đúng của người dùng hiện tại
    final taskWithCorrectUser = task.copyWith(userId: userId);

    // Tạo ID mới nếu task chưa có ID.
    // Cách tạo ID này (dựa trên max ID hiện có) có thể gặp vấn đề về hiệu suất
    // và xung đột nếu có nhiều thao tác đồng thời.
    // Cân nhắc dùng UUID cho task ID giống như Project/Tag hoặc một cơ chế ID khác.
    // Hiện tại, giữ nguyên logic tạo ID của bạn.
    int newId = taskWithCorrectUser.id ??
        (taskBox.values.where((t) => t.userId == userId).isNotEmpty // Lọc theo user trước khi tìm max
            ? (taskBox.values.where((t) => t.userId == userId).map((t) => t.id ?? 0).reduce((a, b) => a > b ? a : b) + 1)
            : 1);

    final taskToAdd = taskWithCorrectUser.copyWith(
      id: newId,
      // userId đã được gán ở taskWithCorrectUser
      createdAt: taskWithCorrectUser.createdAt ?? DateTime.now(),
    );

    await taskBox.put(newId, taskToAdd); // Sử dụng ID làm key
    await _trackModification('tasks'); // THEO DÕI THAY ĐỔI

    // Không tự động đồng bộ lên Firestore ở đây nữa. Việc này sẽ do BackupService xử lý.
    // await firestore
    //     .collection('users')
    //     .doc(userId)
    //     .collection('tasks')
    //     .doc(newId.toString())
    //     .set(taskToAdd.toJson());
    print('Task added to Hive with ID: $newId, Title: ${taskToAdd.title}');
  }

  Future<void> updateTask(Task task) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể cập nhật task.');
    }
    if (task.id == null) {
      throw Exception('Task ID không thể null khi cập nhật.');
    }

    final existingTask = taskBox.get(task.id);
    if (existingTask == null || existingTask.userId != userId) {
      throw Exception('Bạn không có quyền cập nhật task này hoặc task không tồn tại.');
    }

    // Đảm bảo userId và createdAt không bị thay đổi ngoài ý muốn khi cập nhật
    final taskToUpdate = task.copyWith(
        userId: existingTask.userId,
        createdAt: existingTask.createdAt
    );

    await taskBox.put(task.id!, taskToUpdate);
    await _trackModification('tasks'); // THEO DÕI THAY ĐỔI

    // Không tự động đồng bộ lên Firestore ở đây nữa.
    // await firestore
    //     .collection('users')
    //     .doc(userId)
    //     .collection('tasks')
    //     .doc(task.id.toString())
    //     .set(taskToUpdate.toJson(), SetOptions(merge: true));
    print('Task updated in Hive with ID: ${task.id}, Title: ${taskToUpdate.title}');
  }

  Future<void> deleteTask(Task task) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể xóa task.');
    }
    if (task.id == null) {
      throw Exception('Task ID không thể null khi xóa.');
    }

    final existingTask = taskBox.get(task.id);
    if (existingTask != null && existingTask.userId != userId) {
      throw Exception('Bạn không có quyền xóa task này.');
    }

    if (existingTask == null) {
      print('Task ID ${task.id} không tìm thấy trong Hive để xóa.');
    } else {
      await taskBox.delete(task.id!);
      await _trackModification('tasks'); // THEO DÕI THAY ĐỔI
    }

    // Không tự động đồng bộ lên Firestore ở đây nữa.
    // await firestore
    //     .collection('users')
    //     .doc(userId)
    //     .collection('tasks')
    //     .doc(task.id.toString())
    //     .delete();
    print('Task deleted from Hive with ID: ${task.id}');
  }
}