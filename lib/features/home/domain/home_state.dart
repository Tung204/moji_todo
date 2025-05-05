import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final String? selectedTask;
  final int timerSeconds;
  final bool isTimerRunning;
  final bool isPaused;
  final int currentSession;
  final int totalSessions;
  final bool isStrictModeEnabled;
  final bool isAppBlockingEnabled;
  final bool isFlipPhoneEnabled;
  final bool isExitBlockingEnabled;
  final List<String> blockedApps;

  const HomeState({
    this.selectedTask,
    this.timerSeconds = 25 * 60,
    this.isTimerRunning = false,
    this.isPaused = false,
    this.currentSession = 0,
    this.totalSessions = 4,
    this.isStrictModeEnabled = false,
    this.isAppBlockingEnabled = false,
    this.isFlipPhoneEnabled = false,
    this.isExitBlockingEnabled = false,
    this.blockedApps = const [],
  });

  HomeState copyWith({
    String? selectedTask,
    int? timerSeconds,
    bool? isTimerRunning,
    bool? isPaused,
    int? currentSession,
    int? totalSessions,
    bool? isStrictModeEnabled,
    bool? isAppBlockingEnabled,
    bool? isFlipPhoneEnabled,
    bool? isExitBlockingEnabled,
    List<String>? blockedApps,
  }) {
    return HomeState(
      selectedTask: selectedTask ?? this.selectedTask,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isPaused: isPaused ?? this.isPaused,
      currentSession: currentSession ?? this.currentSession,
      totalSessions: totalSessions ?? this.totalSessions,
      isStrictModeEnabled: isStrictModeEnabled ?? this.isStrictModeEnabled,
      isAppBlockingEnabled: isAppBlockingEnabled ?? this.isAppBlockingEnabled,
      isFlipPhoneEnabled: isFlipPhoneEnabled ?? this.isFlipPhoneEnabled,
      isExitBlockingEnabled: isExitBlockingEnabled ?? this.isExitBlockingEnabled,
      blockedApps: blockedApps ?? this.blockedApps,
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
    isStrictModeEnabled,
    isAppBlockingEnabled,
    isFlipPhoneEnabled,
    isExitBlockingEnabled,
    blockedApps,
  ];
}