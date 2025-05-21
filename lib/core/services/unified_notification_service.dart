import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class UnifiedNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const int TIMER_NOTIFICATION_ID = 100;
  static const int SESSION_END_NOTIFICATION_ID = 101; // ID mới cho thông báo kết thúc phiên
  static const MethodChannel _channel = MethodChannel('com.example.moji_todo/notification');

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    try {
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          print('Notification tapped: type=${response.notificationResponseType}, payload=${response.payload}, actionId=${response.actionId}');
          if (response.actionId != null) {
            print('Processing notification action: actionId=${response.actionId}, payload=${response.payload}');
            try {
              int defaultBreakDuration = 5 * 60;
              int defaultWorkDuration = 25 * 60;

              int? timerSecondsFromPayload;
              if (response.payload != null && response.payload!.contains(':')) {
                final parts = response.payload!.split(':');
                if (parts.length > 1) {
                  timerSecondsFromPayload = int.tryParse(parts[1]);
                }
              }

              await _channel.invokeMethod('handleNotificationAction', {
                'action': response.actionId,
                'timerSeconds': timerSecondsFromPayload ?? (response.actionId == 'START_BREAK' ? defaultBreakDuration : defaultWorkDuration),
              });
              print('Sent action ${response.actionId} to MainActivity successfully');
            } catch (e) {
              print('Error sending action to MainActivity: $e');
            }
          } else {
            print('Notification payload tapped: ${response.payload}');
            await _channel.invokeMethod('handleNotificationIntent', {
              'action': 'com.example.moji_todo.OPEN_APP',
              'fromNotification': true,
              'Flutter_notification_payload': response.payload,
            });
            print('Sent OPEN_APP intent to MainActivity from Notification tapped.');
          }
        },
      );
      print('Notification plugin initialized');
    } catch (e) {
      print('Error initializing notification plugin: $e');
    }

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    print('Notification permission granted: $granted');
    if (granted != true) {
      print('Warning: Notification permission not granted');
    }

    tz.initializeTimeZones();
  }

  Future<void> showTimerNotification({
    required int timerSeconds,
    required bool isRunning,
    required bool isPaused,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'timer_channel_id', // Sử dụng kênh cho timer
      'Timer Notifications',
      channelDescription: 'Notifications for Pomodoro timer running in background',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: isRunning && !isPaused,
      showWhen: false,
      sound: null,
      playSound: false,
      onlyAlertOnce: true,
      enableVibration: false,
      actions: [
        if (isRunning && !isPaused)
          AndroidNotificationAction('pause_action', 'Pause', showsUserInterface: false),
        if (isPaused)
          AndroidNotificationAction('resume_action', 'Resume', showsUserInterface: false),
        AndroidNotificationAction('stop_action', 'Stop', showsUserInterface: false),
      ],
    );
    final NotificationDetails details = NotificationDetails(android: androidDetails);
    final minutes = (timerSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timerSeconds % 60).toString().padLeft(2, '0');
    final status = isRunning ? (isPaused ? "Paused" : "Running") : "Stopped";
    try {
      await _notificationsPlugin.show(
        TIMER_NOTIFICATION_ID,
        'Pomodoro Timer',
        'Time: $minutes:$seconds ($status)',
        details,
        payload: 'timer:$timerSeconds',
      );
      print('Timer notification shown: time=$minutes:$seconds, isRunning=$isRunning, isPaused=$isPaused, status=$status');
    } catch (e) {
      print('Error showing timer notification: $e');
    }
  }

  Future<void> showEndSessionNotification({
    required String title,
    required String body,
    required String payload,
    bool? isWorkSession,
    String? notificationSound,
    bool? soundEnabled,
  }) async {
    // NEW LOG: Log received parameters
    print('[UnifiedNotificationService] showEndSessionNotification called with:');
    print('[UnifiedNotificationService]   notificationSound: $notificationSound');
    print('[UnifiedNotificationService]   soundEnabled: $soundEnabled');

    final RawResourceAndroidNotificationSound? customSound = (soundEnabled ?? false) && (notificationSound != null && notificationSound != 'none')
        ? RawResourceAndroidNotificationSound(notificationSound)
        : null;

    // NEW LOG: Log customSound object
    if (customSound != null) {
      print('[UnifiedNotificationService]   customSound object created for: ${customSound.sound}');
    } else {
      print('[UnifiedNotificationService]   customSound object is null.');
    }

    final List<AndroidNotificationAction> actions = [];

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Session End Notifications',
      channelDescription: 'Notifications for when a Pomodoro session ends',
      importance: Importance.max, // MODIFIED: Ensure max importance
      priority: Priority.high, // MODIFIED: Ensure high priority
      autoCancel: true,
      sound: customSound,
      playSound: (soundEnabled ?? false),
      enableVibration: (soundEnabled ?? false), // Rung cũng dựa vào soundEnabled
      actions: actions,
    );

    // NEW LOG: Log AndroidNotificationDetails properties
    print('[UnifiedNotificationService]   AndroidNotificationDetails created with:');
    print('[UnifiedNotificationService]     channelId: ${androidDetails.channelId}');
    print('[UnifiedNotificationService]     importance: ${androidDetails.importance.name}');
    print('[UnifiedNotificationService]     priority: ${androidDetails.priority.name}');
    print('[UnifiedNotificationService]     sound: ${androidDetails.sound?.sound}');
    print('[UnifiedNotificationService]     playSound: ${androidDetails.playSound}');
    print('[UnifiedNotificationService]     enableVibration: ${androidDetails.enableVibration}');


    final NotificationDetails details = NotificationDetails(android: androidDetails);
    try {
      await _notificationsPlugin.show(
        SESSION_END_NOTIFICATION_ID,
        title,
        body,
        details,
        payload: payload,
      );
      // MODIFIED: Existing log - this will now appear after all new detailed logs
      print('End session notification shown (via plugin): title=$title, body=$body, payload=$payload, actions=${actions.map((a) => a.id).join(', ')}');
    } catch (e) {
      print('Error showing end session notification: $e');
      if (kDebugMode) {
        print('Error details: $e');
      }
    }
  }

  Future<void> cancelNotification({int? id}) async {
    try {
      if (id != null) {
        await _notificationsPlugin.cancel(id);
        print('Notification with ID $id cancelled');
      } else {
        await _notificationsPlugin.cancel(TIMER_NOTIFICATION_ID);
        await _notificationsPlugin.cancel(SESSION_END_NOTIFICATION_ID);
        print('All timer/session end notifications cancelled');
      }
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('Scheduled time is in the past, cannot schedule notification');
      return;
    }
    await cancelNotification();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('bell'), // Example, ensure 'bell' is valid
      playSound: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    try {
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
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }
}