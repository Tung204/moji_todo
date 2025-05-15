import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/task_cubit.dart';
import '../data/models/task_model.dart';
import 'utils/tag_colors.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task? task;

  const TaskDetailScreen({super.key, required this.task});

  // Hàm định dạng dueDate thành "Today", "Tomorrow", hoặc ngày cụ thể
  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Hôm nay';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateOnly.isAtSameMomentAs(today)) {
      return 'Hôm nay';
    } else if (dueDateOnly.isAtSameMomentAs(tomorrow)) {
      return 'Ngày mai';
    } else {
      return '${dueDate.day}/${dueDate.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (task == null) {
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
        ),
        body: Center(
          child: Text(
            'Không tìm thấy task.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final isInTrash = task!.category == 'Trash';

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
          task!.title ?? 'Task không có tiêu đề',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Delete') {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    bool isLoading = false;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: Text(isInTrash ? 'Xóa vĩnh viễn' : 'Xóa Task',style: Theme.of(context).textTheme.titleLarge,),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(isInTrash
                                  ? 'Bạn có chắc muốn xóa vĩnh viễn task "${task!.title}" không?'
                                  : 'Task "${task!.title}" sẽ được chuyển vào Thùng rác. Bạn có muốn tiếp tục?',
                                style: Theme.of(context).textTheme.bodyMedium,),
                              if (isLoading) ...[
                                const SizedBox(height: 16),
                                const CircularProgressIndicator(),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                Navigator.pop(dialogContext);
                              },
                              child: Text('Hủy',style: Theme.of(context).textTheme.bodyMedium,),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                setState(() {
                                  isLoading = true;
                                });
                                try {
                                  if (isInTrash) {
                                    await context.read<TaskCubit>().deleteTask(task!);
                                    Navigator.pop(dialogContext);
                                    Navigator.pop(context, true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Task đã được xóa vĩnh viễn!',style: Theme.of(context).textTheme.bodyMedium,),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    await context.read<TaskCubit>().updateTask(
                                      task!.copyWith(
                                        category: 'Trash',
                                        originalCategory: task!.category ?? 'Planned',
                                      ),
                                    );
                                    Navigator.pop(dialogContext);
                                    Navigator.pop(context, true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Task đã được chuyển vào Thùng rác!', style: Theme.of(context).textTheme.bodyMedium,),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: $e',style: Theme.of(context).textTheme.bodyMedium,),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                isInTrash ? 'Xóa vĩnh viễn' : 'Xóa',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                              ),
                            ),
                            if (isInTrash)
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  try {
                                    await context.read<TaskCubit>().restoreTask(task!);
                                    Navigator.pop(dialogContext);
                                    Navigator.pop(context, true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Task đã được khôi phục!'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi khi khôi phục: $e'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Khôi phục',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Pin', child: Text('Ghim')),
              const PopupMenuItem(value: 'Share', child: Text('Chia sẻ')),
              const PopupMenuItem(value: 'Duplicate', child: Text('Nhân bản')),
              const PopupMenuItem(value: 'Comment', child: Text('Bình luận')),
              const PopupMenuItem(value: 'Location', child: Text('Vị trí')),
              const PopupMenuItem(value: 'Delete', child: Text('Xóa')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTaskDetailItem(
              icon: Icons.timer,
              title: 'Pomodoro',
              value: '${task!.completedPomodoros ?? 0}/${task!.estimatedPomodoros ?? 0}',
            ),
            _buildTaskDetailItem(
              icon: Icons.calendar_today,
              title: 'Ngày đến hạn',
              value: _formatDueDate(task!.dueDate),
              backgroundColor: Colors.blue[50],
            ),
            _buildTaskDetailItem(
              icon: Icons.priority_high,
              title: 'Độ ưu tiên',
              value: task!.priority ?? 'Trung bình',
              backgroundColor: Colors.red[50],
            ),
            _buildTaskDetailItem(
              icon: Icons.work,
              title: 'Dự án',
              value: task!.project ?? 'Pomodoro App',
            ),
            _buildTaskDetailItem(
              icon: Icons.alarm,
              title: 'Nhắc nhở',
              value: 'Hôm nay, 10:00 AM',
            ),
            _buildTaskDetailItem(
              icon: Icons.repeat,
              title: 'Lặp lại',
              value: 'Không',
            ),
            const SizedBox(height: 16),
            const Text(
              'Subtasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (task!.subtasks != null && task!.subtasks!.isNotEmpty)
              ...task!.subtasks!.map((subtask) => ListTile(
                leading: Checkbox(
                  value: subtask['completed'] ?? false,
                  onChanged: (value) {
                    // Cập nhật trạng thái subtask
                  },
                ),
                title: Text(subtask['title'] ?? 'Subtask không có tiêu đề'),
              )),
            TextButton(
              onPressed: () {
                // Thêm subtask mới
              },
              child: const Text(
                'Thêm subtask',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thẻ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: task!.tags?.map((tag) {
                final colors = TagColors.getTagColors(tag);
                return Chip(
                  label: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors['text'],
                    ),
                  ),
                  backgroundColor: colors['background'],
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              })?.toList() ??
                  [],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ghi chú',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(task!.note ?? 'Không có ghi chú'),
            const SizedBox(height: 16),
            const Text(
              'Tệp đính kèm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.grey),
              title: const Text('Design Brief - Pomodoro App.pdf'),
              trailing: IconButton(
                icon: const Icon(Icons.download, color: Colors.grey),
                onPressed: () {
                  // Tải file
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}