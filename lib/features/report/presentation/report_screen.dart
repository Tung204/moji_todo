import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart'; // Import CustomAppBar
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/navigation/navigation_manager.dart'; // Import NavigationManager
import '../../../routes/app_routes.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Đặt currentIndex cho Report
    NavigationManager.currentIndex = 3;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: const Center(
        child: Text('Report Screen'),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}