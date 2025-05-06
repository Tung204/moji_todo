import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi nhấn vào thông báo
        if (response.actionId == null) {
          print('Notification tapped, opening app');
        } else {
          print('Notification action: ${response.actionId}');
        }
      },
    );

    // Yêu cầu quyền thông báo trên Android 13+
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    // Khởi tạo timezone
    tz.initializeTimeZones();
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0,
      title,
      body,
      details,
    );
  }

  // Hiển thị thông báo timer với các nút hành động
  Future<void> showTimerNotification({
    required int timerSeconds,
    required bool isRunning,
    required bool isPaused,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'timer_channel_id',
      'Timer Notifications',
      channelDescription: 'Notifications for Pomodoro timer',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // Thông báo không thể bị xóa khi timer đang chạy
      showWhen: false,
      actions: [
        AndroidNotificationAction('pause', 'Pause'),
        AndroidNotificationAction('resume', 'Resume'),
        AndroidNotificationAction('stop', 'Stop'),
      ],
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Chuyển đổi thời gian từ giây sang định dạng mm:ss
    final minutes = (timerSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timerSeconds % 60).toString().padLeft(2, '0');
    final timeDisplay = '$minutes:$seconds';

    await _notificationsPlugin.show(
      0, // ID cố định để cập nhật thông báo
      'Pomodoro Timer',
      'Time remaining: $timeDisplay (${isRunning ? isPaused ? "Paused" : "Running" : "Stopped"})',
      notificationDetails,
      payload: 'open_app',
    );
  }

  // Hủy thông báo timer
  Future<void> cancelTimerNotification() async {
    await _notificationsPlugin.cancel(0);
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('Thời gian lập lịch đã qua, không thể tạo thông báo.');
      return;
    }
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
    );
  }

  Future<void> cancelNotification(String title) async {
    await _notificationsPlugin.cancel(title.hashCode);
  }
}