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
    emit(state.copyWith(isLoading: true)); // Bật trạng thái loading
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], isLoading: false));
      return;
    }
    final tasks = await repository.getTasks();
    emit(state.copyWith(tasks: tasks, isLoading: false)); // Tắt trạng thái loading
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

    emit(state.copyWith(isLoading: true)); // Bật trạng thái loading
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

    emit(state.copyWith(tasks: filteredTasks, isLoading: false)); // Tắt trạng thái loading
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