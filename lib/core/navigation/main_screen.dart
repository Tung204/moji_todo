import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/home/domain/home_cubit.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/tasks/presentation/task_manage_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/ai_chat/presentation/ai_chat_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TaskManageScreen(),
    const CalendarScreen(),
    const ReportScreen(),
    const AIChatScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}