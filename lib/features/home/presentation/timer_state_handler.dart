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
    final prefs = await sharedPreferences;
    try {
      final timerState = await notificationChannel.invokeMethod('getTimerState');
      int timerSeconds = timerState?['timerSeconds'] ?? (prefs.getInt('timerSeconds') ?? 25 * 60);
      bool isRunning = timerState?['isRunning'] ?? (prefs.getBool('isRunning') ?? false);
      bool isPaused = timerState?['isPaused'] ?? (prefs.getBool('isPaused') ?? false);

      // Nếu trạng thái từ getTimerState không hợp lệ (ví dụ: isRunning=true nhưng timerSeconds=0 hoặc sau STOP), ưu tiên SharedPreferences
      if ((timerSeconds == 0 && isRunning) || (!isRunning && !isPaused && timerSeconds != 0)) {
        timerSeconds = prefs.getInt('timerSeconds') ?? 25 * 60;
        isRunning = prefs.getBool('isRunning') ?? false;
        isPaused = prefs.getBool('isPaused') ?? false;
      }

      homeCubit.restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
      );
      print('Restored timer state: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
    } catch (e) {
      print('Error restoring timer state: $e');
      int timerSeconds = prefs.getInt('timerSeconds') ?? 25 * 60;
      bool isRunning = prefs.getBool('isRunning') ?? false;
      bool isPaused = prefs.getBool('isPaused') ?? false;

      homeCubit.restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
      );
      print('Restored timer state from SharedPreferences: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
    }
  }
}