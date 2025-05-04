import 'package:flutter/material.dart';

class TaskCategoryCard extends StatelessWidget {
  final String title;
  final String totalTime;
  final int taskCount;
  final Color borderColor;
  final IconData? icon;
  final Color? iconColor;
  final bool showDetails;
  final bool isCompact; // Thêm tham số để làm gọn ô
  final VoidCallback? onTap;

  const TaskCategoryCard({
    super.key,
    required this.title,
    required this.totalTime,
    required this.taskCount,
    required this.borderColor,
    this.icon,
    this.iconColor,
    this.showDetails = true,
    this.isCompact = false, // Mặc định không làm gọn
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 8 : 12), // Padding nhỏ hơn khi isCompact
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều ngang
          children: [
            if (icon != null)
              Icon(
                icon,
                color: iconColor ?? borderColor,
              ),
            if (icon != null) const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (showDetails) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$totalTime ($taskCount)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}