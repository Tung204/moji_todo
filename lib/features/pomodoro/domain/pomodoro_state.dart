part of 'pomodoro_cubit.dart';

enum SessionType { work, shortBreak, longBreak }

class PomodoroState extends Equatable {
  final bool isRunning;
  final int secondsLeft;
  final SessionType sessionType;
  final int cycleCount;
  final int workDuration; // minutes
  final int shortBreakDuration; // minutes
  final int longBreakDuration; // minutes

  const PomodoroState({
    this.isRunning = false,
    this.secondsLeft = 25 * 60,
    this.sessionType = SessionType.work,
    this.cycleCount = 0,
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
  });

  PomodoroState copyWith({
    bool? isRunning,
    int? secondsLeft,
    SessionType? sessionType,
    int? cycleCount,
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
  }) {
    return PomodoroState(
      isRunning: isRunning ?? this.isRunning,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      sessionType: sessionType ?? this.sessionType,
      cycleCount: cycleCount ?? this.cycleCount,
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
    );
  }

  @override
  List<Object> get props => [
    isRunning,
    secondsLeft,
    sessionType,
    cycleCount,
    workDuration,
    shortBreakDuration,
    longBreakDuration,
  ];
}