import 'package:flutter/material.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../routes/app_routes.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Bỏ nút back
        title: const Text(
          'Report',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: const Center(
        child: Text('Report Screen'),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return; // Đã ở màn hình Report, không làm gì

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.pomodoro);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, AppRoutes.tasks);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.calendar);
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