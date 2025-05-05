import 'dart:async';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
        final taskDoc = snapshot.docs.first;
        final task = Task.fromJson(taskDoc.data());
        emit(state.copyWith(
          selectedTask: task.title,
          timerSeconds: task.remainingPomodoroSeconds ?? 25 * 60,
          isTimerRunning: true,
          isPaused: false,
          currentSession: task.completedPomodoros ?? 0,
          totalSessions: task.estimatedPomodoros ?? 4,
        ));
        _startTimer(task.remainingPomodoroSeconds ?? 25 * 60);
      }
    });
  }

  void selectTask(String taskTitle, int estimatedPomodoros) {
    emit(state.copyWith(
      selectedTask: taskTitle,
      totalSessions: estimatedPomodoros,
      currentSession: 0,
      timerSeconds: 25 * 60,
      isTimerRunning: false,
      isPaused: false,
    ));
  }

  void startTimer() {
    if (state.isTimerRunning) return;

    const int defaultDuration = 25 * 60;
    emit(state.copyWith(
      timerSeconds: defaultDuration,
      isTimerRunning: true,
      isPaused: false,
      currentSession: state.currentSession + 1,
    ));

    _resetPreviousPomodoro();
    _startTimer(defaultDuration);
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, defaultDuration);
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

  void stopTimer() {
    _timer?.cancel();
    emit(state.copyWith(
      timerSeconds: 25 * 60,
      isTimerRunning: false,
      isPaused: false,
      currentSession: 0,
    ));
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, false, 0);
    }
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
        emit(state.copyWith(
          timerSeconds: 0,
          isTimerRunning: false,
          isPaused: false,
        ));
        if (state.selectedTask != null) {
          _updateTaskPomodoroState(state.selectedTask, false, 0);
        }
        _showNotification();
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

  Future<void> _showNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      channelDescription: 'Notifications for Pomodoro completion',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Pomodoro Completed',
      state.selectedTask != null
          ? 'Your Pomodoro for "${state.selectedTask}" has finished!'
          : 'Your Pomodoro has finished!',
      platformDetails,
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}