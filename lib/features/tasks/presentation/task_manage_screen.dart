import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/custom_app_bar.dart'; // Import CustomAppBar
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/navigation/navigation_manager.dart'; // Import NavigationManager
import '../../../routes/app_routes.dart';
import '../domain/task_cubit.dart';
import 'widgets/task_category_card.dart';
import 'add_task/add_task_bottom_sheet.dart';

class TaskManageScreen extends StatelessWidget {
  const TaskManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Đặt currentIndex cho Tasks
    NavigationManager.currentIndex = 1;

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
        final tasksByProject = context.read<TaskCubit>().getTasksByProject();

        return Scaffold(
          appBar: const CustomAppBar(),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.label),
                              title: const Text('Tags'),
                              onTap: () {
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
          bottomNavigationBar: const CustomBottomNavBar(),
        );
      },
    );
  }
}