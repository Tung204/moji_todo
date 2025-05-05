part of 'task_cubit.dart';

class TaskState extends Equatable {
  final List<Task> tasks;
  final bool isLoading; // Thêm trạng thái isLoading

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [tasks, isLoading];
}