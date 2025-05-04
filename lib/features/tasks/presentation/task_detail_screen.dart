import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/task_cubit.dart';
import '../data/models/task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
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
          task.title ?? 'Untitled Task',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Delete') {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Delete Task'),
                      content: Text('Are you sure you want to delete the "${task.title}" task?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<TaskCubit>().deleteTask(task);
                            Navigator.pop(dialogContext);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task has been deleted!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          child: const Text(
                            'Yes, Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Pin', child: Text('Pin')),
              const PopupMenuItem(value: 'Share', child: Text('Share')),
              const PopupMenuItem(value: 'Duplicate', child: Text('Duplicate')),
              const PopupMenuItem(value: 'Comment', child: Text('Comment')),
              const PopupMenuItem(value: 'Location', child: Text('Location')),
              const PopupMenuItem(value: 'Delete', child: Text('Delete')),
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
              value: '${task.completedPomodoros ?? 0}/${task.estimatedPomodoros ?? 0}',
            ),
            _buildTaskDetailItem(
              icon: Icons.calendar_today,
              title: 'Due Date',
              value: task.dueDate != null ? task.dueDate.toString() : 'Today',
            ),
            _buildTaskDetailItem(
              icon: Icons.priority_high,
              title: 'Priority',
              value: task.priority ?? 'Medium',
            ),
            _buildTaskDetailItem(
              icon: Icons.work,
              title: 'Project',
              value: task.project ?? 'Pomodoro App',
            ),
            _buildTaskDetailItem(
              icon: Icons.alarm,
              title: 'Reminder',
              value: 'Today, 10:00 AM', // Giả định, có thể thay đổi sau
            ),
            _buildTaskDetailItem(
              icon: Icons.repeat,
              title: 'Repeat',
              value: 'None', // Giả định, có thể thay đổi sau
            ),
            const SizedBox(height: 16),
            const Text(
              'Subtasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (task.subtasks != null && task.subtasks!.isNotEmpty)
              ...task.subtasks!.map((subtask) => ListTile(
                leading: Checkbox(
                  value: subtask['completed'] ?? false,
                  onChanged: (value) {
                    // Cập nhật trạng thái subtask
                  },
                ),
                title: Text(subtask['title'] ?? 'Untitled Subtask'),
              )),
            TextButton(
              onPressed: () {
                // Thêm subtask mới
              },
              child: const Text(
                'Add a subtask',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: task.tags?.map((tag) => Chip(
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
              'Add a Note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(task.note ?? 'No note'),
            const SizedBox(height: 16),
            const Text(
              'Attachment',
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