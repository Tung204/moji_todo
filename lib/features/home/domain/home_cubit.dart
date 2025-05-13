import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/data/models/task_model.dart';
import 'home_state.dart';

const String prefTimerSeconds = "timerSeconds";
const String prefIsRunning = "isRunning";
const String prefIsPaused = "isPaused";

class TimerActions {
  static const String start = 'START';
  static const String pause = 'com.example.moji_todo.PAUSE';
  static const String resume = 'com.example.moji_todo.RESUME';
  static const String stop = 'com.example.moji_todo.STOP';
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState()) {
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const MethodChannel _notificationChannel = MethodChannel('com.example.moji_todo/notification');
  static const MethodChannel _serviceChannel = MethodChannel('com.example.moji_todo/app_block_service');
  static const EventChannel _eventChannel = EventChannel('com.example.moji_todo/timer_events');
  StreamSubscription? _timerSubscription;
  bool _lastAppBlockingState = false;

  Future<void> _initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _timerSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final args = event as Map;
      final timerSeconds = args['timerSeconds'] as int;
      final isRunning = args['isRunning'] as bool;
      final isPaused = args['isPaused'] as bool;

      emit(state.copyWith(
        timerSeconds: timerSeconds,
        isTimerRunning: isRunning && !isPaused,
        isPaused: isPaused,
      ));
      _updateSharedPreferences(timerSeconds, isRunning, isPaused);
      print('Received timer update: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
      if (timerSeconds <= 0 && isRunning && !isPaused) {
        if (state.soundEnabled) {
          _playSound();
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
      }
    });

    _notificationChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'startBreak':
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
        case 'pause':
          pauseTimer();
          return null;
        case 'resume':
          continueTimer();
          return null;
        case 'stop':
          stopTimer();
          return null;
        default:
          return null;
      }
    });
    _listenToTasks(user.uid);
  }

  void _listenToTasks(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
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

    final timerSeconds = state.isWorkSession ? state.workDuration * 60 : state.breakDuration * 60;
    if (timerSeconds <= 0) return;

    emit(state.copyWith(
      timerSeconds: timerSeconds,
      isTimerRunning: true,
      isPaused: false,
      currentSession: state.isWorkSession ? state.currentSession + 1 : state.currentSession,
    ));

    _resetPreviousPomodoro();
    _startTimer(timerSeconds);
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, timerSeconds);
    }
  }

  void pauseTimer() {
    if (!state.isTimerRunning || state.isPaused) return;

    emit(state.copyWith(
      isTimerRunning: false,
      isPaused: true,
    ));
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, false, state.timerSeconds);
    }

    _notificationChannel.invokeMethod(TimerActions.pause).catchError((e) {
      print('Error sending PAUSE intent: $e');
    });
    _updateSharedPreferences(state.timerSeconds, false, true);
  }

  void continueTimer() {
    if (state.isTimerRunning || !state.isPaused) return;

    emit(state.copyWith(
      isTimerRunning: true,
      isPaused: false,
    ));

    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, state.timerSeconds);
    }
    _updateSharedPreferences(state.timerSeconds, true, false);

    _notificationChannel.invokeMethod('getTimerState').then((timerState) {
      if (timerState != null) {
        final serviceSeconds = timerState['timerSeconds'] as int? ?? state.timerSeconds;
        final serviceRunning = timerState['isRunning'] as bool? ?? false;
        final servicePaused = timerState['isPaused'] as bool? ?? true;
        emit(state.copyWith(
          timerSeconds: serviceSeconds,
          isTimerRunning: serviceRunning && !servicePaused,
          isPaused: servicePaused,
        ));
        print('Synced state from TimerService: timerSeconds=$serviceSeconds, isRunning=$serviceRunning, isPaused=$servicePaused');
      }
    }).catchError((e) {
      print('Error fetching timer state: $e');
    });

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

    _notificationChannel.invokeMethod(TimerActions.stop).catchError((e) {
      print('Error sending STOP intent: $e');
    });
    _updateSharedPreferences(state.workDuration * 60, false, false);
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
    if (state.isTimerRunning && !state.isPaused) {
      print('Cannot update Strict Mode: Timer is running');
      return; // Block update when timer is running
    }

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
    if (state.isTimerRunning && !state.isPaused) {
      print('Cannot update blocked apps: Timer is running');
      return; // Block update when timer is running
    }

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
    if (state.isTimerRunning && !state.isPaused) {
      print('Cannot update Timer Mode: Timer is running');
      return; // Block update when timer is running
    }

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
      isTimerRunning: isRunning && !isPaused,
      isPaused: isPaused,
    ));

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
    final intent = {
      'action': TimerActions.start,
      'timerSeconds': seconds,
      'isRunning': true,
      'isPaused': false,
    };
    print('Sending START intent: $intent');
    _notificationChannel.invokeMethod('startTimerService', intent).catchError((e) {
      print('Error starting timer: $e');
    });
    _updateSharedPreferences(seconds, true, false);
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

  Future<void> _updateSharedPreferences(int timerSeconds, bool isRunning, bool isPaused) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefTimerSeconds, timerSeconds);
    await prefs.setBool(prefIsRunning, isRunning);
    await prefs.setBool(prefIsPaused, isPaused);
    print('Updated SharedPreferences: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}