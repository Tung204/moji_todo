import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/navigation/navigation_manager.dart';
import '../../../routes/app_routes.dart';
import '../domain/task_cubit.dart';
import 'widgets/task_category_card.dart';
import 'add_task/add_task_bottom_sheet.dart';
import 'task_list_screen.dart';

class TaskManageScreen extends StatelessWidget {
  const TaskManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    NavigationManager.currentIndex = 1;

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
        final tasksByProject = context.read<TaskCubit>().getTasksByProject();

        // Danh sách màu viền và icon cho các project
        final projectBorderColors = {
          'Pomodoro App': Colors.red,
          'Fashion App': Colors.green[200]!,
          'AI Chatbot App': Colors.cyan[200]!,
          'Dating App': Colors.pink[200]!,
          'Quiz App': Colors.blue[200]!,
          'News App': Colors.blue[200]!,
          'General': Colors.blue[200]!,
        };
        final projectIcons = {
          'Pomodoro App': Icons.local_pizza_outlined,
          'Fashion App': Icons.check_box_outlined,
          'AI Chatbot App': Icons.smart_toy_outlined,
          'Dating App': Icons.favorite_outline,
          'Quiz App': Icons.quiz_outlined,
          'News App': Icons.newspaper_outlined,
          'General': Icons.category_outlined,
        };

        final spacing = 12.0;

        return Scaffold(
          appBar: const CustomAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2, // Điều chỉnh tỷ lệ để tăng chiều cao, tránh overflow
                  children: [
                    TaskCategoryCard(
                      title: 'Hôm nay',
                      totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Today']!),
                      taskCount: categorizedTasks['Today']!.length,
                      borderColor: Colors.green,
                      icon: Icons.wb_sunny_outlined,
                      iconColor: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TaskListScreen(category: 'Today'),
                          ),
                        );
                      },
                    ),
                    TaskCategoryCard(
                      title: 'Ngày mai',
                      totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Tomorrow']!),
                      taskCount: categorizedTasks['Tomorrow']!.length,
                      borderColor: Colors.blue,
                      icon: Icons.wb_cloudy_outlined,
                      iconColor: Colors.blue,
                    ),
                    TaskCategoryCard(
                      title: 'Tuần này',
                      totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['This Week']!),
                      taskCount: categorizedTasks['This Week']!.length,
                      borderColor: Colors.orange,
                      icon: Icons.calendar_today_outlined,
                      iconColor: Colors.orange,
                    ),
                    TaskCategoryCard(
                      title: 'Đã lên kế hoạch',
                      totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Planned']!),
                      taskCount: categorizedTasks['Planned']!.length,
                      borderColor: Colors.purple,
                      icon: Icons.event_note_outlined,
                      iconColor: Colors.purple,
                    ),
                    TaskCategoryCard(
                      title: 'Đã hoàn thành',
                      totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Completed']!),
                      taskCount: categorizedTasks['Completed']!.length,
                      borderColor: Colors.green[200]!,
                      isSimple: true,
                    ),
                    TaskCategoryCard(
                      title: 'Thùng rác',
                      totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Trash']!),
                      taskCount: categorizedTasks['Trash']!.length,
                      borderColor: Colors.red,
                      isSimple: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Dự án',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2, // Điều chỉnh tỷ lệ để tăng chiều cao, tránh overflow
                  children: tasksByProject.keys.map((project) {
                    return TaskCategoryCard(
                      title: project,
                      totalTime: context.read<TaskCubit>().calculateTotalTime(tasksByProject[project]!),
                      taskCount: tasksByProject[project]!.length,
                      borderColor: projectBorderColors[project] ?? Colors.blue,
                      icon: projectIcons[project],
                      iconColor: projectBorderColors[project] ?? Colors.blue,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 72), // Tăng khoảng trống dưới cùng để tránh che nút Add
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.red,
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
                        title: const Text('Dự án'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.label),
                        title: const Text('Thẻ'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: const CustomBottomNavBar(),
        );
      },
    );
  }
}