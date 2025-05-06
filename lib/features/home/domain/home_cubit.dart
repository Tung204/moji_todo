import 'dart:async';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../tasks/data/models/task_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState()) {
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _timer;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(initializationSettings);

    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('isPomodoroActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        if (state.selectedTask == null) {
          final taskDoc = snapshot.docs.first;
          final task = Task.fromJson(taskDoc.data());
          emit(state.copyWith(
            selectedTask: task.title,
            timerSeconds: task.remainingPomodoroSeconds ?? (state.workDuration * 60),
            isTimerRunning: true,
            isPaused: false,
            currentSession: task.completedPomodoros ?? 0,
            totalSessions: task.estimatedPomodoros ?? state.totalSessions,
            isWorkSession: true,
          ));
          _startTimer(task.remainingPomodoroSeconds ?? (state.workDuration * 60));
        }
      }
    });
  }

  void selectTask(String? taskTitle, int estimatedPomodoros) {
    emit(state.copyWith(
      selectedTask: taskTitle,
      totalSessions: taskTitle != null ? estimatedPomodoros : state.totalSessions,
      currentSession: 0,
      timerSeconds: state.workDuration * 60,
      isTimerRunning: false,
      isPaused: false,
      isWorkSession: true,
    ));
  }

  void startTimer() {
    if (state.isTimerRunning) return;

    emit(state.copyWith(
      timerSeconds: state.isWorkSession ? state.workDuration * 60 : state.breakDuration * 60,
      isTimerRunning: true,
      isPaused: false,
      currentSession: state.isWorkSession ? state.currentSession + 1 : state.currentSession,
    ));

    _resetPreviousPomodoro();
    _startTimer(state.timerSeconds);
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, state.timerSeconds);
    }
  }

  void pauseTimer() {
    if (!state.isTimerRunning || state.isPaused) return;

    _timer?.cancel();
    emit(state.copyWith(
      isTimerRunning: false,
      isPaused: true,
    ));
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, false, state.timerSeconds);
    }
  }

  void continueTimer() {
    if (state.isTimerRunning || !state.isPaused) return;

    emit(state.copyWith(
      isTimerRunning: true,
      isPaused: false,
    ));
    _startTimer(state.timerSeconds);
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, state.timerSeconds);
    }
  }

  void stopTimer({bool updateTaskState = true}) {
    _timer?.cancel();
    emit(state.copyWith(
      timerSeconds: state.workDuration * 60,
      isTimerRunning: false,
      isPaused: false,
      currentSession: 0,
      isWorkSession: true,
    ));
    if (updateTaskState && state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, false, 0);
    }
  }

  void resetTask() async {
    if (state.selectedTask != null) {
      await _updateTaskPomodoroState(state.selectedTask, false, 0);
    }
    stopTimer(updateTaskState: false);
    selectTask(null, state.totalSessions);
  }

  void updateStrictMode({
    bool? isAppBlockingEnabled,
    bool? isFlipPhoneEnabled,
    bool? isExitBlockingEnabled,
  }) {
    final newAppBlockingEnabled = isAppBlockingEnabled ?? state.isAppBlockingEnabled;
    final newFlipPhoneEnabled = isFlipPhoneEnabled ?? state.isFlipPhoneEnabled;
    final newExitBlockingEnabled = isExitBlockingEnabled ?? state.isExitBlockingEnabled;

    final isStrictModeEnabled = newAppBlockingEnabled || newFlipPhoneEnabled || newExitBlockingEnabled;

    emit(state.copyWith(
      isStrictModeEnabled: isStrictModeEnabled,
      isAppBlockingEnabled: newAppBlockingEnabled,
      isFlipPhoneEnabled: newFlipPhoneEnabled,
      isExitBlockingEnabled: newExitBlockingEnabled,
    ));
  }

  void updateBlockedApps(List<String> blockedApps) {
    emit(state.copyWith(
      blockedApps: blockedApps,
    ));
  }

  void updateTimerMode({
    required String timerMode,
    required int workDuration,
    required int breakDuration,
    required bool soundEnabled,
    required bool autoSwitch,
    required String notificationSound,
    int? totalSessions,
  }) {
    emit(state.copyWith(
      timerMode: timerMode,
      workDuration: workDuration,
      breakDuration: breakDuration,
      soundEnabled: soundEnabled,
      autoSwitch: autoSwitch,
      notificationSound: notificationSound,
      totalSessions: totalSessions ?? state.totalSessions,
      timerSeconds: state.isTimerRunning ? state.timerSeconds : (workDuration * 60),
      isWorkSession: true,
    ));
  }
  void restoreTimerState({
    required int timerSeconds,
    required bool isRunning,
    required bool isPaused,
  }) {
    emit(state.copyWith(
      timerSeconds: timerSeconds,
      isTimerRunning: isRunning,
      isPaused: isPaused,
    ));
  }
  void _startTimer(int seconds) {
    int remainingSeconds = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isTimerRunning || state.isPaused) {
        timer.cancel();
        return;
      }
      remainingSeconds--;
      if (remainingSeconds <= 0) {
        timer.cancel();
        if (state.soundEnabled) {
          _playSound();
          _showNotification();
        }
        if (state.autoSwitch) {
          if (state.isWorkSession) {
            emit(state.copyWith(
              timerSeconds: state.breakDuration * 60,
              isWorkSession: false,
              isTimerRunning: true,
              isPaused: false,
            ));
            _startTimer(state.breakDuration * 60);
          } else {
            if (state.currentSession < state.totalSessions) {
              emit(state.copyWith(
                timerSeconds: state.workDuration * 60,
                isWorkSession: true,
                isTimerRunning: true,
                isPaused: false,
                currentSession: state.currentSession + 1,
              ));
              _startTimer(state.workDuration * 60);
            } else {
              emit(state.copyWith(
                timerSeconds: state.workDuration * 60,
                isTimerRunning: false,
                isPaused: false,
                currentSession: 0,
                isWorkSession: true,
              ));
              if (state.selectedTask != null) {
                _updateTaskPomodoroState(state.selectedTask, false, 0);
              }
            }
          }
        } else {
          emit(state.copyWith(
            timerSeconds: state.isWorkSession ? state.breakDuration * 60 : state.workDuration * 60,
            isTimerRunning: false,
            isPaused: false,
            isWorkSession: !state.isWorkSession,
          ));
          if (state.selectedTask != null) {
            _updateTaskPomodoroState(state.selectedTask, false, state.timerSeconds);
          }
        }
      } else {
        emit(state.copyWith(timerSeconds: remainingSeconds));
        if (state.selectedTask != null) {
          _updateTaskPomodoroState(state.selectedTask, true, remainingSeconds);
        }
      }
    });
  }

  Future<void> _resetPreviousPomodoro() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('isPomodoroActive', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'isPomodoroActive': false,
        'remainingPomodoroSeconds': 0,
      });
    }
  }

  Future<void> _updateTaskPomodoroState(String? taskTitle, bool isActive, int remainingSeconds) async {
    final user = _auth.currentUser;
    if (user == null || taskTitle == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('title', isEqualTo: taskTitle)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final taskDoc = snapshot.docs.first;
      await taskDoc.reference.update({
        'isPomodoroActive': isActive,
        'remainingPomodoroSeconds': remainingSeconds,
        'completedPomodoros': state.currentSession,
      });
    }
  }

  Future<void> _playSound() async {
    if (!state.soundEnabled) return;

    String soundFile = 'assets/sounds/${state.notificationSound}.mp3';
    await _audioPlayer.play(AssetSource(soundFile.substring('assets/'.length)));
  }

  Future<void> _showNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      channelDescription: 'Notifications for Pomodoro completion',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: false, // Tắt âm thanh mặc định
      enableVibration: false, // Tắt rung
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      state.isWorkSession ? 'Hết phiên làm việc' : 'Hết phiên nghỉ',
      state.selectedTask != null
          ? 'Your ${state.isWorkSession ? "work" : "break"} session for "${state.selectedTask}" has finished!'
          : 'Your ${state.isWorkSession ? "work" : "break"} session has finished!',
      platformDetails,
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}