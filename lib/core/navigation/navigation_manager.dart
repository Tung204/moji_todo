import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class NavigationManager {
  static int currentIndex = 0;

  static void navigate(BuildContext context, int index) {
    if (currentIndex == index) return; // Không làm gì nếu đã ở màn hình hiện tại

    currentIndex = index;
    String route;
    switch (index) {
      case 0:
        route = AppRoutes.pomodoro;
        break;
      case 1:
        route = AppRoutes.tasks;
        break;
      case 2:
        route = AppRoutes.calendar;
        break;
      case 3:
        route = AppRoutes.report;
        break;
      case 4:
        route = AppRoutes.aiChat;
        break;
      case 5:
        route = AppRoutes.settings;
        break;
      default:
        return;
    }

    Navigator.pushReplacementNamed(context, route);
  }
}