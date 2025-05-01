part of 'home_cubit.dart';

class HomeState extends Equatable {
  final int timerMinutes;
  final bool isTimerRunning;
  final String? selectedTask;

  const HomeState({
    this.timerMinutes = 25,
    this.isTimerRunning = false,
    this.selectedTask,
  });

  HomeState copyWith({
    int? timerMinutes,
    bool? isTimerRunning,
    String? selectedTask,
  }) {
    return HomeState(
      timerMinutes: timerMinutes ?? this.timerMinutes,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      selectedTask: selectedTask ?? this.selectedTask,
    );
  }

  @override
  List<Object?> get props => [timerMinutes, isTimerRunning, selectedTask];
}