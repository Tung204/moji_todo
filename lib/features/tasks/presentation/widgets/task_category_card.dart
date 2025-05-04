import 'package:flutter/material.dart';

class TaskCategoryCard extends StatelessWidget {
  final String title;
  final String totalTime;
  final int taskCount;
  final Color borderColor;
  final IconData? icon;
  final Color? iconColor;
  final bool isSimple;
  final VoidCallback? onTap;

  const TaskCategoryCard({
    super.key,
    required this.title,
    required this.totalTime,
    required this.taskCount,
    required this.borderColor,
    this.icon,
    this.iconColor,
    this.isSimple = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isSimple
            ? Center(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        )
            : Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                color: iconColor ?? borderColor,
              ),
            if (icon != null) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalTime ($taskCount)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}