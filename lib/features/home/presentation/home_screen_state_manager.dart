import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/home/domain/home_cubit.dart';
import 'package:moji_todo/features/home/domain/home_state.dart';
import 'package:moji_todo/features/home/presentation/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
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
      notificationService: NotificationService(),
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
      }
    } else if (state == AppLifecycleState.resumed) {
      await _restoreTimerState();
      if (homeCubit.state.isStrictModeEnabled && homeCubit.state.isTimerRunning && homeCubit.state.isFlipPhoneEnabled) {
        await _channel.invokeMethod('startTimerService', {
          'action': 'UPDATE',
          'timerSeconds': homeCubit.state.timerSeconds,
          'isRunning': homeCubit.state.isTimerRunning,
          'isPaused': homeCubit.state.isPaused,
          'isCountingUp': homeCubit.state.isCountingUp,
        });
      }
    }
  }

  Future<void> handleTimerAction(String action, {Task? task, int? estimatedPomodoros}) async {
    final homeCubit = context.read<HomeCubit>();
    final prefs = await sharedPreferences;
    switch (action) {
      case 'start':
        if (!homeCubit.state.isTimerRunning) {
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
          await _restoreTimerState();
        }
        break;
      case 'pause':
        if (homeCubit.state.isTimerRunning && !homeCubit.state.isPaused) {
          homeCubit.pauseTimer();
          await _channel.invokeMethod('com.example.moji_todo.PAUSE');
          await prefs.setInt('timerSeconds', homeCubit.state.timerSeconds);
          await prefs.setBool('isRunning', false);
          await prefs.setBool('isPaused', true);
          await prefs.setBool('isCountingUp', homeCubit.state.isCountingUp);
          await _restoreTimerState();
        }
        break;
      case 'continue':
        if (!homeCubit.state.isTimerRunning && homeCubit.state.isPaused) {
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
          await _restoreTimerState();
        }
        break;
      case 'stop':
        if (homeCubit.state.isTimerRunning || homeCubit.state.isPaused) {
          homeCubit.stopTimer();
          await _channel.invokeMethod('com.example.moji_todo.STOP');
          await prefs.setInt('timerSeconds', homeCubit.state.isCountingUp ? 0 : homeCubit.state.workDuration * 60);
          await prefs.setBool('isRunning', false);
          await prefs.setBool('isPaused', false);
          await prefs.setBool('isCountingUp', homeCubit.state.isCountingUp);
          await _restoreTimerState();
        }
        break;
    }
  }

  void dispose() {}

  void _updatePermissionState({
    bool? hasNotificationPermission,
    bool? hasRequestedBackgroundPermission,
    bool? isIgnoringBatteryOptimizations,
  }) {
    // Update permission state
  }

  bool get hasNotificationPermission => true;
}