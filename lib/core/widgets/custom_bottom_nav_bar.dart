import 'package:flutter/material.dart';
import '../navigation/navigation_manager.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});
  @override
  Widget build(BuildContext context) {

    return BottomNavigationBar(
      currentIndex: NavigationManager.currentIndex,
      onTap: (index) {
        NavigationManager.navigate(context, index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2B30CB),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.timer),
          label: 'Pomodoro',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.widgets),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Report',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome),
          label: 'Chat',
        ),
      ],
    );
  }
}