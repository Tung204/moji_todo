import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/gemini_service.dart';
import '../data/models/task_model.dart';
import '../data/task_repository.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskRepository repository;
  final GeminiService _geminiService = GeminiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TaskCubit(this.repository) : super(const TaskState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    emit(state.copyWith(isLoading: true));
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], isLoading: false));
      return;
    }
    final tasks = await repository.getTasks();
    emit(state.copyWith(tasks: tasks, isLoading: false));
  }

  Future<void> addTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final category = await _geminiService.classifyTask(task.title ?? '');
    task = task.copyWith(category: category, userId: user.uid);
    await repository.addTask(task);
    await loadTasks();
  }

  void sortTasksByPriority() async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], isLoading: false));
      return;
    }
    final sortedTasks = List<Task>.from(state.tasks);
    sortedTasks.sort((a, b) => _priorityValue(a.priority).compareTo(_priorityValue(b.priority)));
    emit(state.copyWith(tasks: sortedTasks));
  }

  Future<void> searchTasks(String query) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    emit(state.copyWith(isLoading: true));
    final allTasks = await repository.getTasks();
    final geminiService = GeminiService();
    final filteredTasks = <Task>[];

    for (var task in allTasks) {
      final prompt = '''
      Kiểm tra xem task sau có phù hợp với query không:
      - Task title: "${task.title}"
      - Query: "$query"
      Trả về true/false.
      ''';
      final response = await geminiService.generateContent([Content.text(prompt)]);
      if (response.text?.trim().toLowerCase() == 'true') {
        filteredTasks.add(task);
      }
    }

    emit(state.copyWith(tasks: filteredTasks, isLoading: false));
  }

  Future<void> searchTasksInTrash(String query) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    emit(state.copyWith(isLoading: true));
    final allTasks = await repository.getTasks();
    final trashTasks = allTasks.where((task) => task.category == 'Trash').toList();
    final geminiService = GeminiService();
    final filteredTasks = <Task>[];

    for (var task in trashTasks) {
      final prompt = '''
      Kiểm tra xem task sau có phù hợp với query không:
      - Task title: "${task.title}"
      - Query: "$query"
      Trả về true/false.
      ''';
      final response = await geminiService.generateContent([Content.text(prompt)]);
      if (response.text?.trim().toLowerCase() == 'true') {
        filteredTasks.add(task);
      }
    }

    emit(state.copyWith(tasks: filteredTasks, isLoading: false));
  }

  Future<void> updateTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (task.userId != user.uid) throw Exception('Bạn không có quyền cập nhật task này.');

    await repository.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (task.userId != user.uid) throw Exception('Bạn không có quyền xóa task này.');

    await repository.deleteTask(task);
    await loadTasks();
  }

  Future<void> restoreTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (task.userId != user.uid) throw Exception('Bạn không có quyền khôi phục task này.');

    final restoredCategory = task.originalCategory ?? 'Planned';
    await repository.updateTask(task.copyWith(category: restoredCategory));
    await loadTasks();
  }

  void sortTasks(String criteria) {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], isLoading: false));
      return;
    }
    final sortedTasks = List<Task>.from(state.tasks);
    if (criteria == 'dueDate') {
      sortedTasks.sort((a, b) => a.dueDate?.compareTo(b.dueDate ?? DateTime.now()) ?? 0);
    } else if (criteria == 'priority') {
      sortedTasks.sort((a, b) => _priorityValue(a.priority).compareTo(_priorityValue(b.priority)));
    }
    emit(state.copyWith(tasks: sortedTasks));
  }

  void sortTasksInTrash(String criteria) {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], isLoading: false));
      return;
    }
    final trashTasks = state.tasks.where((task) => task.category == 'Trash').toList();
    final sortedTasks = List<Task>.from(state.tasks);

    if (criteria == 'title') {
      trashTasks.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
    } else if (criteria == 'deletedDate') {
      trashTasks.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    }

    // Cập nhật danh sách task, giữ các task không thuộc "Thùng rác" nguyên trạng
    final nonTrashTasks = state.tasks.where((task) => task.category != 'Trash').toList();
    sortedTasks.clear();
    sortedTasks.addAll(nonTrashTasks);
    sortedTasks.addAll(trashTasks);

    emit(state.copyWith(tasks: sortedTasks));
  }

  void toggleSelectionMode() {
    emit(state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedTasks: state.isSelectionMode ? [] : state.selectedTasks, // Xóa danh sách chọn khi thoát chế độ
    ));
  }

  void toggleTaskSelection(Task task) {
    final selectedTasks = List<Task>.from(state.selectedTasks);
    if (selectedTasks.contains(task)) {
      selectedTasks.remove(task);
    } else {
      selectedTasks.add(task);
    }
    emit(state.copyWith(selectedTasks: selectedTasks));
  }

  Future<void> restoreSelectedTasks() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    for (var task in state.selectedTasks) {
      if (task.userId != user.uid) continue;
      final restoredCategory = task.originalCategory ?? 'Planned';
      await repository.updateTask(task.copyWith(category: restoredCategory));
    }
    emit(state.copyWith(isSelectionMode: false, selectedTasks: []));
    await loadTasks();
  }

  Future<void> deleteSelectedTasks() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    for (var task in state.selectedTasks) {
      if (task.userId != user.uid) continue;
      await repository.deleteTask(task);
    }
    emit(state.copyWith(isSelectionMode: false, selectedTasks: []));
    await loadTasks();
  }

  int _priorityValue(String? priority) {
    switch (priority) {
      case 'High':
        return 1;
      case 'Medium':
        return 2;
      case 'Low':
        return 3;
      default:
        return 4;
    }
  }

  Map<String, List<Task>> getCategorizedTasks() {
    final user = _auth.currentUser;
    if (user == null) return {
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'Planned': [],
      'Completed': [],
      'Trash': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final thisWeekEnd = today.add(const Duration(days: 7));

    final Map<String, List<Task>> categorizedTasks = {
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'Planned': [],
      'Completed': [],
      'Trash': [],
    };

    for (var task in state.tasks) {
      if (task.userId != user.uid) continue;
      if (task.isCompleted == true) {
        categorizedTasks['Completed']!.add(task);
      } else if (task.category == 'Trash') {
        categorizedTasks['Trash']!.add(task);
      } else if (task.dueDate != null) {
        final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        if (dueDate.isAtSameMomentAs(today)) {
          categorizedTasks['Today']!.add(task);
        } else if (dueDate.isAtSameMomentAs(tomorrow)) {
          categorizedTasks['Tomorrow']!.add(task);
        } else if (dueDate.isAfter(today) && dueDate.isBefore(thisWeekEnd)) {
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

    final Map<String, List<Task>> tasksByProject = {};

    for (var task in state.tasks) {
      if (task.userId != user.uid) continue;
      final project = task.project ?? 'General';
      if (!tasksByProject.containsKey(project)) {
        tasksByProject[project] = [];
      }
      tasksByProject[project]!.add(task);
    }

    return tasksByProject;
  }

  String calculateTotalTime(List<Task> tasks) {
    final user = _auth.currentUser;
    if (user == null) return '00:00';

    int totalPomodoros = 0;
    for (var task in tasks) {
      if (task.userId != user.uid) continue;
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
      if (task.userId != user.uid) continue;
      elapsedPomodoros += task.completedPomodoros ?? 0;
    }
    int totalMinutes = elapsedPomodoros * 25;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}