import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/data/models/task_model.dart';
import 'home_state.dart';

const String prefTimerSeconds = "timerSeconds";
const String prefIsRunning = "isRunning";
const String prefIsPaused = "isPaused";

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState()) {
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _timer;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const MethodChannel _notificationChannel = MethodChannel('com.example.moji_todo/notification');
  static const MethodChannel _serviceChannel = MethodChannel('com.example.moji_todo/app_block_service');
  bool _lastAppBlockingState = false;

  Future<void> _initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(initializationSettings);

    final user = _auth.currentUser;
    if (user == null) return;

    _notificationChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'startBreak':
        // Chuyển sang "Phiên nghỉ" khi ấn vào thông báo "Hết phiên làm việc"
          emit(state.copyWith(
            timerSeconds: state.breakDuration * 60,
            isWorkSession: false,
            isTimerRunning: state.autoSwitch,
            isPaused: !state.autoSwitch,
          ));
          if (state.autoSwitch) {
            _startTimer(state.breakDuration * 60);
          }
          return null;
        case 'startWork':
        // Chuyển sang "Phiên làm việc" khi ấn vào thông báo "Hết phiên nghỉ"
          emit(state.copyWith(
            timerSeconds: state.workDuration * 60,
            isWorkSession: true,
            isTimerRunning: state.autoSwitch,
            isPaused: !state.autoSwitch,
            currentSession: state.currentSession + 1,
          ));
          if (state.autoSwitch) {
            _startTimer(state.workDuration * 60);
          }
          return null;
        default:
          return null;
      }
    });

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

    final intent = {
      'action': 'START',
      'timerSeconds': state.timerSeconds,
      'isRunning': true,
      'isPaused': false,
    };
    print('Sending START intent: $intent');
    _notificationChannel.invokeMethod('startTimerService', intent);
    _updateSharedPreferences(state.timerSeconds, true, false);

    final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
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

    final intent = {
      'action': 'com.example.moji_todo.PAUSE',
    };
    print('Sending PAUSE intent: $intent');
    _notificationChannel.invokeMethod('startTimerService', intent);
    _updateSharedPreferences(state.timerSeconds, false, true);

    final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
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

    final intent = {
      'action': 'com.example.moji_todo.RESUME',
    };
    print('Sending RESUME intent: $intent');
    _notificationChannel.invokeMethod('startTimerService', intent);
    _updateSharedPreferences(state.timerSeconds, true, false);

    final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
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

    final intent = {
      'action': 'com.example.moji_todo.STOP',
    };
    print('Sending STOP intent: $intent');
    _notificationChannel.invokeMethod('startTimerService', intent);
    _updateSharedPreferences(0, false, false);

    final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
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

    final newAppBlockingState = newAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
    }
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
    if (isRunning && !isPaused) {
      _startTimer(timerSeconds);
    }

    final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
    }
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
                // Hiển thị thông báo "Hoàn thành công việc"
                _showTaskCompletedNotification();
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
        _updateSharedPreferences(remainingSeconds, true, false, sendUpdate: true);
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
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      channelDescription: 'Notifications for Pomodoro completion',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      actions: [
        AndroidNotificationAction(
          'action_open',
          'Open',
          showsUserInterface: true,
        ),
      ],
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      state.isWorkSession ? 'Hết phiên làm việc' : 'Hết phiên nghỉ',
      state.selectedTask != null
          ? 'Your ${state.isWorkSession ? "work" : "break"} session for "${state.selectedTask}" has finished!'
          : 'Your ${state.isWorkSession ? "work" : "break"} session has finished!',
      platformDetails,
      payload: state.isWorkSession ? 'START_BREAK' : 'START_WORK',
    );
  }

  Future<void> _showTaskCompletedNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      channelDescription: 'Notifications for Pomodoro completion',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: false,
      enableVibration: false,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      1, // ID khác để không ghi đè thông báo "Hết phiên"
      'Hoàn thành công việc',
      state.selectedTask != null
          ? 'Bạn đã hoàn thành tất cả phiên Pomodoro cho "${state.selectedTask}"!'
          : 'Bạn đã hoàn thành tất cả phiên Pomodoro!',
      platformDetails,
    );
  }

  Future<void> _updateSharedPreferences(int timerSeconds, bool isRunning, bool isPaused, {bool sendUpdate = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefTimerSeconds, timerSeconds);
    await prefs.setBool(prefIsRunning, isRunning);
    await prefs.setBool(prefIsPaused, isPaused);

    if (sendUpdate) {
      final intent = {
        'action': 'UPDATE',
        'timerSeconds': timerSeconds,
        'isRunning': isRunning,
        'isPaused': isPaused,
      };
      print('Sending UPDATE intent from Flutter: $intent');
      await _notificationChannel.invokeMethod('startTimerService', intent);
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}