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
const String prefWhiteNoiseEnabled = "whiteNoiseEnabled";
const String prefSelectedWhiteNoise = "selectedWhiteNoise";
const String prefWhiteNoiseVolume = "whiteNoiseVolume";
const String prefIsCountingUp = "isCountingUp";

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

    final prefs = await SharedPreferences.getInstance();
    final isWhiteNoiseEnabled = prefs.getBool(prefWhiteNoiseEnabled) ?? false;
    final selectedWhiteNoise = prefs.getString(prefSelectedWhiteNoise) ?? 'none';
    final whiteNoiseVolume = prefs.getDouble(prefWhiteNoiseVolume) ?? 1.0;
    final isCountingUp = prefs.getBool(prefIsCountingUp) ?? false;
    emit(state.copyWith(
      isWhiteNoiseEnabled: isWhiteNoiseEnabled,
      selectedWhiteNoise: selectedWhiteNoise,
      whiteNoiseVolume: whiteNoiseVolume,
      isCountingUp: isCountingUp,
    ));

    _timerSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final args = event as Map;
      final timerSeconds = args['timerSeconds'] as int;
      final isRunning = args['isRunning'] as bool;
      final isPaused = args['isPaused'] as bool;
      final isCountingUp = args['isCountingUp'] as bool? ?? state.isCountingUp;

      emit(state.copyWith(
        timerSeconds: timerSeconds,
        isTimerRunning: isRunning && !isPaused,
        isPaused: isPaused,
        isCountingUp: isCountingUp,
      ));

      if (!isCountingUp && timerSeconds <= 0 && isRunning && !isPaused) {
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
      print('Received timer update: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp');
    }, onError: (e) {
      print('Error in timer event stream: $e');
    });

    _notificationChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'startBreak':
          emit(state.copyWith(
            timerSeconds: state.breakDuration * 60,
            isWorkSession: false,
            isTimerRunning: state.autoSwitch,
            isPaused: !state.autoSwitch,
            isCountingUp: false,
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
            isCountingUp: false,
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
            isCountingUp: false,
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
      isCountingUp: state.isCountingUp,
    ));
  }

  void startTimer() {
    if (state.isTimerRunning) {
      print('Timer already running, ignoring start');
      return;
    }

    int timerSeconds;
    if (state.isCountingUp) {
      timerSeconds = 0;
    } else {
      timerSeconds = state.isWorkSession ? state.workDuration * 60 : state.breakDuration * 60;
      if (timerSeconds <= 0) {
        print('Invalid timer duration for counting down mode');
        return;
      }
    }

    emit(state.copyWith(
      timerSeconds: timerSeconds,
      isTimerRunning: true,
      isPaused: false,
      currentSession: state.isWorkSession ? state.currentSession + 1 : state.currentSession,
    ));

    _resetPreviousPomodoro();
    _updateSharedPreferences(timerSeconds, true, false);
    _startTimer(timerSeconds);
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, timerSeconds);
    }
    if (state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none') {
      _playWhiteNoise(state.selectedWhiteNoise!);
    }
  }

  void pauseTimer() {
    if (!state.isTimerRunning || state.isPaused) {
      print('Timer not running or already paused, ignoring pause');
      return;
    }

    emit(state.copyWith(
      isTimerRunning: false,
      isPaused: true,
    ));
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, false, state.timerSeconds);
    }

    try {
      _notificationChannel.invokeMethod(TimerActions.pause);
    } catch (e) {
      print('Error sending PAUSE intent: $e');
    }
    _updateSharedPreferences(state.timerSeconds, false, true);
    _audioPlayer.pause();
  }

  void continueTimer() {
    if (state.isTimerRunning || !state.isPaused) {
      print('Timer not paused or already running, ignoring continue');
      return;
    }

    emit(state.copyWith(
      isTimerRunning: true,
      isPaused: false,
    ));

    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, state.timerSeconds);
    }
    _updateSharedPreferences(state.timerSeconds, true, false);

    try {
      _notificationChannel.invokeMethod(TimerActions.resume);
    } catch (e) {
      print('Error sending RESUME intent: $e');
    }

    final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
    }
    if (state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none') {
      _playWhiteNoise(state.selectedWhiteNoise!);
    }
  }

  void stopTimer({bool updateTaskState = true}) {
    emit(state.copyWith(
      timerSeconds: state.isCountingUp ? 0 : state.workDuration * 60,
      isTimerRunning: false,
      isPaused: false,
      currentSession: 0,
      isWorkSession: true,
    ));
    if (updateTaskState && state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, false, 0);
    }

    try {
      _notificationChannel.invokeMethod(TimerActions.stop);
    } catch (e) {
      print('Error sending STOP intent: $e');
    }
    _updateSharedPreferences(state.isCountingUp ? 0 : state.workDuration * 60, false, false);
    _audioPlayer.stop();
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
      return;
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

    if (newExitBlockingEnabled && state.isWhiteNoiseEnabled) {
      _audioPlayer.pause();
    } else if (!newExitBlockingEnabled && state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none' && state.isTimerRunning) {
      _playWhiteNoise(state.selectedWhiteNoise!);
    }
  }

  void updateBlockedApps(List<String> blockedApps) {
    if (state.isTimerRunning && !state.isPaused) {
      print('Cannot update blocked apps: Timer is running');
      return;
    }
    if (state.isAppBlockingEnabled && blockedApps.isEmpty) {
      print('Cannot save empty blocked apps when App Blocking is enabled');
      return;
    }
    emit(state.copyWith(blockedApps: blockedApps));
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
      return;
    }

    bool isCountingUp = false;
    int newWorkDuration = workDuration;
    int newBreakDuration = breakDuration;
    bool newAutoSwitch = autoSwitch;

    // Validate inputs
    if (newWorkDuration < 1 || newWorkDuration > 480) {
      newWorkDuration = 25;
    }
    if (newBreakDuration < 1 || newBreakDuration > 60) {
      newBreakDuration = 5;
    }
    final newTotalSessions = totalSessions ?? state.totalSessions;
    if (newTotalSessions < 1 || newTotalSessions > 10) {
      totalSessions = 4;
    }

    switch (timerMode) {
      case '25:00 - 00:00':
        newWorkDuration = 25;
        newBreakDuration = 5;
        isCountingUp = false;
        break;
      case '00:00 - 0∞':
        newWorkDuration = 0;
        newBreakDuration = 0;
        isCountingUp = true;
        newAutoSwitch = false;
        break;
      case 'Tùy chỉnh':
        isCountingUp = false;
        break;
    }

    emit(state.copyWith(
      timerMode: timerMode,
      workDuration: newWorkDuration,
      breakDuration: newBreakDuration,
      soundEnabled: soundEnabled,
      autoSwitch: newAutoSwitch,
      notificationSound: notificationSound,
      totalSessions: totalSessions ?? newTotalSessions,
      timerSeconds: state.isTimerRunning ? state.timerSeconds : (newWorkDuration * 60),
      isWorkSession: true,
      isCountingUp: isCountingUp,
    ));
    _updateSharedPreferences(state.isTimerRunning ? state.timerSeconds : (newWorkDuration * 60), false, false);
  }

  void restoreTimerState({
    required int timerSeconds,
    required bool isRunning,
    required bool isPaused,
    required bool isCountingUp,
  }) {
    emit(state.copyWith(
      timerSeconds: timerSeconds,
      isTimerRunning: isRunning && !isPaused,
      isPaused: isPaused,
      isCountingUp: isCountingUp,
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

  void toggleWhiteNoise(bool enable) async {
    emit(state.copyWith(isWhiteNoiseEnabled: enable));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefWhiteNoiseEnabled, enable);

    if (enable && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none' && state.isTimerRunning) {
      _playWhiteNoise(state.selectedWhiteNoise!);
    } else {
      _audioPlayer.stop();
    }
  }

  void selectWhiteNoise(String sound) async {
    emit(state.copyWith(
      selectedWhiteNoise: sound,
      isWhiteNoiseEnabled: sound != 'none',
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefSelectedWhiteNoise, sound);

    if (sound != 'none' && state.isWhiteNoiseEnabled && state.isTimerRunning) {
      _playWhiteNoise(sound);
    } else {
      _audioPlayer.stop();
    }
  }

  void setWhiteNoiseVolume(double volume) async {
    emit(state.copyWith(whiteNoiseVolume: volume));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(prefWhiteNoiseVolume, volume);

    if (state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none' && state.isTimerRunning) {
      await _audioPlayer.setVolume(volume);
    }
  }

  Future<void> _playWhiteNoise(String sound) async {
    if (sound == 'none' || sound.isEmpty) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource('sounds/whiteNoise/$sound.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(state.whiteNoiseVolume);
      final playbackRate = ['clock_ticking'].contains(sound) ? 0.8 : 1.0;
      await _audioPlayer.setPlaybackRate(playbackRate);
      if (state.isTimerRunning && !state.isPaused) {
        await _audioPlayer.resume();
        print('Playing white noise: $sound');
      }
    } catch (e) {
      print('Error playing white noise: $e');
    }
  }

  Future<void> _startTimer(int seconds) async {
    final intent = {
      'action': TimerActions.start,
      'timerSeconds': seconds,
      'isRunning': true,
      'isPaused': false,
      'isCountingUp': state.isCountingUp,
    };
    print('Sending START intent: $intent');
    for (int i = 0; i < 3; i++) {
      try {
        await _notificationChannel.invokeMethod('startTimerService', intent);
        break;
      } catch (e) {
        print('Retry ${i+1}/3: Error starting timer: $e');
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
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
    await prefs.setBool(prefIsCountingUp, state.isCountingUp);
    print('Updated SharedPreferences: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=${state.isCountingUp}');
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}