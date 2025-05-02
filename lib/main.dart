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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Khởi tạo Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  final taskBox = await Hive.openBox<Task>('tasks');

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(MyApp(
    taskBox: taskBox,
    notificationService: notificationService,
  ));
}

class MyApp extends StatelessWidget {
  final Box<Task> taskBox;
  final NotificationService notificationService;

  const MyApp({required this.taskBox, required this.notificationService, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PomodoroCubit(
            PomodoroRepository(notificationService: notificationService),
          ),
        ),
        BlocProvider(
          create: (context) => TaskCubit(TaskRepository(taskBox: taskBox)),
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
    );
  }
}