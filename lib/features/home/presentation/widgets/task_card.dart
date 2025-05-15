import 'package:flutter/material.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/utils/tag_colors.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onPlay;
  final VoidCallback onComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onPlay,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            child: Checkbox(
              value: task.isCompleted ?? false,
              onChanged: (value) {
                if (value != null && value) {
                  onComplete();
                }
              },
              shape: const CircleBorder(),
              activeColor: Colors.green,
              checkColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onPlay,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title ?? 'Untitled Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      decoration: task.isCompleted == true ? TextDecoration.lineThrough : null,
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.completedPomodoros ?? 0}/${task.estimatedPomodoros ?? 0}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.bookmark,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.project ?? 'Pomodoro App',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.play_circle_fill,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}