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
}