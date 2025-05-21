import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/gemini_service.dart';
import '../data/models/project_model.dart';
import '../data/models/tag_model.dart';
import '../data/models/task_model.dart';
import '../data/task_repository.dart';
import '../data/models/project_tag_repository.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskRepository taskRepository;
  final ProjectTagRepository projectTagRepository;
  final GeminiService _geminiService = GeminiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TaskCubit({
    required this.taskRepository,
    required this.projectTagRepository,
  }) : super(const TaskState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true));
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], allProjects: [], allTags: [], isLoading: false));
      return;
    }
    try {
      final tasks = await taskRepository.getTasks();
      final projects = await projectTagRepository.getProjects();
      final tags = await projectTagRepository.getTags();

      emit(state.copyWith(
        tasks: tasks,
        allProjects: projects,
        allTags: tags,
        isLoading: false,
      ));
    } catch (e) {
      print("Error loading initial data for TaskCubit: $e");
      emit(state.copyWith(isLoading: false, tasks: [], allProjects: [], allTags: [])); // Đảm bảo reset nếu lỗi
    }
  }

  Future<void> loadTasks() async {
    await loadInitialData();
  }

  Future<void> addTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final category = await _geminiService.classifyTask(task.title ?? '');
    final taskToAdd = task.copyWith(
      category: category,
      userId: user.uid,
      createdAt: task.createdAt ?? DateTime.now(),
      isCompleted: false,
      completionDate: null,
    );
    await taskRepository.addTask(taskToAdd);
    await loadInitialData();
  }

  Future<void> updateTasksOnProjectDeletion(String projectIdToDelete) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final tasksToUpdate = List<Task>.from(state.tasks)
        .where((task) => task.projectId == projectIdToDelete && task.userId == user.uid)
        .toList();

    for (var task in tasksToUpdate) {
      await taskRepository.updateTask(task.copyWith(projectId: null));
    }
    await loadInitialData();
  }

  Future<void> updateTasksOnTagDeletion(String tagIdToDelete) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final tasksToUpdate = List<Task>.from(state.tasks)
        .where((task) => task.tagIds?.contains(tagIdToDelete) == true && task.userId == user.uid)
        .toList();

    for (var task in tasksToUpdate) {
      final updatedTagIds = List<String>.from(task.tagIds!)..remove(tagIdToDelete);
      await taskRepository.updateTask(task.copyWith(tagIds: updatedTagIds));
    }
    await loadInitialData();
  }

  Future<void> updateTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    // Đảm bảo task đang được cập nhật thuộc về người dùng hiện tại (nếu task đã có userId)
    if (task.userId != null && task.userId != user.uid) {
      print('Cảnh báo: Cố gắng cập nhật task không thuộc sở hữu của người dùng hiện tại. Task UserID: ${task.userId}, Current UserID: ${user.uid}');
      throw Exception('Bạn không có quyền cập nhật task này.');
    }

    Task taskToUpdate = task.copyWith(userId: user.uid);

    if (taskToUpdate.isCompleted == true && taskToUpdate.completionDate == null) {
      taskToUpdate = taskToUpdate.copyWith(completionDate: DateTime.now());
    } else if (taskToUpdate.isCompleted == false && taskToUpdate.completionDate != null) {
      taskToUpdate = Task(
        id: taskToUpdate.id,
        title: taskToUpdate.title,
        note: taskToUpdate.note,
        dueDate: taskToUpdate.dueDate,
        priority: taskToUpdate.priority,
        projectId: taskToUpdate.projectId,
        tagIds: taskToUpdate.tagIds,
        estimatedPomodoros: taskToUpdate.estimatedPomodoros,
        completedPomodoros: taskToUpdate.completedPomodoros,
        category: taskToUpdate.category,
        isPomodoroActive: taskToUpdate.isPomodoroActive,
        remainingPomodoroSeconds: taskToUpdate.remainingPomodoroSeconds,
        isCompleted: taskToUpdate.isCompleted,
        subtasks: taskToUpdate.subtasks,
        userId: taskToUpdate.userId,
        createdAt: taskToUpdate.createdAt,
        originalCategory: taskToUpdate.originalCategory,
        completionDate: null,
      );
    }

    await taskRepository.updateTask(taskToUpdate);
    await loadInitialData();
  }

  Future<void> deleteTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (task.userId != user.uid && task.userId != null) throw Exception('Bạn không có quyền xóa task này.');

    await taskRepository.deleteTask(task);
    await loadInitialData();
  }

  Future<void> restoreTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (task.userId != user.uid && task.userId != null) throw Exception('Bạn không có quyền khôi phục task này.');

    final restoredCategory = task.originalCategory ?? 'Planned';
    await taskRepository.updateTask(task.copyWith(category: restoredCategory, isCompleted: false, completionDate: null));
    await loadInitialData();
  }

  Future<void> searchTasks(String query) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], isLoading: false, allProjects: state.allProjects, allTags: state.allTags));
      return;
    }

    emit(state.copyWith(isLoading: true));
    final allTasks = await taskRepository.getTasks(); // Lấy tất cả task của user hiện tại

    if (query.isEmpty) {
      // Khi query rỗng, chỉ cần emit lại danh sách task đã load (allTasks)
      // allProjects và allTags đã có sẵn trong state từ loadInitialData
      emit(state.copyWith(tasks: allTasks, isLoading: false, allProjects: state.allProjects, allTags: state.allTags));
      return;
    }

    final geminiService = GeminiService();
    final filteredTasks = <Task>[];

    for (var task in allTasks) {
      // Không cần kiểm tra task.userId == user.uid nữa vì getTasks() đã làm điều đó
      final prompt = '''
      Kiểm tra xem task sau có phù hợp với query không:
      - Task title: "${task.title}"
      - Query: "$query"
      Trả về true/false.
      ''';
      try {
        final response = await geminiService.generateContent([Content.text(prompt)]);
        if (response.text?.trim().toLowerCase() == 'true') {
          filteredTasks.add(task);
        }
      } catch (e) {
        print('Lỗi khi dùng Gemini để search task ${task.title}: $e');
        if (task.title?.toLowerCase().contains(query.toLowerCase()) ?? false) {
          // filteredTasks.add(task); // Fallback tìm kiếm đơn giản
        }
      }
    }
    emit(state.copyWith(tasks: filteredTasks, isLoading: false, allProjects: state.allProjects, allTags: state.allTags));
  }

  // --- NEW: Thêm các hàm bị thiếu ---
  void toggleSelectionMode() {
    emit(state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      // Xóa danh sách các task đã chọn khi thoát khỏi chế độ chọn nhiều
      selectedTasks: !state.isSelectionMode ? state.selectedTasks : [],
    ));
  }

  void toggleTaskSelection(Task task) {
    if (!state.isSelectionMode) return; // Chỉ hoạt động ở chế độ chọn

    final currentSelectedTasks = List<Task>.from(state.selectedTasks);
    // Kiểm tra xem task đã được chọn chưa bằng cách so sánh ID (nếu có) hoặc object
    final existingTaskIndex = currentSelectedTasks.indexWhere((t) => t.id == task.id && task.id != null || t == task);

    if (existingTaskIndex != -1) {
      currentSelectedTasks.removeAt(existingTaskIndex);
    } else {
      currentSelectedTasks.add(task);
    }
    emit(state.copyWith(selectedTasks: currentSelectedTasks));
  }

  Future<void> restoreSelectedTasks() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (state.selectedTasks.isEmpty) return;

    for (var task in state.selectedTasks) {
      if (task.userId == user.uid) { // Chỉ khôi phục task của user hiện tại
        final restoredCategory = task.originalCategory ?? 'Planned';
        await taskRepository.updateTask(task.copyWith(
            category: restoredCategory,
            isCompleted: false, // Khi khôi phục thì chưa hoàn thành
            completionDate: null // Xóa ngày hoàn thành
        ));
      }
    }
    // Thoát chế độ chọn và load lại dữ liệu
    emit(state.copyWith(isSelectionMode: false, selectedTasks: []));
    await loadInitialData();
  }

  Future<void> deleteSelectedTasks() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (state.selectedTasks.isEmpty) return;

    for (var task in state.selectedTasks) {
      if (task.userId == user.uid) { // Chỉ xóa task của user hiện tại
        await taskRepository.deleteTask(task); // Giả sử deleteTask xử lý xóa vĩnh viễn
      }
    }
    // Thoát chế độ chọn và load lại dữ liệu
    emit(state.copyWith(isSelectionMode: false, selectedTasks: []));
    await loadInitialData();
  }

  void sortTasks(String criteria) {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: []));
      return;
    }
    final sortedTasks = List<Task>.from(state.tasks);
    if (criteria == 'dueDate') {
      sortedTasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else if (criteria == 'priority') {
      sortedTasks.sort((a, b) => _priorityValue(a.priority).compareTo(_priorityValue(b.priority)));
    }
    // Khi sắp xếp, không cần load lại allProjects, allTags vì chúng không đổi
    emit(state.copyWith(tasks: sortedTasks, allProjects: state.allProjects, allTags: state.allTags));
  }


  void sortTasksInTrash(String criteria) {
    final user = _auth.currentUser;
    if (user == null) {
      // Không thay đổi state.tasks nếu không có user, chỉ đảm bảo không crash
      emit(state.copyWith(tasks: state.tasks, allProjects: state.allProjects, allTags: state.allTags));
      return;
    }

    // Lấy toàn bộ danh sách tasks từ state hiện tại
    final currentTasks = List<Task>.from(state.tasks);

    // Tách riêng tasks trong thùng rác và tasks không trong thùng rác
    final trashTasks = currentTasks.where((task) => task.category == 'Trash' && task.userId == user.uid).toList();
    final nonTrashTasks = currentTasks.where((task) => task.category != 'Trash' || task.userId != user.uid).toList();

    // Sắp xếp danh sách task trong thùng rác
    if (criteria == 'title') {
      trashTasks.sort((a, b) => (a.title ?? '').toLowerCase().compareTo((b.title ?? '').toLowerCase()));
    } else if (criteria == 'deletedDate') {
      // Giả sử 'createdAt' có thể coi như ngày gần nhất task được cập nhật/đưa vào thùng rác
      trashTasks.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(1900);
        final dateB = b.createdAt ?? DateTime(1900);
        return dateB.compareTo(dateA); // Mới nhất lên đầu
      });
    }

    // Kết hợp lại: tasks không trong thùng rác + tasks trong thùng rác đã sắp xếp
    final newTaskList = [...nonTrashTasks, ...trashTasks];

    // Emit state mới với danh sách task đã được xử lý
    emit(state.copyWith(tasks: newTaskList, allProjects: state.allProjects, allTags: state.allTags));
  }
  // --- Hết phần thêm các hàm ---


  int _priorityValue(String? priority) {
    switch (priority) {
      case 'High': return 1;
      case 'Medium': return 2;
      case 'Low': return 3;
      default: return 4;
    }
  }

  Map<String, List<Task>> getCategorizedTasks() {
    final user = _auth.currentUser;
    if (user == null) return {
      'Today': [], 'Tomorrow': [], 'This Week': [],
      'Planned': [], 'Completed': [], 'Trash': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final startOfWeek = today.subtract(Duration(days: today.weekday - DateTime.monday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final Map<String, List<Task>> categorizedTasks = {
      'Today': [], 'Tomorrow': [], 'This Week': [],
      'Planned': [], 'Completed': [], 'Trash': [],
    };

    for (var task in state.tasks) {
      if (task.userId != user.uid) continue;

      if (task.category == 'Trash') {
        categorizedTasks['Trash']!.add(task);
      } else if (task.isCompleted == true) {
        categorizedTasks['Completed']!.add(task);
      } else if (task.dueDate != null) {
        final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        if (dueDate.isAtSameMomentAs(today)) {
          categorizedTasks['Today']!.add(task);
        } else if (dueDate.isAtSameMomentAs(tomorrow)) {
          categorizedTasks['Tomorrow']!.add(task);
        } else if (!dueDate.isBefore(startOfWeek) && !dueDate.isAfter(endOfWeek)) {
          categorizedTasks['This Week']!.add(task);
        } else {
          categorizedTasks['Planned']!.add(task);
        }
      } else {
        categorizedTasks['Planned']!.add(task);
      }
    }
    return categorizedTasks;
  }

  Map<String, List<Task>> getTasksByProject() {
    final user = _auth.currentUser;
    if (user == null) return {};

    final Map<String, List<Task>> tasksByProjectId = {};

    for (var task in state.tasks) {
      if (task.userId != user.uid) continue;
      if (task.category == 'Trash') continue;

      final currentProjectId = task.projectId ?? 'no_project_id';

      if (!tasksByProjectId.containsKey(currentProjectId)) {
        tasksByProjectId[currentProjectId] = [];
      }
      tasksByProjectId[currentProjectId]!.add(task);
    }
    return tasksByProjectId;
  }

  String calculateTotalTime(List<Task> tasks) {
    final user = _auth.currentUser;
    if (user == null) return '00:00';

    int totalPomodoros = 0;
    for (var task in tasks) {
      if (task.userId != user.uid) continue; // Chỉ tính task của user hiện tại
      totalPomodoros += task.estimatedPomodoros ?? 0;
    }
    int totalMinutes = totalPomodoros * 25;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String calculateElapsedTime(List<Task> tasks) {
    final user = _auth.currentUser;
    if (user == null) return '00:00';

    int elapsedPomodoros = 0;
    for (var task in tasks) {
      if (task.userId != user.uid) continue; // Chỉ tính task của user hiện tại
      elapsedPomodoros += task.completedPomodoros ?? 0;
    }
    int totalMinutes = elapsedPomodoros * 25;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}