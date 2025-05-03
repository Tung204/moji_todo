import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final String? selectedTask;
  final int timerSeconds;
  final bool isTimerRunning;
  final bool isPaused;
  final int currentSession;
  final int totalSessions;

  const HomeState({
    this.selectedTask,
    this.timerSeconds = 25 * 60,
    this.isTimerRunning = false,
    this.isPaused = false,
    this.currentSession = 0,
    this.totalSessions = 4, // Mặc định 4 phiên Pomodoro
  });

  HomeState copyWith({
    String? selectedTask,
    int? timerSeconds,
    bool? isTimerRunning,
    bool? isPaused,
    int? currentSession,
    int? totalSessions,
  }) {
    return HomeState(
      selectedTask: selectedTask ?? this.selectedTask,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isPaused: isPaused ?? this.isPaused,
      currentSession: currentSession ?? this.currentSession,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }

  @override
  List<Object?> get props => [
    selectedTask,
    timerSeconds,
    isTimerRunning,
    isPaused,
    currentSession,
    totalSessions,
  ];
}