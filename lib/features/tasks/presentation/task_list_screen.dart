import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:moji_todo/features/tasks/presentation/widgets/task_item_card.dart';

import '../domain/task_cubit.dart';
import '../data/models/project_tag_repository.dart';
import 'task_detail_screen.dart';
import 'add_task/add_task_bottom_sheet.dart';

class TaskListScreen extends StatelessWidget {
  final String category;

  const TaskListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final projectTagRepository = ProjectTagRepository(
      projectBox: Hive.box('projects'),
      tagBox: Hive.box('tags'),
    );

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                category == 'Today' ? 'Hôm nay' : category,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
        final tasksByProject = context.read<TaskCubit>().getTasksByProject();
        final tasks = categorizedTasks.containsKey(category)
            ? categorizedTasks[category]!
            : tasksByProject[category] ?? [];
        final completedTasks = tasks.where((task) => task.isCompleted == true).toList();
        final waitingTasks = tasks.where((task) => task.isCompleted != true).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              category == 'Today' ? 'Hôm nay' : category,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      final TextEditingController controller = TextEditingController();
                      return AlertDialog(
                        title: Text(
                          'Tìm kiếm task',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Nhập tên task...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            child: Text(
                              'Hủy',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await context.read<TaskCubit>().searchTasks(controller.text);
                              Navigator.pop(dialogContext);
                            },
                            child: Text(
                              'Tìm kiếm',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Sort by Due Date') {
                    context.read<TaskCubit>().sortTasks('dueDate');
                  } else if (value == 'Sort by Priority') {
                    context.read<TaskCubit>().sortTasks('priority');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Sort by Due Date', child: Text('Sắp xếp theo ngày đến hạn')),
                  const PopupMenuItem(value: 'Sort by Priority', child: Text('Sắp xếp theo độ ưu tiên')),
                ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.read<TaskCubit>().calculateTotalTime(tasks).toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tổng thời gian tập trung',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.read<TaskCubit>().calculateElapsedTime(tasks).toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thời gian đã trôi qua',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              waitingTasks.length.toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Task đang chờ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              completedTasks.length.toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Task đã hoàn thành',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                  ),
                  child: GestureDetector(
                    onTap: () {
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
                    child: Text(
                      'Thêm một task.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                    child: Text(
                      'Không có task nào trong danh mục này.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                      : ListView.builder(
                    itemCount: waitingTasks.length + (completedTasks.isNotEmpty ? 1 : 0) + completedTasks.length,
                    itemBuilder: (context, index) {
                      if (index < waitingTasks.length) {
                        final task = waitingTasks[index];
                        if (task == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TaskItemCard(
                            task: task,
                            onTap: () {
                              print('Navigating to TaskDetailScreen with task: ${task.title}, ID: ${task.id}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(task: task),
                                ),
                              );
                            },
                            onCheckboxChanged: (value) {
                              if (value != null) {
                                context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                              }
                            },
                            onPlayPressed: () {
                              // Logic bắt đầu Pomodoro cho task
                            },
                          ),
                        );
                      } else if (index == waitingTasks.length && completedTasks.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Đã hoàn thành',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        );
                      } else {
                        final completedIndex = index - waitingTasks.length - 1;
                        final task = completedTasks[completedIndex];
                        if (task == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TaskItemCard(
                            task: task,
                            onTap: () {
                              print('Navigating to TaskDetailScreen with task: ${task.title}, ID: ${task.id}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(task: task),
                                ),
                              );
                            },
                            onCheckboxChanged: (value) {
                              if (value != null) {
                                context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                              }
                            },
                            onPlayPressed: () {
                              // Logic bắt đầu Pomodoro cho task
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
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