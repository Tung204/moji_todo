import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:moji_todo/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'core/services/backup_service.dart';
import 'core/services/notification_service.dart';
import 'core/themes/theme.dart';
import 'core/themes/theme_provider.dart';
import 'features/home/domain/home_cubit.dart';
import 'core/navigation/main_screen.dart';
import 'features/pomodoro/data/pomodoro_repository.dart';
import 'features/pomodoro/domain/pomodoro_cubit.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/tasks/data/models/project_model.dart';
import 'features/tasks/data/models/project_tag_repository.dart';
import 'features/tasks/data/models/tag_model.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/domain/task_cubit.dart';

// InheritedWidget để truyền taskBox, syncInfoBox, projectBox và tagBox
class AppData extends InheritedWidget {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final NotificationService notificationService;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;

  const AppData({
    super.key,
    required this.taskBox,
    required this.syncInfoBox,
    required this.notificationService,
    required this.projectBox,
    required this.tagBox,
    required super.child,
  });

  static AppData of(BuildContext context) {
    final AppData? result = context.dependOnInheritedWidgetOfExactType<AppData>();
    assert(result != null, 'No AppData found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppData oldWidget) {
    return taskBox != oldWidget.taskBox ||
        syncInfoBox != oldWidget.syncInfoBox ||
        projectBox != oldWidget.projectBox ||
        tagBox != oldWidget.tagBox;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel('com.example.moji_todo/notification');

  await Firebase.initializeApp();

  await dotenv.load(fileName: ".env");

  // Khởi tạo Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(TagAdapter());
  final taskBox = await Hive.openBox<Task>('tasks');
  final syncInfoBox = await Hive.openBox<DateTime>('sync_info');
  final projectBox = await Hive.openBox<Project>('projects');
  final tagBox = await Hive.openBox<Tag>('tags');

  if (syncInfoBox == null) {
    throw Exception('Không thể mở syncInfoBox. Kiểm tra quyền lưu trữ hoặc trạng thái Hive.');
  }

  final notificationService = NotificationService();
  await notificationService.init();

  // Kiểm tra và sinh project/tag mặc định nếu Hive trống
  await initializeDefaultData(projectBox, tagBox);

  runApp(MyApp(
    taskBox: taskBox,
    syncInfoBox: syncInfoBox,
    notificationService: notificationService,
    projectBox: projectBox,
    tagBox: tagBox,
  ));
}

// Hàm khởi tạo dữ liệu mặc định
Future<void> initializeDefaultData(Box<Project> projectBox, Box<Tag> tagBox) async {
  final repository = ProjectTagRepository(projectBox: projectBox, tagBox: tagBox);

  // Nếu Hive trống, thêm dữ liệu mặc định
  if (projectBox.isEmpty) {
    final defaultProjects = [
      Project(name: 'General', color: Colors.green, isArchived: false),
      Project(name: 'Pomodoro App', color: Colors.red, isArchived: false),
      Project(name: 'Fashion App', color: Colors.green, isArchived: false),
      Project(name: 'AI Chatbot App', color: Colors.cyan, isArchived: false),
      Project(name: 'Dating App', color: Colors.pink, isArchived: false),
      Project(name: 'Quiz App', color: Colors.blue, isArchived: false),
      Project(name: 'News App', color: Colors.teal, isArchived: false),
    ];

    for (var project in defaultProjects) {
      await repository.addProject(project);
    }
  }

  if (tagBox.isEmpty) {
    final defaultTags = [
      Tag(name: 'Design', backgroundColor: Colors.lightGreen.shade50, textColor: Colors.lightGreen, isArchived: false),
      Tag(name: 'Work', backgroundColor: Colors.blue.shade50, textColor: Colors.blue, isArchived: false),
      Tag(name: 'Productive', backgroundColor: Colors.purple.shade50, textColor: Colors.purple, isArchived: false),
      Tag(name: 'Personal', backgroundColor: Colors.green.shade50, textColor: Colors.green, isArchived: false),
      Tag(name: 'Study', backgroundColor: Colors.purple.shade50, textColor: Colors.purple, isArchived: false),
      Tag(name: 'Urgent', backgroundColor: Colors.red.shade50, textColor: Colors.red, isArchived: false),
      Tag(name: 'Home', backgroundColor: Colors.cyan.shade50, textColor: Colors.cyan, isArchived: false),
      Tag(name: 'Important', backgroundColor: Colors.orange.shade50, textColor: Colors.orange, isArchived: false),
      Tag(name: 'Research', backgroundColor: Colors.brown.shade50, textColor: Colors.brown, isArchived: false),
    ];

    for (var tag in defaultTags) {
      await repository.addTag(tag);
    }
  }
}

class MyApp extends StatefulWidget {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final NotificationService notificationService;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;

  const MyApp({
    required this.taskBox,
    required this.syncInfoBox,
    required this.notificationService,
    required this.projectBox,
    required this.tagBox,
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
    _backupService = BackupService(
      widget.taskBox,
      widget.syncInfoBox,
      widget.projectBox,
      widget.tagBox,
    );
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
      projectBox: widget.projectBox,
      tagBox: widget.tagBox,
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
          BlocProvider(
            create: (context) => HomeCubit(), // Cung cấp HomeCubit ở cấp cao
          ),
        ],
        child: ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Moji ToDo',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.getThemeMode(),
                home: const SplashScreen(),
                onGenerateRoute: AppRoutes.generateRoute,
              );
            },
          ),
        ),
      ),
    );
  }
}
