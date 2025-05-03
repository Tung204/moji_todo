import 'package:flutter/material.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../routes/app_routes.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Bỏ nút back
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: const Center(
        child: Text('Calendar Screen'),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return; // Đã ở màn hình Calendar, không làm gì

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.pomodoro);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoutes.tasks);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutes.report);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, AppRoutes.settings);
              break;
          }
        },
      ),
    );
  }
}