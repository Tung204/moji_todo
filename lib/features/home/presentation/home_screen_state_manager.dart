import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/home/domain/home_cubit.dart';
import 'package:moji_todo/features/home/presentation/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/unified_notification_service.dart';
import '../../tasks/data/models/task_model.dart';
import 'timer_state_handler.dart';

class HomeScreenStateManager {
  final BuildContext context;
  final Future<SharedPreferences> sharedPreferences;
  final Function(BuildContext) onShowTaskBottomSheet;
  final MethodChannel _channel = const MethodChannel('com.example.moji_todo/notification');
  final MethodChannel _serviceChannel = const MethodChannel('com.example.moji_todo/app_block_service');
  late final TimerStateHandler _timerStateHandler;
  late final PermissionHandler permissionHandler;
  bool _fromNotification = false;
  bool _isActionPending = false;

  HomeScreenStateManager({
    required this.context,
    required this.sharedPreferences,
    required this.onShowTaskBottomSheet,
  }) {
    _timerStateHandler = TimerStateHandler(
      homeCubit: context.read<HomeCubit>(),
      notificationChannel: _channel,
      sharedPreferences: sharedPreferences,
    );
    permissionHandler = PermissionHandler(
      context: context,
      notificationChannel: _channel,
      notificationService: UnifiedNotificationService(),
      onPermissionStateChanged: _updatePermissionState,
    );
  }

  Future<void> init() async {
    await _restoreTimerState();
    await _checkStrictMode();
  }

  Future<void> checkAndRequestPermissionsForTimer() async {
    await permissionHandler.checkNotificationPermission();
    await permissionHandler.checkBackgroundPermission();
  }

  Future<void> _restoreTimerState() async {
    await _timerStateHandler.restoreTimerState();
  }

  Future<void> _checkStrictMode() async {
    final prefs = await sharedPreferences;
    final isStrictModeEnabled = prefs.getBool('isStrictModeEnabled') ?? false;
    if (isStrictModeEnabled) {
      context.read<HomeCubit>().updateStrictMode(isAppBlockingEnabled: true);
      final isBlockAppsEnabled = prefs.getBool('isBlockAppsEnabled') ?? false;
      final blockedApps = prefs.getStringList('blockedApps') ?? [];
      if (isBlockAppsEnabled) {
        await _serviceChannel.invokeMethod('setBlockedApps', {'apps': blockedApps});
        await _serviceChannel.invokeMethod('setAppBlockingEnabled', {'enabled': true});
      }
    }
  }

  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    final homeCubit = context.read<HomeCubit>();
    if (state == AppLifecycleState.paused) {
      if (homeCubit.state.isTimerRunning && !homeCubit.state.isPaused) {
        final prefs = await sharedPreferences;
        await prefs.setInt('timerSeconds', homeCubit.state.timerSeconds);
        await prefs.setBool('isRunning', homeCubit.state.isTimerRunning);
        await prefs.setBool('isPaused', homeCubit.state.isPaused);
        await prefs.setBool('isCountingUp', homeCubit.state.isCountingUp);
        await prefs.setBool('isWorkSession', homeCubit.state.isWorkSession);
      }
      _fromNotification = false;
    } else if (state == AppLifecycleState.resumed) {
      if (_fromNotification) {
        final prefs = await sharedPreferences;
        int timerSeconds = prefs.getInt('timerSeconds') ?? 25 * 60;
        bool isRunning = prefs.getBool('isRunning') ?? false;
        bool isPaused = prefs.getBool('isPaused') ?? false;
        bool isCountingUp = prefs.getBool('isCountingUp') ?? false;
        homeCubit.restoreTimerState(
          timerSeconds: timerSeconds,
          isRunning: isRunning,
          isPaused: isPaused,
          isCountingUp: isCountingUp,
        );
        print('Restored state from notification: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp');
      } else {
        await _restoreTimerState();
      }
      if (homeCubit.state.isStrictModeEnabled && homeCubit.state.isTimerRunning && homeCubit.state.isFlipPhoneEnabled) {
        try {
          await _channel.invokeMethod('startTimerService', {
            'action': 'UPDATE',
            'timerSeconds': homeCubit.state.timerSeconds,
            'isRunning': homeCubit.state.isTimerRunning,
            'isPaused': homeCubit.state.isPaused,
            'isCountingUp': homeCubit.state.isCountingUp,
          });
        } catch (e) {
          print('Error updating timer service: $e');
        }
      }
      _fromNotification = false;
    }
  }

  Future<void> setFromNotification() async {
    _fromNotification = true;
    print('Set _fromNotification to true');
  }

  Future<void> handleTimerAction(String action, {Task? task, int? estimatedPomodoros}) async {
    if (_isActionPending) {
      print('Action pending, ignoring: $action');
      return;
    }

    _isActionPending = true;
    final homeCubit = context.read<HomeCubit>();
    final prefs = await sharedPreferences;

    bool canProceed = true;
    switch (action) {
      case 'start':
        if (homeCubit.state.isTimerRunning) {
          print('Timer already running, ignoring start action');
          canProceed = false;
        }
        break;
      case 'pause':
        if (!homeCubit.state.isTimerRunning || homeCubit.state.isPaused) {
          print('Timer not running or already paused, ignoring pause action');
          canProceed = false;
        }
        break;
      case 'continue':
        if (homeCubit.state.isTimerRunning || !homeCubit.state.isPaused) {
          print('Timer not paused or already running, ignoring continue action');
          canProceed = false;
        }
        break;
      case 'stop':
        if (!homeCubit.state.isTimerRunning && !homeCubit.state.isPaused) {
          print('Timer not running or paused, ignoring stop action');
          canProceed = false;
        }
        break;
    }

    if (!canProceed) {
      _isActionPending = false;
      return;
    }

    switch (action) {
      case 'start':
        try {
          await checkAndRequestPermissionsForTimer();
          if (task != null && estimatedPomodoros != null) {
            homeCubit.selectTask(task.title, estimatedPomodoros);
          }
          homeCubit.startTimer();
          await _channel.invokeMethod('startTimerService', {
            'action': 'START',
            'timerSeconds': homeCubit.state.timerSeconds,
            'isRunning': true,
            'isPaused': false,
            'isCountingUp': homeCubit.state.isCountingUp,
          });
          await prefs.setInt('timerSeconds', homeCubit.state.timerSeconds);
          await prefs.setBool('isRunning', true);
          await prefs.setBool('isPaused', false);
          await prefs.setBool('isCountingUp', homeCubit.state.isCountingUp);
          await prefs.setBool('isWorkSession', homeCubit.state.isWorkSession);
          await _restoreTimerState();
        } catch (e) {
          print('Error starting timer: $e');
          homeCubit.stopTimer();
        }
        break;
      case 'pause':
        try {
          homeCubit.pauseTimer();
          await _channel.invokeMethod('com.example.moji_todo.PAUSE');
          await prefs.setInt('timerSeconds', homeCubit.state.timerSeconds);
          await prefs.setBool('isRunning', false);
          await prefs.setBool('isPaused', true);
          await prefs.setBool('isCountingUp', homeCubit.state.isCountingUp);
          await prefs.setBool('isWorkSession', homeCubit.state.isWorkSession);
          await _restoreTimerState();
        } catch (e) {
          print('Error pausing timer: $e');
        }
        break;
      case 'continue':
        try {
          await checkAndRequestPermissionsForTimer();
          homeCubit.continueTimer();
          await _channel.invokeMethod('startTimerService', {
            'action': 'com.example.moji_todo.RESUME',
            'timerSeconds': homeCubit.state.timerSeconds,
            'isRunning': true,
            'isPaused': false,
            'isCountingUp': homeCubit.state.isCountingUp,
          });
          await prefs.setInt('timerSeconds', homeCubit.state.timerSeconds);
          await prefs.setBool('isRunning', true);
          await prefs.setBool('isPaused', false);
          await prefs.setBool('isCountingUp', homeCubit.state.isCountingUp);
          await prefs.setBool('isWorkSession', homeCubit.state.isWorkSession);
          await _restoreTimerState();
        } catch (e) {
          print('Error resuming timer: $e');
        }
        break;
      case 'stop':
        try {
          homeCubit.stopTimer();
          await _channel.invokeMethod('com.example.moji_todo.STOP');
          await prefs.setInt('timerSeconds', homeCubit.state.isCountingUp ? 0 : homeCubit.state.workDuration * 60);
          await prefs.setBool('isRunning', false);
          await prefs.setBool('isPaused', false);
          await prefs.setBool('isCountingUp', homeCubit.state.isCountingUp);
          await prefs.setBool('isWorkSession', homeCubit.state.isWorkSession);
          await _restoreTimerState();
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          print('Error stopping timer: $e');
        }
        break;
    }

    // Mở khóa hành động sau 1 giây
    await Future.delayed(Duration(milliseconds: 1000));
    _isActionPending = false;
  }

  void dispose() {
    _isActionPending = false;
  }

  void _updatePermissionState({
    bool? hasNotificationPermission,
    bool? hasRequestedBackgroundPermission,
    bool? isIgnoringBatteryOptimizations,
  }) {
    // Update permission state
  }

  bool get hasNotificationPermission => true;
}