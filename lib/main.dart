import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moji_todo/core/services/notification_service.dart';
import 'package:moji_todo/features/pomodoro/data/pomodoro_repository.dart';
import 'package:moji_todo/features/pomodoro/domain/pomodoro_cubit.dart';
import 'package:moji_todo/features/tasks/data/task_repository.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';
import 'package:moji_todo/features/tasks/domain/task_cubit.dart';
import 'package:moji_todo/routes/app_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/backup_service.dart';

// InheritedWidget để truyền taskBox và syncInfoBox
class AppData extends InheritedWidget {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final NotificationService notificationService;

  const AppData({
    super.key,
    required this.taskBox,
    required this.syncInfoBox,
    required this.notificationService,
    required super.child,
  });

  static AppData of(BuildContext context) {
    final AppData? result = context.dependOnInheritedWidgetOfExactType<AppData>();
    assert(result != null, 'No AppData found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppData oldWidget) {
    return taskBox != oldWidget.taskBox || syncInfoBox != oldWidget.syncInfoBox;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await dotenv.load(fileName: ".env");

  // Khởi tạo Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  final taskBox = await Hive.openBox<Task>('tasks');
  final syncInfoBox = await Hive.openBox<DateTime>('sync_info');

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(MyApp(
    taskBox: taskBox,
    syncInfoBox: syncInfoBox,
    notificationService: notificationService,
  ));
}

class MyApp extends StatefulWidget {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final NotificationService notificationService;

  const MyApp({
    required this.taskBox,
    required this.syncInfoBox,
    required this.notificationService,
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _syncTimer;
  late BackupService _backupService;

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(widget.taskBox, widget.syncInfoBox);
    _startSyncTimer();
  }

  void _startSyncTimer() {
    const syncInterval = Duration(minutes: 15);
    _syncTimer = Timer.periodic(syncInterval, (timer) async {
      try {
        final lastSync = await _backupService.getLastBackupTime();
        final now = DateTime.now();
        if (lastSync == null || now.difference(lastSync).inMinutes >= 15) {
          await _backupService.backupToFirestore();
          print('Đã đồng bộ dữ liệu lên Firestore lúc: $now');
        }
      } catch (e) {
        print('Lỗi khi đồng bộ dữ liệu: $e');
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppData(
      taskBox: widget.taskBox,
      syncInfoBox: widget.syncInfoBox,
      notificationService: widget.notificationService,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => PomodoroCubit(
              PomodoroRepository(notificationService: widget.notificationService),
            ),
          ),
          BlocProvider(
            create: (context) => TaskCubit(TaskRepository(taskBox: widget.taskBox)),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Moji ToDo',
          theme: ThemeData(
            primaryColor: const Color(0xFF00C4FF),
            scaffoldBackgroundColor: const Color(0xFFE6F7FA),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFFFF69B4)),
            ),
          ),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      ),
    );
  }
}