import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/task_cubit.dart';
import 'task_detail_screen.dart';
import 'utils/tag_colors.dart';

class CompletedTasksScreen extends StatelessWidget {
  const CompletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Đã hoàn thành',
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
        final completedTasks = categorizedTasks['Completed'] ?? [];

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
              'Đã hoàn thành',
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
                              context.read<TaskCubit>().calculateTotalTime(completedTasks).toString(),
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
                              context.read<TaskCubit>().calculateElapsedTime(completedTasks).toString(),
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
                const SizedBox(height: 16),
                Expanded(
                  child: completedTasks.isEmpty
                      ? Center(
                    child: Text(
                      'Không có task nào đã hoàn thành.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                      : ListView.builder(
                    itemCount: completedTasks.length,
                    itemBuilder: (context, index) {
                      final task = completedTasks[index];
                      if (task == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () {
                              print('Navigating to TaskDetailScreen with task: ${task.title}, ID: ${task.id}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(task: task),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  context.read<TaskCubit>().loadTasks();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0),
                                    child: Checkbox(
                                      value: task.isCompleted ?? false,
                                      onChanged: (value) {
                                        if (value != null) {
                                          context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                                        }
                                      },
                                      shape: const CircleBorder(),
                                      activeColor: Colors.green,
                                      checkColor: Theme.of(context).colorScheme.onSurface,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title ?? 'Task không có tiêu đề',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        if (task.tags != null && task.tags!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: task.tags!.map((tag) {
                                                final colors = TagColors.getTagColors(tag);
                                                return Chip(
                                                  label: Text(
                                                    '#$tag',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontSize: 10,
                                                      color: colors['text'],
                                                    ),
                                                  ),
                                                  backgroundColor: colors['background'],
                                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                                  labelPadding: EdgeInsets.zero,
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.timer, size: 14, color: Theme.of(context).iconTheme.color),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${task.estimatedPomodoros ?? 0}',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              Icon(Icons.wb_sunny, size: 14, color: Theme.of(context).iconTheme.color),
                                              Icon(Icons.nights_stay, size: 14, color: Theme.of(context).iconTheme.color),
                                              Icon(Icons.flag, size: 14, color: Theme.of(context).iconTheme.color),
                                              Icon(Icons.comment, size: 14, color: Theme.of(context).iconTheme.color),
                                              if (task.project != null)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.bookmark, size: 14, color: Theme.of(context).iconTheme.color),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      task.project!,
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 24),
                                      onPressed: () {
                                        // Logic bắt đầu Pomodoro cho task
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}