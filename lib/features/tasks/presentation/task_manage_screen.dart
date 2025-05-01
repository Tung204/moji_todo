import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../routes/app_routes.dart';
import '../domain/task_cubit.dart';
import 'widgets/task_category_card.dart';
import 'add_task_bottom_sheet.dart';

class TaskManageScreen extends StatelessWidget {
  const TaskManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
        final tasksByProject = context.read<TaskCubit>().getTasksByProject();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
                icon: const Icon(Icons.search, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        TaskCategoryCard(
                          title: 'Today',
                          totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Today']!),
                          taskCount: categorizedTasks['Today']!.length,
                          borderColor: Colors.green,
                        ),
                        TaskCategoryCard(
                          title: 'Tomorrow',
                          totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Tomorrow']!),
                          taskCount: categorizedTasks['Tomorrow']!.length,
                          borderColor: Colors.blue,
                        ),
                        TaskCategoryCard(
                          title: 'This Week',
                          totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['This Week']!),
                          taskCount: categorizedTasks['This Week']!.length,
                          borderColor: Colors.orange,
                        ),
                        TaskCategoryCard(
                          title: 'Planned',
                          totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Planned']!),
                          taskCount: categorizedTasks['Planned']!.length,
                          borderColor: Colors.purple,
                        ),
                        TaskCategoryCard(
                          title: 'Completed',
                          totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Completed']!),
                          taskCount: categorizedTasks['Completed']!.length,
                          borderColor: Colors.green,
                        ),
                        TaskCategoryCard(
                          title: 'Trash',
                          totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Trash']!),
                          taskCount: categorizedTasks['Trash']!.length,
                          borderColor: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Projects
                    const Text(
                      'Projects',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: tasksByProject.keys.map((project) {
                        return TaskCategoryCard(
                          title: project,
                          totalTime: context.read<TaskCubit>().calculateTotalTime(tasksByProject[project]!),
                          taskCount: tasksByProject[project]!.length,
                          borderColor: Colors.blue,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Task'),
                              onTap: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => const AddTaskBottomSheet(),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.work),
                              title: const Text('Project'),
                              onTap: () {
                                // Logic thêm project
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.label),
                              title: const Text('Tags'),
                              onTap: () {
                                // Logic thêm tags
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 1, // "Manage" tab
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, AppRoutes.pomodoro);
                  break;
                case 1:
                // Đã ở màn hình Manage
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
            },
          ),
        );
      },
    );
  }
}