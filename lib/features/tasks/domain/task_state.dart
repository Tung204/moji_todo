part of 'task_cubit.dart';

class TaskState extends Equatable {
  final List<Task> tasks;
  final bool isLoading;
  final bool isSelectionMode; // Thêm trạng thái để bật/tắt chế độ chọn nhiều
  final List<Task> selectedTasks; // Danh sách task được chọn

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isSelectionMode = false,
    this.selectedTasks = const [],
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? isSelectionMode,
    List<Task>? selectedTasks,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedTasks: selectedTasks ?? this.selectedTasks,
    );
  }

  @override
  List<Object> get props => [tasks, isLoading, isSelectionMode, selectedTasks];
}