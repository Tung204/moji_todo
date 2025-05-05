import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/navigation/navigation_manager.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    NavigationManager.currentIndex = 0;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: const Center(
        child: Text('Pomodoro Screen'),
      ),
    );
  }
}