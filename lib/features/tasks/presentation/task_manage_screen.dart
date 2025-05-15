import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../data/models/project_tag_repository.dart';
import '../domain/task_cubit.dart';
import 'add_project_and_tags/add_project_screen.dart';
import 'add_project_and_tags/add_tag_screen.dart';
import 'manage_project_and_tags/manage_projects_tags_screen.dart';
import 'widgets/task_category_card.dart';
import 'add_task/add_task_bottom_sheet.dart';
import 'task_list_screen.dart';
import 'trash_screen.dart';
import 'completed_tasks_screen.dart';

class TaskManageScreen extends StatelessWidget {
  const TaskManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: const CustomAppBar(),
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để tiếp tục.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final projectTagRepository = ProjectTagRepository(
      projectBox: Hive.box('projects'),
      tagBox: Hive.box('tags'),
    );

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
        final tasksByProject = context.read<TaskCubit>().getTasksByProject();

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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Manage Tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                onSelected: (value) {
                  if (value == 'Manage Projects and Tags') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageProjectsTagsScreen(
                          repository: projectTagRepository,
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Manage Projects and Tags',
                    child: Text('Manage Projects and Tags'),
                  ),
                ],
              ),
            ],
          ),
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
                  childAspectRatio: 2,
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TaskListScreen(category: 'Tomorrow'),
                          ),
                        );
                      },
                    ),
                    TaskCategoryCard(
                      title: 'Tuần này',
                      totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['This Week']!),
                      taskCount: categorizedTasks['This Week']!.length,
                      borderColor: Colors.orange,
                      icon: Icons.calendar_today_outlined,
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TaskListScreen(category: 'This Week'),
                          ),
                        );
                      },
                    ),
                    TaskCategoryCard(
                      title: 'Đã lên kế hoạch',
                      totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Planned']!),
                      taskCount: categorizedTasks['Planned']!.length,
                      borderColor: Colors.purple,
                      icon: Icons.event_note_outlined,
                      iconColor: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TaskListScreen(category: 'Planned'),
                          ),
                        );
                      },
                    ),
                    TaskCategoryCard(
                      title: 'Đã hoàn thành',
                      totalTime: '',
                      taskCount: categorizedTasks['Completed']!.length,
                      borderColor: Colors.green[200]!,
                      icon: Icons.check,
                      iconColor: Colors.green[200]!,
                      showDetails: false,
                      isCompact: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CompletedTasksScreen(),
                          ),
                        );
                      },
                    ),
                    TaskCategoryCard(
                      title: 'Thùng rác',
                      totalTime: '',
                      taskCount: 0,
                      borderColor: Colors.red,
                      icon: Icons.delete,
                      iconColor: Colors.red,
                      showDetails: false,
                      isCompact: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TrashScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Dự án',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2,
                  children: tasksByProject.keys.map((project) {
                    return TaskCategoryCard(
                      title: project,
                      totalTime: context.read<TaskCubit>().calculateTotalTime(tasksByProject[project]!),
                      taskCount: tasksByProject[project]!.length,
                      borderColor: projectBorderColors[project] ?? Colors.blue,
                      icon: projectIcons[project],
                      iconColor: projectBorderColors[project] ?? Colors.blue,
                      onTap: () { // THÊM: Xử lý nhấn vào dự án
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskListScreen(category: project),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 72),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'tasks_fab',
            backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                builder: (context) => AddTaskBottomSheet(
                  repository: projectTagRepository,
                ),
              );
            },
            child: Icon(Icons.add, color: Theme.of(context).floatingActionButtonTheme.foregroundColor),
          ),
        );
      },
    );
  }
}