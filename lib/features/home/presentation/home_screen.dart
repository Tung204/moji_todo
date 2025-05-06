import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import 'widgets/pomodoro_timer.dart';
import 'widgets/task_card.dart';
import 'strict_mode_menu.dart'; // Giữ import từ tinvo
import 'timer_mode_menu.dart'; // Giữ import từ tinvo
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/navigation/navigation_manager.dart';
import '../../../routes/app_routes.dart';
import '../../tasks/domain/task_cubit.dart';
import '../../../core/services/notification_service.dart';

const String prefTimerSeconds = "timerSeconds";
const String prefIsRunning = "isRunning";
const String prefIsPaused = "isPaused";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const MethodChannel _permissionChannel = MethodChannel('com.example.moji_todo/permissions');
  static const MethodChannel _serviceChannel = MethodChannel('com.example.moji_todo/app_block_service');
  static const MethodChannel _notificationChannel = MethodChannel('com.example.moji_todo/notification');
  final NotificationService _notificationService = NotificationService();
  bool _lastAppBlockingState = false;
  bool _isTimerServiceRunning = false;
  bool _hasNotificationPermission = false;
  bool _hasRequestedBackgroundPermission = false;
  bool _isIgnoringBatteryOptimizations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermission();
    _checkBackgroundPermission();
    _restoreTimerState();

    _notificationChannel.setMethodCallHandler((call) async {
      final prefs = await SharedPreferences.getInstance();
      switch (call.method) {
        case 'notificationPermissionResult':
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
          break;
        case 'ignoreBatteryOptimizationsResult':
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
          break;
        case 'pauseTimer':
          await prefs.setBool(prefIsPaused, true);
          final intent = {
            'action': 'com.example.moji_todo.PAUSE',
          };
          print('Received pauseTimer, sending PAUSE intent: $intent');
          await _notificationChannel.invokeMethod('startTimerService', intent);
          context.read<HomeCubit>().pauseTimer();
          break;
        case 'resumeTimer':
          await prefs.setBool(prefIsPaused, false);
          final intent = {
            'action': 'com.example.moji_todo.RESUME',
          };
          print('Received resumeTimer, sending RESUME intent: $intent');
          await _notificationChannel.invokeMethod('startTimerService', intent);
          context.read<HomeCubit>().continueTimer();
          break;
        case 'stopTimer':
          await prefs.setBool(prefIsRunning, false);
          await prefs.setBool(prefIsPaused, false);
          await prefs.setInt(prefTimerSeconds, 0);
          final intent = {
            'action': 'com.example.moji_todo.STOP',
          };
          print('Received stopTimer, sending STOP intent: $intent');
          await _notificationChannel.invokeMethod('startTimerService', intent);
          _isTimerServiceRunning = false;
          context.read<HomeCubit>().stopTimer();
          break;
        case 'updateTimer':
          final timerSeconds = call.arguments['timerSeconds'] as int;
          final isRunning = call.arguments['isRunning'] as bool;
          final isPaused = call.arguments['isPaused'] as bool;
          print('Received updateTimer: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
          await prefs.setInt(prefTimerSeconds, timerSeconds);
          await prefs.setBool(prefIsRunning, isRunning);
          await prefs.setBool(prefIsPaused, isPaused);
          _isTimerServiceRunning = isRunning;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<HomeCubit>().restoreTimerState(
              timerSeconds: timerSeconds,
              isRunning: isRunning,
              isPaused: isPaused,
            );
          });
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
    final hasPermission = await _notificationChannel.invokeMethod('checkNotificationPermission');
    print('Notification Permission: $hasPermission');
    setState(() {
      _hasNotificationPermission = hasPermission;
    });
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

      if (granted != true) {
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
      setState(() {
        _isIgnoringBatteryOptimizations = isIgnoringBatteryOptimizations;
      });

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
      setState(() {
        _hasRequestedBackgroundPermission = true;
      });
    } else {
      setState(() {
        _hasRequestedBackgroundPermission = true;
        _isIgnoringBatteryOptimizations = prefs.getBool('isIgnoringBatteryOptimizations') ?? false;
      });
    }
  }

  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final timerState = await _notificationChannel.invokeMethod('getTimerState');
      int timerSeconds = timerState?['timerSeconds'] ?? prefs.getInt(prefTimerSeconds) ?? 0;
      bool isRunning = timerState?['isRunning'] ?? prefs.getBool(prefIsRunning) ?? false;
      bool isPaused = timerState?['isPaused'] ?? prefs.getBool(prefIsPaused) ?? false;

      context.read<HomeCubit>().restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
      );
      _isTimerServiceRunning = isRunning;
      print('Restored timer state: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused');
    } catch (e) {
      print('Error restoring timer state: $e');
      int timerSeconds = prefs.getInt(prefTimerSeconds) ?? 0;
      bool isRunning = prefs.getBool(prefIsRunning) ?? false;
      bool isPaused = prefs.getBool(prefIsPaused) ?? false;

      context.read<HomeCubit>().restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
      );
      _isTimerServiceRunning = isRunning;
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
                                          context.read<HomeCubit>().selectTask(
                                                task.title ?? 'Untitled Task',
                                                task.estimatedPomodoros ?? 4,
                                              );
                                          context.read<HomeCubit>().startTimer();
                                          Navigator.pop(context);
                                        },
                                        onComplete: () {
                                          context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: true));
                                          if (context.read<HomeCubit>().state.selectedTask == task.title) {
                                            context.read<HomeCubit>().stopTimer();
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

  Future<bool> _checkAndRequestAccessibilityPermission(BuildContext context) async {
    try {
      final bool isPermissionEnabled = await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
      print('Accessibility Permission Enabled: $isPermissionEnabled');
      if (!isPermissionEnabled) {
        bool? granted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Yêu cầu quyền Accessibility'),
            content: const Text('Ứng dụng cần quyền Accessibility để chặn ứng dụng khi Strict Mode được bật. Vui lòng cấp quyền trong cài đặt.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Từ chối'),
              ),
              TextButton(
                onPressed: () async {
                  await _permissionChannel.invokeMethod('requestAccessibilityPermission');
                  Navigator.pop(context, true);
                },
                child: const Text('Cấp quyền'),
              ),
            ],
          ),
        );

        if (granted != true) {
          SystemNavigator.pop();
          return false;
        }

        final bool updatedPermission = await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
        print('Updated Accessibility Permission: $updatedPermission');
        return updatedPermission;
      }
      return true;
    } catch (e) {
      print('Error checking accessibility permission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking accessibility permission: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  void _showStrictModeMenu(BuildContext context) {
    bool isAppBlockingEnabled = context.read<HomeCubit>().state.isAppBlockingEnabled;
    bool isFlipPhoneEnabled = context.read<HomeCubit>().state.isFlipPhoneEnabled;
    bool isExitBlockingEnabled = context.read<HomeCubit>().state.isExitBlockingEnabled;
    List<String> blockedApps = List.from(context.read<HomeCubit>().state.blockedApps);

    final List<Map<String, String>> availableApps = [
      {'name': 'Facebook', 'package': 'com.facebook.katana'},
      {'name': 'YouTube', 'package': 'com.google.android.youtube'},
      {'name': 'Instagram', 'package': 'com.instagram.android'},
      {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically'},
      {'name': 'Twitter', 'package': 'com.twitter.android'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Strict Mode Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text('Tắt'),
                      value: !isAppBlockingEnabled && !isFlipPhoneEnabled && !isExitBlockingEnabled,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            isAppBlockingEnabled = false;
                            isFlipPhoneEnabled = false;
                            isExitBlockingEnabled = false;
                            blockedApps = [];
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Chặn ứng dụng'),
                      value: isAppBlockingEnabled,
                      onChanged: (value) async {
                        if (value == true) {
                          bool permissionGranted = await _checkAndRequestAccessibilityPermission(context);
                          if (!permissionGranted) {
                            return;
                          }
                        }
                        setState(() {
                          isAppBlockingEnabled = value ?? false;
                          if (!isAppBlockingEnabled) {
                            blockedApps = [];
                          }
                        });
                      },
                    ),
                    if (isAppBlockingEnabled)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (appDialogContext) {
                                    return StatefulBuilder(
                                      builder: (context, setAppDialogState) {
                                        return AlertDialog(
                                          title: const Text('Chọn ứng dụng để chặn'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: availableApps.map((app) {
                                                return CheckboxListTile(
                                                  title: Text(app['name']!),
                                                  value: blockedApps.contains(app['package']),
                                                  onChanged: (value) {
                                                    setAppDialogState(() {
                                                      if (value == true) {
                                                        blockedApps.add(app['package']!);
                                                      } else {
                                                        blockedApps.remove(app['package']);
                                                      }
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(appDialogContext);
                                              },
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  context.read<HomeCubit>().updateBlockedApps(blockedApps);
                                                  print('Sending blocked apps to service: $blockedApps');
                                                  _serviceChannel.invokeMethod('setBlockedApps', {'apps': blockedApps});
                                                });
                                                Navigator.pop(appDialogContext);
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              child: const Text(
                                'Danh sách ứng dụng',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    CheckboxListTile(
                      title: const Text('Lật điện thoại'),
                      value: isFlipPhoneEnabled,
                      onChanged: (value) {
                        setState(() {
                          isFlipPhoneEnabled = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Cấm thoát'),
                      value: isExitBlockingEnabled,
                      onChanged: (value) {
                        setState(() {
                          isExitBlockingEnabled = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<HomeCubit>().updateStrictMode(
                          isAppBlockingEnabled: isAppBlockingEnabled,
                          isFlipPhoneEnabled: isFlipPhoneEnabled,
                          isExitBlockingEnabled: isExitBlockingEnabled,
                        );
                    final currentState = context.read<HomeCubit>().state;
                    final newAppBlockingState = isAppBlockingEnabled && currentState.isTimerRunning;
                    if (newAppBlockingState != _lastAppBlockingState) {
                      print('Setting app blocking enabled: $newAppBlockingState');
                      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
                        'enabled': newAppBlockingState,
                      });
                      _lastAppBlockingState = newAppBlockingState;
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('OK'),
                ),
              ],
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
            final homeCubit = context.read<HomeCubit>();
            final selectedTaskTitle = homeCubit.state.selectedTask;
            if (selectedTaskTitle != null) {
              final todayTasks = context.read<TaskCubit>().getCategorizedTasks()['Today'] ?? [];
              final isTaskStillInToday = todayTasks.any((task) => task.title == selectedTaskTitle);
              if (!isTaskStillInToday) {
                homeCubit.resetTask();
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
            previous.isStrictModeEnabled != current.isStrictModeEnabled,
        builder: (context, state) {
          final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
          if (newAppBlockingState != _lastAppBlockingState) {
            print('Updating app blocking state: $newAppBlockingState');
            _serviceChannel.invokeMethod('setAppBlockingEnabled', {
              'enabled': newAppBlockingState,
            });
            _lastAppBlockingState = newAppBlockingState;
          }

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
                    PomodoroTimer(
                      timerSeconds: state.timerSeconds,
                      isRunning: state.isTimerRunning,
                      isPaused: state.isPaused,
                      currentSession: state.currentSession,
                      totalSessions: state.totalSessions,
                      onStart: () async {
                        context.read<HomeCubit>().startTimer();
                        if (_hasNotificationPermission) {
                          final initialSeconds = context.read<HomeCubit>().state.timerSeconds;
                          final intent = {
                            'action': 'START',
                            'timerSeconds': initialSeconds,
                            'isRunning': true,
                            'isPaused': false,
                          };
                          print('Sending START intent: $intent');
                          await _notificationChannel.invokeMethod('startTimerService', intent);
                          _isTimerServiceRunning = true;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt(prefTimerSeconds, initialSeconds);
                          await prefs.setBool(prefIsRunning, true);
                          await prefs.setBool(prefIsPaused, false);
                        }
                      },
                      onPause: () async {
                        context.read<HomeCubit>().pauseTimer();
                        final intent = {
                          'action': 'com.example.moji_todo.PAUSE',
                        };
                        print('Sending PAUSE intent: $intent');
                        await _notificationChannel.invokeMethod('startTimerService', intent);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(prefTimerSeconds, state.timerSeconds);
                        await prefs.setBool(prefIsRunning, state.isTimerRunning);
                        await prefs.setBool(prefIsPaused, true);
                      },
                      onContinue: () async {
                        context.read<HomeCubit>().continueTimer();
                        final intent = {
                          'action': 'com.example.moji_todo.RESUME',
                        };
                        print('Sending RESUME intent: $intent');
                        await _notificationChannel.invokeMethod('startTimerService', intent);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(prefTimerSeconds, state.timerSeconds);
                        await prefs.setBool(prefIsRunning, state.isTimerRunning);
                        await prefs.setBool(prefIsPaused, false);
                      },
                      onStop: () async {
                        context.read<HomeCubit>().stopTimer();
                        final intent = {
                          'action': 'com.example.moji_todo.STOP',
                        };
                        print('Sending STOP intent: $intent');
                        await _notificationChannel.invokeMethod('startTimerService', intent);
                        _isTimerServiceRunning = false;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(prefTimerSeconds, 0);
                        await prefs.setBool(prefIsRunning, false);
                        await prefs.setBool(prefIsPaused, false);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selected Task: ${state.selectedTask ?? 'None'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.warning,
                                color: state.isStrictModeEnabled ? Colors.red : Colors.grey,
                              ),
                              onPressed: () {
                                _showStrictModeMenu(context);
                              },
                            ),
                            Text(
                              'Strict Mode ${state.isStrictModeEnabled ? 'On' : 'Off'}',
                              style: TextStyle(
                                color: state.isStrictModeEnabled ? Colors.red : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.hourglass_empty, color: Colors.grey),
                              onPressed: () {
                                // TODO: Thêm logic cho TimerModeMenu nếu cần
                              },
                            ),
                            const Text(
                              'Timer Mode',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
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
                    // TODO: Nếu muốn tích hợp StrictModeMenu và TimerModeMenu từ tinvo, thay thế IconButton bằng:
                    // const StrictModeMenu(),
                    // const TimerModeMenu(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}