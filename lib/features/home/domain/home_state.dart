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
  final String timerMode;
  final int workDuration;
  final int breakDuration;
  final bool soundEnabled;
  final bool autoSwitch;
  final bool isWorkSession;
  final String notificationSound;
  final bool isWhiteNoiseEnabled; // Thêm: trạng thái bật/tắt white noise
  final String? selectedWhiteNoise; // Thêm: âm thanh white noise được chọn
  final double whiteNoiseVolume;

  const HomeState({
    this.selectedTask,
    this.timerSeconds = 25 * 60, // Mặc định 25 phút
    this.isTimerRunning = false,
    this.isPaused = false,
    this.currentSession = 0,
    this.totalSessions = 4,
    this.isStrictModeEnabled = false,
    this.isAppBlockingEnabled = false,
    this.isFlipPhoneEnabled = false,
    this.isExitBlockingEnabled = false,
    this.blockedApps = const [],
    this.timerMode = 'Pomodoro',
    this.workDuration = 25, // Mặc định 25 phút
    this.breakDuration = 5, // Mặc định 5 phút
    this.soundEnabled = true,
    this.autoSwitch = false,
    this.isWorkSession = true,
    this.notificationSound = 'bell',
    this.isWhiteNoiseEnabled = false, // Mặc định tắt
    this.selectedWhiteNoise, // Mặc định không chọn âm thanh
    this.whiteNoiseVolume = 1.0, // Mặc định âm lượng 50%
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
    String? timerMode,
    int? workDuration,
    int? breakDuration,
    bool? soundEnabled,
    bool? autoSwitch,
    bool? isWorkSession,
    String? notificationSound,
    bool? isWhiteNoiseEnabled, // Thêm
    String? selectedWhiteNoise, // Thêm
    double? whiteNoiseVolume,
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
      timerMode: timerMode ?? this.timerMode,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      autoSwitch: autoSwitch ?? this.autoSwitch,
      isWorkSession: isWorkSession ?? this.isWorkSession,
      notificationSound: notificationSound ?? this.notificationSound,
      isWhiteNoiseEnabled: isWhiteNoiseEnabled ?? this.isWhiteNoiseEnabled,
      selectedWhiteNoise: selectedWhiteNoise ?? this.selectedWhiteNoise,
      whiteNoiseVolume: whiteNoiseVolume ?? this.whiteNoiseVolume,
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
    timerMode,
    workDuration,
    breakDuration,
    soundEnabled,
    autoSwitch,
    isWorkSession,
    notificationSound,
    isWhiteNoiseEnabled,
    selectedWhiteNoise,
    whiteNoiseVolume,
  ];
}