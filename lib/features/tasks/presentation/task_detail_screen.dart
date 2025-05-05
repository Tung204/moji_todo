import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/task_cubit.dart';
import '../data/models/task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task? task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    if (task == null) {
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
        ),
        body: const Center(
          child: Text('Không tìm thấy task.'),
        ),
      );
    }

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
        title: Text(
          task!.title ?? 'Task không có tiêu đề',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Delete') {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    bool isLoading = false; // Trạng thái loading
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Xóa Task'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Bạn có chắc muốn xóa task "${task!.title}" không?'),
                              if (isLoading) ...[
                                const SizedBox(height: 16),
                                const CircularProgressIndicator(),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: isLoading
                                  ? null // Vô hiệu hóa nút khi đang loading
                                  : () {
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null // Vô hiệu hóa nút khi đang loading
                                  : () async {
                                setState(() {
                                  isLoading = true; // Bật trạng thái loading
                                });
                                try {
                                  await context.read<TaskCubit>().deleteTask(task!);
                                  Navigator.pop(dialogContext);
                                  Navigator.pop(context, true); // Truyền thông báo xóa thành công về TaskListScreen
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi khi xóa task: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Xóa',
                                style: TextStyle(color: Colors.red),
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
              value: task!.dueDate != null ? task!.dueDate.toString() : 'Hôm nay',
            ),
            _buildTaskDetailItem(
              icon: Icons.priority_high,
              title: 'Độ ưu tiên',
              value: task!.priority ?? 'Trung bình',
            ),
            _buildTaskDetailItem(
              icon: Icons.work,
              title: 'Dự án',
              value: task!.project ?? 'Pomodoro App',
            ),
            _buildTaskDetailItem(
              icon: Icons.alarm,
              title: 'Nhắc nhở',
              value: 'Hôm nay, 10:00 AM', // Giả định, có thể thay đổi sau
            ),
            _buildTaskDetailItem(
              icon: Icons.repeat,
              title: 'Lặp lại',
              value: 'Không', // Giả định, có thể thay đổi sau
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
              children: task!.tags?.map((tag) => Chip(
                label: Text(
                  '#$tag',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
                backgroundColor: Colors.blue[50],
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ))?.toList() ??
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
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Text(value, style: const TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }
}