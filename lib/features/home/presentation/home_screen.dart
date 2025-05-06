import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../tasks/data/models/task_model.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import 'widgets/pomodoro_timer.dart';
import 'widgets/task_card.dart';
import 'strict_mode_menu.dart'; // Thêm import mới
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/navigation/navigation_manager.dart';
import '../../../routes/app_routes.dart';
import '../../tasks/domain/task_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                                      // BlocListener sẽ tự động gọi resetTask nếu task đang chọn bị hoàn thành
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

  @override
  Widget build(BuildContext context) {
    NavigationManager.currentIndex = 0;

    return MultiBlocListener(
      listeners: [
        BlocListener<TaskCubit, TaskState>(
          listener: (context, taskState) {
            // Khi danh sách task trong TaskCubit cập nhật, kiểm tra xem task đang chọn có còn trong danh sách "Today" không
            final homeCubit = context.read<HomeCubit>();
            final selectedTaskTitle = homeCubit.state.selectedTask;
            if (selectedTaskTitle != null) {
              final todayTasks = context.read<TaskCubit>().getCategorizedTasks()['Today'] ?? [];
              final isTaskStillInToday = todayTasks.any((task) => task.title == selectedTaskTitle);
              if (!isTaskStillInToday) {
                // Nếu task không còn trong "Today" (đã hoàn thành hoặc bị xóa), reset ô "Select Task"
                homeCubit.resetTask();
              }
            }
          },
        ),
      ],
      child: BlocBuilder<HomeCubit, HomeState>(
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
                            if (state.selectedTask != null)
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 8),
                                child: Checkbox(
                                  value: false,
                                  onChanged: (value) {
                                    if (value == true && state.selectedTask != null) {
                                      final todayTasks = context.read<TaskCubit>().getCategorizedTasks()['Today'] ?? [];
                                      if (todayTasks.isNotEmpty) {
                                        final selectedTask = todayTasks.firstWhere(
                                              (task) => task.title == state.selectedTask,
                                          orElse: () {
                                            // If the task is not found, return a default Task with null values
                                            return Task(
                                              title: '',
                                              userId: '',
                                            );
                                          },
                                        );
                                        if (selectedTask.title != '') {
                                          context.read<TaskCubit>().updateTask(selectedTask.copyWith(isCompleted: true));
                                        }
                                      }
                                    }
                                  },
                                  shape: const CircleBorder(),
                                  activeColor: Colors.green,
                                  checkColor: Colors.white,
                                  side: const BorderSide(color: Colors.grey),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                state.selectedTask ?? 'Select Task',
                                style: TextStyle(
                                  color: state.selectedTask != null ? Colors.black : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (state.selectedTask == null)
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
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
                        const StrictModeMenu(), // Thay bằng widget mới
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
      ),
    );
  }
}