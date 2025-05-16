import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../utils/tag_colors.dart';

class TaskItemCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback onPlayPressed;
  final bool showDetails;
  final EdgeInsets padding;
  final Widget? actionButton;

  const TaskItemCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onCheckboxChanged,
    required this.onPlayPressed,
    this.showDetails = true,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onCheckboxChanged != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0),
                  child: Checkbox(
                    value: task.isCompleted ?? false,
                    onChanged: onCheckboxChanged,
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
                        decoration: task.isCompleted == true ? TextDecoration.lineThrough : null,
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
                            return Text(
                              '#$tag',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: colors['text'],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (showDetails)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (task.estimatedPomodoros != null && task.estimatedPomodoros! > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 14,
                                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${task.estimatedPomodoros}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            if (task.dueDate != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Icon(
                                  Icons.wb_sunny,
                                  size: 14,
                                  color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                                ),
                              ),
                            if (task.priority != null && task.priority!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Icon(
                                  Icons.flag,
                                  size: 14,
                                  color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                                ),
                              ),
                            if (task.project != null && task.project!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bookmark,
                                      size: 14,
                                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.project!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: actionButton ??
                    IconButton(
                      icon: Icon(
                        Icons.play_circle_fill,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                      onPressed: onPlayPressed,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}