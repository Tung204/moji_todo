import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Để định dạng ngày nếu cần
import '../../data/models/project_model.dart';
import '../../data/models/tag_model.dart';
import '../../domain/task_cubit.dart';
import '../../data/models/task_model.dart';

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
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
    this.actionButton,
  });

  // Hàm helper để lấy icon cho ngày (chỉ trả về IconData)
  IconData _getDueDateIconData(BuildContext context, DateTime? dueDate) {
    if (dueDate == null) {
      return Icons.calendar_today_outlined; // Icon mặc định nếu không có ngày
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateOnly.isAtSameMomentAs(today)) {
      return Icons.wb_sunny_outlined; // Hôm nay
    } else if (dueDateOnly.isAtSameMomentAs(tomorrow)) {
      return Icons.wb_cloudy_outlined; // Ngày mai
    }
    // Bạn có thể thêm logic cho "Tuần này" nếu muốn
    return Icons.event_outlined; // Đã lên kế hoạch (mặc định)
  }

  @override
  Widget build(BuildContext context) {
    final taskCubitState = context.watch<TaskCubit>().state;
    final List<Project> allProjects = taskCubitState.allProjects;
    final List<Tag> allTags = taskCubitState.allTags;

    String? projectNameDisplay;
    // Không cần projectColorDisplayForIcon nữa vì tất cả icon sẽ dùng màu chung
    IconData projectIconData = Icons.bookmark_border; // Icon mặc định cho project

    if (task.projectId != null && task.projectId != 'no_project_id') {
      try {
        final project = allProjects.firstWhere((p) => p.id == task.projectId);
        projectNameDisplay = project.name;
        if (project.icon != null) {
          projectIconData = project.icon!;
        }
      } catch (e) {
        print('TaskItemCard: Không tìm thấy project với ID: ${task.projectId} cho task "${task.title}"');
        projectNameDisplay = task.projectId;
      }
    }

    // MODIFIED: Xác định màu chung cho các icon và text trong dòng chi tiết
    final Color detailIconAndTextColor = Theme.of(context).iconTheme.color?.withOpacity(0.7) ?? Colors.grey.shade600;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onCheckboxChanged != null)
                Transform.scale(
                  scale: 0.85,
                  child: Checkbox(
                    value: task.isCompleted ?? false,
                    onChanged: onCheckboxChanged,
                    shape: const CircleBorder(),
                    activeColor: Colors.green,
                    checkColor: Theme.of(context).colorScheme.onPrimary,
                    side: MaterialStateBorderSide.resolveWith(
                          (states) => BorderSide(color: states.contains(MaterialState.selected) ? Colors.green : Colors.red, width: 1.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              if (onCheckboxChanged != null) const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TIÊU ĐỀ TASK ---
                    Text(
                      task.title ?? 'Task không có tiêu đề',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: task.isCompleted == true ? TextDecoration.lineThrough : null,
                        color: task.isCompleted == true
                            ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                            : Theme.of(context).textTheme.titleMedium?.color,
                        fontWeight: task.isCompleted == true ? FontWeight.normal : FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // --- HIỂN THỊ TAGS ---
                    if (task.tagIds != null && task.tagIds!.isNotEmpty)
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        children: task.tagIds!.map((tagId) {
                          Tag? currentTag;
                          try {
                            currentTag = allTags.firstWhere((t) => t.id == tagId);
                          } catch (e) { /* Lỗi đã được log */ }
                          if (currentTag == null) return const SizedBox.shrink();
                          return Text(
                            '#${currentTag.name}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: currentTag.textColor.withOpacity(0.9),
                            ),
                          );
                        }).toList(),
                      ),

                    if (task.tagIds != null && task.tagIds!.isNotEmpty && showDetails)
                      const SizedBox(height: 7),

                    // --- DÒNG HIỂN THỊ CHI TIẾT (THEO THỨ TỰ MỚI VÀ MÀU ĐỒNG NHẤT) ---
                    if (showDetails)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Pomodoro
                          if (task.estimatedPomodoros != null && task.estimatedPomodoros! > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 15, color: detailIconAndTextColor), // MODIFIED: Màu
                                  const SizedBox(width: 3),
                                  Text(
                                    '${task.completedPomodoros ?? 0}/${task.estimatedPomodoros}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: detailIconAndTextColor), // MODIFIED: Màu
                                  ),
                                ],
                              ),
                            ),

                          // 2. DueDate Icon
                          if (task.dueDate != null) // Chỉ hiển thị nếu có dueDate
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Icon(_getDueDateIconData(context, task.dueDate), size: 15, color: detailIconAndTextColor), // MODIFIED: Màu
                            ),

                          // 3. Priority Icon
                          if (task.priority != null && task.priority!.isNotEmpty && task.priority != 'None')
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Icon(
                                Icons.flag_outlined,
                                size: 15,
                                color: detailIconAndTextColor, // MODIFIED: Màu
                              ),
                            ),

                          // 4. Project Name
                          if (projectNameDisplay != null)
                            Flexible(
                              fit: FlexFit.loose,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 0), // Bỏ padding right ở đây nếu là item cuối
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      projectIconData,
                                      size: 15,
                                      color: detailIconAndTextColor, // MODIFIED: Màu
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        projectNameDisplay,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          color: detailIconAndTextColor, // MODIFIED: Màu
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              // Nút Action Button hoặc Play
              if (actionButton != null)
                actionButton!
              else if (task.isCompleted != true)
                IconButton(
                  icon: Icon(
                    Icons.play_circle,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 27,
                  ),
                  onPressed: onPlayPressed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}