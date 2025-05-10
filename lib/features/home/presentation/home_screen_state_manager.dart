import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import 'permission_handler.dart';
import 'timer_state_handler.dart';
import '../../../core/services/notification_service.dart';

class HomeScreenStateManager {
  final BuildContext context;
  final Future<SharedPreferences> sharedPreferences;
  final Function(BuildContext) onShowTaskBottomSheet;

  static const MethodChannel _notificationChannel = MethodChannel('com.example.moji_todo/notification');
  final NotificationService _notificationService = NotificationService();
  late PermissionHandler _permissionHandler;
  late TimerStateHandler _timerStateHandler;
  late HomeCubit _homeCubit;
  bool _hasNotificationPermission = false;
  bool _hasRequestedBackgroundPermission = false;
  bool _isIgnoringBatteryOptimizations = false;
  bool _isTimerServiceRunning = false;

  HomeScreenStateManager({
    required this.context,
    required this.sharedPreferences,
    required this.onShowTaskBottomSheet,
  }) {
    _homeCubit = context.read<HomeCubit>();
    _permissionHandler = PermissionHandler(
      context: context,
      notificationChannel: _notificationChannel,
      notificationService: _notificationService,
      onPermissionStateChanged: _updatePermissionState,
    );
    _timerStateHandler = TimerStateHandler(
      homeCubit: _homeCubit,
      notificationChannel: _notificationChannel,
      sharedPreferences: sharedPreferences,
    );
  }

  Future<void> init() async {
    _permissionHandler.checkNotificationPermission();
    _permissionHandler.checkBackgroundPermission();
    _timerStateHandler.restoreTimerState();

    _notificationChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'notificationPermissionResult':
          _updatePermissionState(hasNotificationPermission: call.arguments as bool);
          break;
        case 'ignoreBatteryOptimizationsResult':
          _updatePermissionState(isIgnoringBatteryOptimizations: call.arguments as bool);
          break;
        case 'pauseTimer':
          if (context.mounted) {
            _homeCubit.pauseTimer();
            print('Paused timer from notification');
            // Lưu trạng thái vào SharedPreferences
            final prefs = await sharedPreferences;
            await prefs.setInt('timerSeconds', _homeCubit.state.timerSeconds);
            await prefs.setBool('isRunning', false);
            await prefs.setBool('isPaused', true);
          }
          break;
        case 'resumeTimer':
          if (context.mounted) {
            _homeCubit.continueTimer();
            print('Resumed timer from notification');
          }
          break;
        case 'stopTimer':
          if (context.mounted) {
            _homeCubit.stopTimer();
            _isTimerServiceRunning = false;
            print('Stopped timer from notification or broadcast');
            // Cập nhật SharedPreferences
            final prefs = await sharedPreferences;
            await prefs.setInt('timerSeconds', 0);
            await prefs.setBool('isRunning', false);
            await prefs.setBool('isPaused', false);
          }
          break;
        case 'updateTimer':
          final timerSeconds = call.arguments['timerSeconds'] as int;
          final isRunning = call.arguments['isRunning'] as bool;
          final isPaused = call.arguments['isPaused'] as bool;
          print('Received updateTimer: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
          if (context.mounted) {
            _homeCubit.restoreTimerState(
              timerSeconds: timerSeconds,
              isRunning: isRunning,
              isPaused: isPaused,
            );
            _isTimerServiceRunning = isRunning;
            // Nếu timer dừng, cập nhật SharedPreferences
            if (!isRunning && !isPaused && timerSeconds == 0) {
              final prefs = await sharedPreferences;
              await prefs.setInt('timerSeconds', 0);
              await prefs.setBool('isRunning', false);
              await prefs.setBool('isPaused', false);
            }
          }
          break;
      }
      return null;
    });
  }

  Future<void> startTimer(int initialSeconds) async {
    if (_isTimerServiceRunning || initialSeconds <= 0) return; // Ngăn gọi nếu timer đã chạy hoặc initialSeconds không hợp lệ

    final prefs = await sharedPreferences;
    await prefs.setInt('timerSeconds', initialSeconds);
    await prefs.setBool('isRunning', true);
    await prefs.setBool('isPaused', false);

    final intent = {
      'action': 'START',
      'timerSeconds': initialSeconds,
      'isRunning': true,
      'isPaused': false,
    };
    await _notificationChannel.invokeMethod('startTimerService', intent).catchError((e) {
      print('Error sending START intent: $e');
    });
    _isTimerServiceRunning = true;
    print('Sending START intent: $intent');
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed, restoring timer state');
      _timerStateHandler.restoreTimerState();
      // Đồng bộ trạng thái với TimerService
      if (context.mounted) {
        _notificationChannel.invokeMethod('getTimerState').then((state) {
          if (state != null && context.mounted) {
            final timerSeconds = state['timerSeconds'] as int;
            final isRunning = state['isRunning'] as bool;
            final isPaused = state['isPaused'] as bool;
            print('Restoring timer state from TimerService: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
            // Kiểm tra trạng thái không hợp lệ
            if ((timerSeconds == 0 && isRunning) || (!isRunning && !isPaused && timerSeconds != 0)) {
              sharedPreferences.then((prefs) {
                final correctedTimerSeconds = prefs.getInt('timerSeconds') ?? 25 * 60;
                final correctedIsRunning = prefs.getBool('isRunning') ?? false;
                final correctedIsPaused = prefs.getBool('isPaused') ?? false;
                _homeCubit.restoreTimerState(
                  timerSeconds: correctedTimerSeconds,
                  isRunning: correctedIsRunning,
                  isPaused: correctedIsPaused,
                );
                _isTimerServiceRunning = correctedIsRunning;
                print('Corrected timer state from SharedPreferences: timerSeconds=$correctedTimerSeconds, isRunning=$correctedIsRunning, isPaused=$correctedIsPaused');
              });
            } else {
              _homeCubit.restoreTimerState(
                timerSeconds: timerSeconds,
                isRunning: isRunning,
                isPaused: isPaused,
              );
              _isTimerServiceRunning = isRunning;
              // Nếu timer dừng, đảm bảo trạng thái được reset
              if (!isRunning && !isPaused && timerSeconds == 0) {
                _homeCubit.stopTimer();
                _isTimerServiceRunning = false;
                sharedPreferences.then((prefs) {
                  prefs.setInt('timerSeconds', 0);
                  prefs.setBool('isRunning', false);
                  prefs.setBool('isPaused', false);
                });
              }
            }
          }
        }).catchError((e) {
          print('Error getting timer state: $e');
        });
      }
    }
  }

  void dispose() {}

  void _updatePermissionState({
    bool? hasNotificationPermission,
    bool? hasRequestedBackgroundPermission,
    bool? isIgnoringBatteryOptimizations,
  }) {
    if (hasNotificationPermission != null) {
      _hasNotificationPermission = hasNotificationPermission;
      if (!_hasNotificationPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is required to display timer notifications.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    if (hasRequestedBackgroundPermission != null) {
      _hasRequestedBackgroundPermission = hasRequestedBackgroundPermission;
    }
    if (isIgnoringBatteryOptimizations != null) {
      _isIgnoringBatteryOptimizations = isIgnoringBatteryOptimizations;
      if (!_isIgnoringBatteryOptimizations) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background activity permission is required for the timer to work in the background.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool get hasNotificationPermission => _hasNotificationPermission;
}
