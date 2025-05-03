import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/navigation/navigation_manager.dart';
import '../../../routes/app_routes.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    NavigationManager.currentIndex = 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return isSameDay(DateTime.now(), day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                // Xử lý khi người dùng chọn ngày
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhiệm vụ trong ngày',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Hiển thị danh sách nhiệm vụ tại đây
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}