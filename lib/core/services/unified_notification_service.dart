import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class UnifiedNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const int TIMER_NOTIFICATION_ID = 100;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped, payload: ${response.payload}');
      },
    );

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    print('Notification permission granted: $granted');
    if (granted != true) {
      print('Warning: Notification permission not granted.');
    }

    tz.initializeTimeZones();
  }

  Future<void> showTimerNotification({
    required int timerSeconds,
    required bool isRunning,
    required bool isPaused,
  }) async {
    // Hủy thông báo cũ trước khi hiển thị mới
    await cancelNotification();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'timer_channel_id',
      'Timer Notifications',
      channelDescription: 'Notifications for Pomodoro timer',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: isRunning && !isPaused,
      showWhen: false,
      actions: [
        if (isRunning && !isPaused)
          AndroidNotificationAction('pause', 'Pause'),
        AndroidNotificationAction('stop', 'Stop'),
      ],
    );
    final NotificationDetails details = NotificationDetails(android: androidDetails);
    final minutes = (timerSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timerSeconds % 60).toString().padLeft(2, '0');
    await _notificationsPlugin.show(
      TIMER_NOTIFICATION_ID,
      'Pomodoro Timer',
      'Time: $minutes:$seconds (${isRunning ? isPaused ? "Paused" : "Running" : "Stopped"})',
      details,
      payload: 'open_app',
    );
    print('Timer notification shown: time=$minutes:$seconds, isRunning=$isRunning, isPaused=$isPaused');
  }

  Future<void> showEndSessionNotification({required bool isWorkSession}) async {
    await cancelNotification();
    final title = isWorkSession ? "Đã hoàn thành phiên làm việc" : "Đã hoàn thành phiên nghỉ";
    const body = "Nhấn để mở ứng dụng và tiếp tục!";
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      TIMER_NOTIFICATION_ID,
      title,
      body,
      details,
      payload: 'open_app',
    );
    print('End session notification shown: title=$title, body=$body');
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await cancelNotification();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      TIMER_NOTIFICATION_ID,
      title,
      body,
      details,
      payload: 'open_app',
    );
    print('Notification shown: title=$title, body=$body');
  }

  Future<void> cancelNotification() async {
    await _notificationsPlugin.cancel(TIMER_NOTIFICATION_ID);
    print('Notification cancelled');
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('Scheduled time is in the past, cannot schedule notification.');
      return;
    }
    await cancelNotification();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.zonedSchedule(
      title.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    print('Scheduled notification: title=$title, scheduledTime=$scheduledTime');
  }
}