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
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: const Text(
                'Đã hoàn thành',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'Đã hoàn thành',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.grey),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      final TextEditingController controller = TextEditingController();
                      return AlertDialog(
                        title: const Text('Tìm kiếm task'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Nhập tên task...',
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
                            onPressed: () async {
                              await context.read<TaskCubit>().searchTasks(controller.text);
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Tìm kiếm'),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.read<TaskCubit>().calculateTotalTime(completedTasks).toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tổng thời gian tập trung',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.read<TaskCubit>().calculateElapsedTime(completedTasks).toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Thời gian đã trôi qua',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                      ? const Center(child: Text('Không có task nào đã hoàn thành.'))
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
                                // Làm mới danh sách sau khi quay lại từ TaskDetailScreen
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
                                      checkColor: Colors.white,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title ?? 'Task không có tiêu đề',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
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
                                                    style: TextStyle(
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
                                                  const Icon(Icons.timer, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${task.estimatedPomodoros ?? 0}',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                              const Icon(Icons.wb_sunny, size: 14, color: Colors.grey),
                                              const Icon(Icons.nights_stay, size: 14, color: Colors.grey),
                                              const Icon(Icons.flag, size: 14, color: Colors.grey),
                                              const Icon(Icons.comment, size: 14, color: Colors.grey),
                                              if (task.project != null)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.bookmark, size: 14, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      task.project!,
                                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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