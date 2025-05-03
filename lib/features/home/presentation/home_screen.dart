import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/home_cubit.dart';
import 'widgets/pomodoro_timer.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../routes/app_routes.dart';
import '../../tasks/domain/task_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return; // Đã ở màn hình hiện tại, không làm gì

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
      // Đã ở Home (Pomodoro), không làm gì
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.tasks);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.calendar);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.report);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.settings);
        break;
    }
  }

  void _showTaskBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                decoration: InputDecoration(
                  hintText: 'Search task...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...state.tasks.map((task) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title ?? 'Untitled Task',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        if (task.tags != null)
                                          ...task.tags!.map((tag) => Chip(
                                            label: Text(
                                              '#$tag',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            backgroundColor: Colors.blue[50],
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                          )),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${task.completedPomodoros ?? 0}/${task.estimatedPomodoros ?? 0}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.bookmark, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.project ?? 'Pomodoro App',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: Color(0xFFFF5733)),
                                onPressed: () {
                                  context.read<HomeCubit>().selectTask(task.title ?? 'Untitled Task');
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      }),
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
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE6F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Bỏ nút back
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00C4FF), Color(0xFFFF69B4)],
            ).createShader(bounds),
            child: const Text(
              'Moji-ToDo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
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
                      const Text(
                        'Select Task',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      PomodoroTimer(
                        minutes: state.timerMinutes,
                        isRunning: state.isTimerRunning,
                        onStart: () {
                          context.read<HomeCubit>().startTimer();
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Selected Task: ${state.selectedTask ?? 'None'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.warning, color: Colors.grey),
                        onPressed: () {},
                      ),
                      const Text(
                        'Strict Mode',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
        ),
      ),
    );
  }
}