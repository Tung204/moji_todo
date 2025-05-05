import 'package:flutter/material.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/utils/tag_colors.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onPlay;

  const TaskCard({
    super.key,
    required this.task,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!), // Thêm viền xám nhạt
        borderRadius: BorderRadius.circular(8), // Bo góc
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: task.isCompleted == true
                ? const Icon(
              Icons.check,
              color: Colors.green,
              size: 16,
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title ?? 'Untitled Task',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                if (task.tags != null && task.tags!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: task.tags!.map((tag) {
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
                        labelPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${task.completedPomodoros ?? 0}/${task.estimatedPomodoros ?? 0}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.bookmark, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      task.project ?? 'Pomodoro App',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Color(0xFFFF5733)),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}