import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/home_cubit.dart';

class TimerStateHandler {
  final HomeCubit homeCubit;
  final MethodChannel notificationChannel;
  final Future<SharedPreferences> sharedPreferences;

  TimerStateHandler({
    required this.homeCubit,
    required this.notificationChannel,
    required this.sharedPreferences,
  });

  Future<void> restoreTimerState() async {
    try {
      final timerState = await notificationChannel.invokeMethod('getTimerState');
      int timerSeconds = timerState?['timerSeconds'] ?? 25 * 60;
      bool isRunning = timerState?['isRunning'] ?? false;
      bool isPaused = timerState?['isPaused'] ?? false;

      homeCubit.restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
      );
      print('Restored timer state from service: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
    } catch (e) {
      print('Error restoring timer state: $e');
      final prefs = await sharedPreferences;
      int timerSeconds = prefs.getInt('timerSeconds') ?? 25 * 60;
      bool isRunning = prefs.getBool('isRunning') ?? false;
      bool isPaused = prefs.getBool('isPaused') ?? false;

      homeCubit.restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
      );
      print('Restored from SharedPreferences: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
    }
  }
}