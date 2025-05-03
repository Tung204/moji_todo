import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart'; // Import CustomAppBar
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/navigation/navigation_manager.dart'; // Import NavigationManager
import '../../../routes/app_routes.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Đặt currentIndex cho Pomodoro
    NavigationManager.currentIndex = 0;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: const Center(
        child: Text('Pomodoro Screen'),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}