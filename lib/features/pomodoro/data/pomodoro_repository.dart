import 'dart:async';
import 'dart:ui';
import 'package:moji_todo/core/services/notification_service.dart';

class PomodoroRepository {
  final NotificationService notificationService;
  Timer? _timer;

  PomodoroRepository({required this.notificationService});

  void startTimer({
    required int duration,
    required Function(int) onTick,
    required VoidCallback onComplete,
  }) {
    _timer?.cancel();
    int secondsLeft = duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft > 0) {
        secondsLeft--;
        onTick(secondsLeft);
      } else {
        timer.cancel();
        onComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
  }

  void resetTimer() {
    _timer?.cancel();
  }

  void showNotification({required String title, required String body}) {
    notificationService.showNotification(title: title, body: body);
  }
}