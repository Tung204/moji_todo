import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // THÊM ĐỂ LẤY USER ID CHO DỮ LIỆU MẪU (NẾU THEO CÁCH 2)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:moji_todo/features/auth/data/auth_repository.dart'; // SẼ CẦN CHO AUTHCUBIT
import 'package:moji_todo/features/auth/domain/auth_cubit.dart'; // SẼ CẦN CHO AUTHCUBIT
import 'package:moji_todo/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'core/services/backup_service.dart';
import 'core/services/firebase_service.dart'; // SẼ CẦN CHO AUTHCUBIT (thông qua AuthRepository)
import 'core/services/unified_notification_service.dart';
import 'core/themes/theme.dart';
import 'core/themes/theme_provider.dart';
import 'features/home/domain/home_cubit.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/tasks/data/models/project_model.dart';
import 'features/tasks/data/models/project_tag_repository.dart';
import 'features/tasks/data/models/tag_model.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/domain/task_cubit.dart';

// InheritedWidget để truyền các box
class AppData extends InheritedWidget {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final UnifiedNotificationService notificationService;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final Box<dynamic> appStatusBox; // THÊM app_status box

  const AppData({
    super.key,
    required this.taskBox,
    required this.syncInfoBox,
    required this.notificationService,
    required this.projectBox,
    required this.tagBox,
    required this.appStatusBox, // THÊM
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
        tagBox != oldWidget.tagBox ||
        appStatusBox != oldWidget.appStatusBox; // THÊM
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bỏ MethodChannel nếu không còn dùng
  // const MethodChannel('com.example.moji_todo/notification');

  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  // Khởi tạo Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(TagAdapter()); // TagModel đã được sửa để không có backgroundColorValue

  final taskBox = await Hive.openBox<Task>('tasks');
  final syncInfoBox = await Hive.openBox<DateTime>('sync_info');
  final projectBox = await Hive.openBox<Project>('projects');
  final tagBox = await Hive.openBox<Tag>('tags');
  final appStatusBox = await Hive.openBox<dynamic>('app_status'); // THÊM: Mở app_status box

  // Dòng kiểm tra syncInfoBox đã có trong file bạn gửi
  // if (syncInfoBox == null) { // syncInfoBox sẽ không bao giờ là null sau khi await Hive.openBox
  //   throw Exception('Không thể mở syncInfoBox. Kiểm tra quyền lưu trữ hoặc trạng thái Hive.');
  // }

  final notificationService = UnifiedNotificationService();
  await notificationService.init();

  // BỎ HOẶC VÔ HIỆU HÓA initializeDefaultData Ở ĐÂY
  // Logic này sẽ được chuyển vào AuthCubit để tạo dữ liệu mẫu gắn với userId
  // await initializeDefaultData(projectBox, tagBox);

  // Khởi tạo các service và repository cần cho AuthCubit
  // (AuthCubit sẽ được cung cấp trong MyApp để có thể truy cập context)
  final firebaseService = FirebaseService(); // Giả sử FirebaseService không cần tham số
  final authRepository = AuthRepository(firebaseService); // Truyền firebaseService nếu cần

  runApp(MyApp(
    taskBox: taskBox,
    syncInfoBox: syncInfoBox,
    notificationService: notificationService,
    projectBox: projectBox,
    tagBox: tagBox,
    appStatusBox: appStatusBox, // TRUYỀN appStatusBox
    authRepository: authRepository, // TRUYỀN authRepository để cung cấp cho AuthCubit
    backupService: BackupService(taskBox, syncInfoBox, projectBox, tagBox), // TRUYỀN backupService
  ));
}

// HÀM NÀY SẼ ĐƯỢC DI CHUYỂN HOẶC THAY THẾ BẰNG LOGIC TRONG AUTHCUBIT
/*
Future<void> initializeDefaultData(Box<Project> projectBox, Box<Tag> tagBox) async {
  // Lấy userId hiện tại (NẾU có, nhưng ở main() thì thường là chưa có user)
  // final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // if (currentUserId == null) {
  //   print('Không có người dùng đăng nhập, không thể tạo dữ liệu mẫu có userId.');
  //   // return; // Hoặc tạo dữ liệu mẫu không có userId và xử lý sau
  // }

  final repository = ProjectTagRepository(projectBox: projectBox, tagBox: tagBox);

  // Chỉ thêm nếu box trống VÀ có userId (nếu bạn muốn dữ liệu mẫu phải có userId ngay)
  // Hoặc, bỏ qua userId ở đây và AuthCubit sẽ xử lý việc gán userId cho dữ liệu mẫu sau này.
  if (projectBox.isEmpty) {
    final defaultProjects = [
      Project(name: 'General', color: Colors.green, userId: null /* currentUserId */), // Cần userId
      Project(name: 'Pomodoro App', color: Colors.red, userId: null /* currentUserId */, iconCodePoint: Icons.timer_outlined.codePoint, iconFontFamily: Icons.timer_outlined.fontFamily),
      // ... các project khác
    ];
    for (var project in defaultProjects) {
      // addProject trong repository đã được sửa để xử lý userId
      await repository.addProject(project);
    }
    print('Default projects (potentially without userId) initialized from main.');
  }

  if (tagBox.isEmpty) {
    final defaultTags = [
      Tag(name: 'Design', textColor: Colors.lightGreen, userId: null /* currentUserId */), // Cần userId, không có backgroundColor
      Tag(name: 'Work', textColor: Colors.blue, userId: null /* currentUserId */),
      // ... các tag khác
    ];
    for (var tag in defaultTags) {
      await repository.addTag(tag);
    }
    print('Default tags (potentially without userId) initialized from main.');
  }
}
*/

class MyApp extends StatefulWidget {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final UnifiedNotificationService notificationService;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final Box<dynamic> appStatusBox; // THÊM
  final AuthRepository authRepository; // THÊM
  final BackupService backupService;   // THÊM

  const MyApp({
    required this.taskBox,
    required this.syncInfoBox,
    required this.notificationService,
    required this.projectBox,
    required this.tagBox,
    required this.appStatusBox, // THÊM
    required this.authRepository, // THÊM
    required this.backupService,  // THÊM
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _syncTimer;
  // Bỏ _backupService ở đây vì đã được truyền vào từ main
  // late BackupService _backupService;

  @override
  void initState() {
    super.initState();
    // _backupService đã được khởi tạo ở main và truyền vào widget
    // _backupService = BackupService(
    //   widget.taskBox,
    //   widget.syncInfoBox,
    //   widget.projectBox,
    //   widget.tagBox,
    // );
    _startSyncTimer();
  }

  void _startSyncTimer() {
    const syncInterval = Duration(minutes: 15);
    _syncTimer = Timer.periodic(syncInterval, (timer) async {
      try {
        // Sử dụng widget.backupService đã được truyền vào
        final lastSync = await widget.backupService.getLastBackupTime();
        final now = DateTime.now();
        // Kiểm tra xem người dùng có đang đăng nhập không trước khi đồng bộ
        if (FirebaseAuth.instance.currentUser != null) {
          if (lastSync == null || now.difference(lastSync).inMinutes >= 15) {
            print('Attempting periodic backup...');
            await widget.backupService.backupToFirestore();
            print('Đã đồng bộ dữ liệu lên Firestore lúc: $now');
          }
        } else {
          print('User not logged in, skipping periodic backup.');
        }
      } catch (e) {
        print('Lỗi khi đồng bộ dữ liệu tự động: $e');
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    // Đóng các box Hive khi ứng dụng thoát (quan trọng)
    widget.taskBox.close();
    widget.syncInfoBox.close();
    widget.projectBox.close();
    widget.tagBox.close();
    widget.appStatusBox.close();
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
      appStatusBox: widget.appStatusBox, // TRUYỀN appStatusBox
      child: MultiProvider( // ĐỔI MultiBlocProvider thành MultiProvider để chứa cả Provider thường
        providers: [
          // CUNG CẤP CÁC REPOSITORY VÀ SERVICE CẦN THIẾT
          Provider<AuthRepository>.value(value: widget.authRepository),
          Provider<BackupService>.value(value: widget.backupService),
          Provider<ProjectTagRepository>(
            create: (_) => ProjectTagRepository(
              projectBox: widget.projectBox,
              tagBox: widget.tagBox,
            ),
          ),
          Provider<TaskRepository>(
            create: (_) => TaskRepository(
              taskBox: widget.taskBox,
              projectBox: widget.projectBox,
              tagBox: widget.tagBox,
            ),
          ),

          // BLOC PROVIDERS
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              context.read<AuthRepository>(), // Lấy từ Provider
              context.read<BackupService>(),  // Lấy từ Provider
              context.read<ProjectTagRepository>(), // Lấy từ Provider
              context.read<TaskRepository>(),       // Lấy từ Provider
              widget.projectBox, // Truyền trực tiếp các box nếu AuthCubit cần clear
              widget.tagBox,
              widget.taskBox,
              widget.syncInfoBox, // Cho việc xóa lastSync khi logout
              widget.appStatusBox,  // Cho việc xóa lastModified khi logout
            ),
          ),
          BlocProvider<TaskCubit>(
            create: (context) => TaskCubit(
              taskRepository: context.read<TaskRepository>(), // Lấy từ Provider
              projectTagRepository: context.read<ProjectTagRepository>(), // Lấy từ Provider
            )..loadInitialData(), // Gọi loadInitialData ở đây hoặc từ SplashScreen sau khi xác thực
          ),
          BlocProvider<HomeCubit>(
            create: (context) => HomeCubit(),
          ),
          ChangeNotifierProvider<ThemeProvider>( // ThemeProvider vẫn dùng ChangeNotifierProvider
            create: (context) => ThemeProvider(),
          ),
        ],
        child: Consumer<ThemeProvider>( // Consumer cho ThemeProvider
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Moji ToDo',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.getThemeMode(),
              home: const SplashScreen(), // SplashScreen sẽ xử lý việc điều hướng dựa trên trạng thái Auth
              onGenerateRoute: AppRoutes.generateRoute,
            );
          },
        ),
      ),
    );
  }
}