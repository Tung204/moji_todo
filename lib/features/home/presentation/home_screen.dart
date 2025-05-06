import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import 'widgets/pomodoro_timer.dart';
import 'widgets/task_card.dart';
import 'strict_mode_menu.dart';
import 'timer_mode_menu.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/navigation/navigation_manager.dart';
import '../../../routes/app_routes.dart';
import '../../tasks/domain/task_cubit.dart';
import '../../../core/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const MethodChannel _permissionChannel = MethodChannel('com.example.moji_todo/permissions');
  static const MethodChannel _notificationChannel = MethodChannel('com.example.moji_todo/notification');
  final NotificationService _notificationService = NotificationService();
  bool _hasNotificationPermission = false;
  bool _hasRequestedBackgroundPermission = false;
  bool _isIgnoringBatteryOptimizations = false;
  late HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = context.read<HomeCubit>();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermission();
    _checkBackgroundPermission();
    _restoreTimerState();

    _notificationChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'notificationPermissionResult':
          if (mounted) {
            setState(() {
              _hasNotificationPermission = call.arguments as bool;
            });
            if (!_hasNotificationPermission) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification permission is required to display timer notifications.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
          break;
        case 'ignoreBatteryOptimizationsResult':
          if (mounted) {
            setState(() {
              _isIgnoringBatteryOptimizations = call.arguments as bool;
            });
            if (!_isIgnoringBatteryOptimizations) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Background activity permission is required for the timer to work in the background.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
          break;
        case 'pauseTimer':
          _homeCubit.pauseTimer();
          break;
        case 'resumeTimer':
          _homeCubit.continueTimer();
          break;
        case 'stopTimer':
          _homeCubit.stopTimer();
          break;
        case 'updateTimer':
          final timerSeconds = call.arguments['timerSeconds'] as int;
          final isRunning = call.arguments['isRunning'] as bool;
          final isPaused = call.arguments['isPaused'] as bool;
          print('Received updateTimer: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
          if (mounted) {
            _homeCubit.restoreTimerState(
              timerSeconds: timerSeconds,
              isRunning: isRunning,
              isPaused: isPaused,
            );
          }
          break;
      }
      return null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('App resumed, restoring timer state');
      _restoreTimerState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkNotificationPermission() async {
    await _notificationService.init();
    final hasPermission = await _notificationChannel.invokeMethod('checkNotificationPermission');
    print('Notification Permission: $hasPermission');
    if (mounted) {
      setState(() {
        _hasNotificationPermission = hasPermission;
      });
    }
    if (!_hasNotificationPermission) {
      bool? granted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Yêu cầu quyền thông báo'),
          content: const Text('Ứng dụng cần quyền thông báo để hiển thị trạng thái timer. Vui lòng cấp quyền trong cài đặt.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Từ chối'),
            ),
            TextButton(
              onPressed: () async {
                await _notificationChannel.invokeMethod('requestNotificationPermission');
                Navigator.pop(context, true);
              },
              child: const Text('Cấp quyền'),
            ),
          ],
        ),
      );

      if (granted != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is required to display timer notifications.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _checkBackgroundPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool('hasRequestedBackgroundPermission') ?? false;
    if (!hasRequested) {
      final isIgnoringBatteryOptimizations = await _permissionChannel.invokeMethod('checkIgnoreBatteryOptimizations');
      print('Battery Optimization Ignored: $isIgnoringBatteryOptimizations');
      if (mounted) {
        setState(() {
          _isIgnoringBatteryOptimizations = isIgnoringBatteryOptimizations;
        });
      }

      if (!_isIgnoringBatteryOptimizations) {
        bool? confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Yêu cầu quyền chạy nền'),
            content: const Text(
              'Để timer hoạt động chính xác khi ứng dụng ở background, vui lòng cho phép ứng dụng chạy nền:\n'
                  '1. Bỏ qua tối ưu pin (sẽ mở cài đặt ngay).\n'
                  '2. Nếu thiết bị yêu cầu thêm, vào Settings > Apps > Moji Todo > Allow background activity.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Bỏ qua'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Mở cài đặt'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _permissionChannel.invokeMethod('requestIgnoreBatteryOptimizations');
        }
      }

      await prefs.setBool('hasRequestedBackgroundPermission', true);
      if (mounted) {
        setState(() {
          _hasRequestedBackgroundPermission = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasRequestedBackgroundPermission = true;
          _isIgnoringBatteryOptimizations = prefs.getBool('isIgnoringBatteryOptimizations') ?? false;
        });
      }
    }
  }

  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final timerState = await _notificationChannel.invokeMethod('getTimerState');
      int timerSeconds = timerState?['timerSeconds'] ?? (prefs.getInt('timerSeconds') ?? 25 * 60); // Mặc định 25 phút
      bool isRunning = timerState?['isRunning'] ?? (prefs.getBool('isRunning') ?? false);
      bool isPaused = timerState?['isPaused'] ?? (prefs.getBool('isPaused') ?? false);

      _homeCubit.restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
      );
      print('Restored timer state: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
    } catch (e) {
      print('Error restoring timer state: $e');
      int timerSeconds = prefs.getInt('timerSeconds') ?? 25 * 60; // Mặc định 25 phút
      bool isRunning = prefs.getBool('isRunning') ?? false;
      bool isPaused = prefs.getBool('isPaused') ?? false;

      _homeCubit.restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
      );
    }
  }

  void _showTaskBottomSheet(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Task',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Color(0xFFFF5733)),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.tasks);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search task...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        autofocus: true,
                        onChanged: (value) {
                          setBottomSheetState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<TaskCubit, TaskState>(
                        builder: (context, state) {
                          final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
                          final todayTasks = categorizedTasks['Today'] ?? [];
                          final filteredTasks = searchQuery.isEmpty
                              ? todayTasks
                              : todayTasks
                              .where((task) => task.title?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Today Tasks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (filteredTasks.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(child: Text('No tasks found.')),
                                )
                              else
                                SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: filteredTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = filteredTasks[index];
                                      return TaskCard(
                                        task: task,
                                        onPlay: () {
                                          _homeCubit.selectTask(
                                            task.title ?? 'Untitled Task',
                                            task.estimatedPomodoros ?? 4,
                                          );
                                          _homeCubit.startTimer();
                                          Navigator.pop(context);
                                        },
                                        onComplete: () {
                                          context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: true));
                                          if (_homeCubit.state.selectedTask == task.title) {
                                            _homeCubit.stopTimer();
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    NavigationManager.currentIndex = 0;

    return MultiBlocListener(
      listeners: [
        BlocListener<TaskCubit, TaskState>(
          listener: (context, taskState) {
            final selectedTaskTitle = _homeCubit.state.selectedTask;
            if (selectedTaskTitle != null) {
              final todayTasks = context.read<TaskCubit>().getCategorizedTasks()['Today'] ?? [];
              final isTaskStillInToday = todayTasks.any((task) => task.title == selectedTaskTitle);
              if (!isTaskStillInToday) {
                _homeCubit.resetTask();
              }
            }
          },
        ),
      ],
      child: BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (previous, current) =>
        previous.timerSeconds != current.timerSeconds ||
            previous.isTimerRunning != current.isTimerRunning ||
            previous.isPaused != current.isPaused ||
            previous.selectedTask != current.selectedTask ||
            previous.isStrictModeEnabled != current.isStrictModeEnabled ||
            previous.workDuration != current.workDuration ||
            previous.breakDuration != current.breakDuration ||
            previous.isWorkSession != current.isWorkSession,
        builder: (context, state) {
          return WillPopScope(
            onWillPop: () async {
              if (state.isStrictModeEnabled && state.isTimerRunning && state.isExitBlockingEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Strict Mode (Cấm thoát) đang bật! Bạn không thể thoát ứng dụng.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
                return false;
              }
              return true;
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFE6F7FA),
              appBar: const CustomAppBar(),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _showTaskBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.selectedTask ?? 'Select Task',
                              style: TextStyle(
                                color: state.selectedTask != null ? Colors.black : Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const PomodoroTimer(),
                    const SizedBox(height: 16),
                    Text(
                      'Selected Task: ${state.selectedTask ?? 'None'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const StrictModeMenu(),
                        const TimerModeMenu(),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.music_note, color: Colors.grey),
                              onPressed: () {},
                            ),
                            const Text(
                              'White Noise',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}