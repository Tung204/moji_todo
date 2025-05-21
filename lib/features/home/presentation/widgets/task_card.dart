import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // NEW: Import Bloc
import '../../../tasks/data/models/project_model.dart'; // NEW: Import ProjectModel
import '../../../tasks/data/models/tag_model.dart';     // NEW: Import TagModel
import '../../../tasks/domain/task_cubit.dart';      // NEW: Import TaskCubit để lấy state
import '../../../tasks/data/models/task_model.dart';
// import '../../../tasks/presentation/utils/tag_colors.dart'; // MODIFIED: Sẽ không dùng TagColors nữa

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

  // Hàm helper để lấy icon cho ngày (chỉ trả về IconData)
  // Bạn có thể chuyển hàm này ra một file utils nếu dùng ở nhiều nơi
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
    return Icons.event_outlined; // Đã lên kế hoạch (mặc định)
  }


  @override
  Widget build(BuildContext context) {
    // NEW: Lấy allProjects và allTags từ TaskCubit state
    final taskCubitState = context.watch<TaskCubit>().state;
    final List<Project> allProjects = taskCubitState.allProjects;
    final List<Tag> allTags = taskCubitState.allTags;

    // --- NEW: Lấy thông tin Project ---
    String? projectNameDisplay;
    IconData projectIconData = Icons.bookmark_border; // Icon mặc định

    if (task.projectId != null && task.projectId != 'no_project_id') {
      try {
        final project = allProjects.firstWhere((p) => p.id == task.projectId);
        projectNameDisplay = project.name;
        if (project.icon != null) { // Sử dụng icon từ project nếu có
          projectIconData = project.icon!;
        }
      } catch (e) {
        print('TaskCard: Không tìm thấy project với ID: ${task.projectId} cho task "${task.title}"');
        projectNameDisplay = task.projectId; // Hiển thị ID nếu không tìm thấy
      }
    }
    // --- Hết phần lấy thông tin Project ---

    // MODIFIED: Xác định màu chung cho các icon và text trong dòng chi tiết
    final Color detailIconAndTextColor = Theme.of(context).iconTheme.color?.withOpacity(0.7) ?? Colors.grey.shade600;


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0), // Giống TaskItemCard
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Sử dụng cardColor
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12), // Bo góc giống TaskItemCard
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa items
        children: [
          // Checkbox
          Transform.scale(
            scale: 0.85,
            child: Checkbox(
              value: task.isCompleted ?? false,
              onChanged: (value) {
                if (value != null) {
                  onComplete(); // Gọi callback onComplete
                  // Logic cập nhật task (isCompleted, completionDate) nên được xử lý
                  // bởi widget cha khi nhận callback này (ví dụ trong TaskBottomSheet)
                  // Hoặc, TaskCubit.updateTask được gọi trực tiếp ở đây nếu onComplete chỉ là trigger
                  // context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                }
              },
              shape: const CircleBorder(),
              activeColor: Colors.green,
              checkColor: Theme.of(context).colorScheme.onPrimary,
              side: BorderSide(
                color: task.isCompleted == true ? Colors.green : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                width: 1.5,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector( // Cho phép nhấn vào vùng text để kích hoạt onPlay (nếu task chưa hoàn thành)
              onTap: task.isCompleted == true ? null : onPlay,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TIÊU ĐỀ TASK ---
                  Text(
                    task.title ?? 'Task không có tiêu đề', // Sửa lỗi chính tả "Untitled Task"
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
                  const SizedBox(height: 4),

                  // --- HIỂN THỊ TAGS (Vị trí này giống code cũ) ---
                  if (task.tagIds != null && task.tagIds!.isNotEmpty)
                    Wrap(
                      spacing: 7, // Khoảng cách ngang
                      runSpacing: 4, // Khoảng cách dọc nếu wrap
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
                            color: currentTag.textColor.withOpacity(0.9), // Chỉ màu chữ
                          ),
                        );
                      }).toList(),
                    ),

                  if (task.tagIds != null && task.tagIds!.isNotEmpty)
                    const SizedBox(height: 6), // Khoảng cách nếu có tag


                  // --- DÒNG HIỂN THỊ CHI TIẾT (Pomodoro, DueDate, Priority, Project) ---
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
                              Icon(Icons.timer_outlined, size: 15, color: detailIconAndTextColor),
                              const SizedBox(width: 3),
                              Text(
                                '${task.completedPomodoros ?? 0}/${task.estimatedPomodoros}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: detailIconAndTextColor),
                              ),
                            ],
                          ),
                        ),

                      // 2. DueDate Icon
                      if (task.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(_getDueDateIconData(context, task.dueDate), size: 15, color: detailIconAndTextColor),
                        ),

                      // 3. Priority Icon
                      if (task.priority != null && task.priority!.isNotEmpty && task.priority != 'None')
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(
                            Icons.flag_outlined,
                            size: 15,
                            color: detailIconAndTextColor,
                          ),
                        ),

                      // 4. Project Name
                      if (projectNameDisplay != null)
                        Flexible(
                          fit: FlexFit.loose,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                projectIconData,
                                size: 15,
                                color: detailIconAndTextColor,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  projectNameDisplay,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: detailIconAndTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Bỏ SizedBox(width: 10) ở đây nếu đây là item cuối cùng trong Row này
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Nút Play, chỉ hiển thị nếu task chưa hoàn thành
          if (task.isCompleted != true)
            IconButton(
              icon: Icon(
                Icons.play_circle_fill,
                color: Theme.of(context).colorScheme.secondary,
                size: 27,
              ),
              onPressed: onPlay,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 22,
            ),
        ],
      ),
    );
  }
}