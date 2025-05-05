import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import 'widgets/pomodoro_timer.dart';
import 'widgets/task_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/navigation/navigation_manager.dart';
import '../../../routes/app_routes.dart';
import '../../tasks/domain/task_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const MethodChannel _permissionChannel = MethodChannel('com.example.moji_todo/permissions');
  static const MethodChannel _serviceChannel = MethodChannel('com.example.moji_todo/app_block_service');

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
          builder: (context, setState) {
            return Padding(
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
                    onChanged: (value) {
                      setState(() {
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
                                      context.read<HomeCubit>().stopTimer();
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
            );
          },
        );
      },
    );
  }

  Future<bool> _checkAndRequestAccessibilityPermission(BuildContext context) async {
    try {
      final bool isPermissionEnabled = await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
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

        return await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
      }
      return true;
    } catch (e) {
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
                    // Truy cập state từ HomeCubit
                    final currentState = context.read<HomeCubit>().state;
                    _serviceChannel.invokeMethod('setAppBlockingEnabled', {
                      'enabled': isAppBlockingEnabled && currentState.isTimerRunning,
                    });
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

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        // Cập nhật trạng thái chặn ứng dụng mỗi khi timer thay đổi
        _serviceChannel.invokeMethod('setAppBlockingEnabled', {
          'enabled': state.isAppBlockingEnabled && state.isTimerRunning,
        });

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
                    onStart: () {
                      context.read<HomeCubit>().startTimer();
                    },
                    onPause: () {
                      context.read<HomeCubit>().pauseTimer();
                    },
                    onContinue: () {
                      context.read<HomeCubit>().continueTimer();
                    },
                    onStop: () {
                      context.read<HomeCubit>().stopTimer();
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
                            onPressed: () {},
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}