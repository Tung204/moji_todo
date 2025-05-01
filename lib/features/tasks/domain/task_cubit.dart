import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/task_model.dart';
import '../data/task_repository.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskRepository repository;

  TaskCubit(this.repository) : super(const TaskState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final tasks = await repository.getTasks();
    emit(state.copyWith(tasks: tasks));
  }

  Future<void> addTask(Task task) async {
    await repository.addTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await repository.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await repository.deleteTask(id);
    await loadTasks();
  }

  void sortTasks(String criteria) {
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

  // Phân loại task theo danh mục
  Map<String, List<Task>> getCategorizedTasks() {
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
      if (task.dueDate == null) {
        categorizedTasks['Planned']!.add(task);
      } else {
        final dueDate = task.dueDate!;
        if (dueDate.year == today.year &&
            dueDate.month == today.month &&
            dueDate.day == today.day) {
          categorizedTasks['Today']!.add(task);
        } else if (dueDate.year == tomorrow.year &&
            dueDate.month == tomorrow.month &&
            dueDate.day == tomorrow.day) {
          categorizedTasks['Tomorrow']!.add(task);
        } else if (dueDate.isAfter(today) && dueDate.isBefore(thisWeekEnd)) {
          categorizedTasks['This Week']!.add(task);
        } else if (dueDate.isAfter(thisWeekEnd)) {
          categorizedTasks['Planned']!.add(task);
        }
      }
    }

    return categorizedTasks;
  }

  // Phân loại task theo project
  Map<String, List<Task>> getTasksByProject() {
    final Map<String, List<Task>> tasksByProject = {};

    for (var task in state.tasks) {
      final project = task.project ?? 'General';
      if (!tasksByProject.containsKey(project)) {
        tasksByProject[project] = [];
      }
      tasksByProject[project]!.add(task);
    }

    return tasksByProject;
  }

  // Tính tổng thời gian của một danh sách task (giả sử 1 Pomodoro = 25 phút)
  String calculateTotalTime(List<Task> tasks) {
    int totalPomodoros = 0;
    for (var task in tasks) {
      totalPomodoros += task.estimatedPomodoros ?? 0;
    }
    int totalMinutes = totalPomodoros * 25;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}