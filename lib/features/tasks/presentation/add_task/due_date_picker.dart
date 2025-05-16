import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DueDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateSelected;

  const DueDatePicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<DueDatePicker> createState() => _DueDatePickerState();
}

class _DueDatePickerState extends State<DueDatePicker> {
  late DateTime selectedDate;
  final DateTime now = DateTime.now();
  String? _selectedQuickOption; // Theo dõi nút chọn nhanh nào được chọn
  bool _isTapped = false; // Theo dõi trạng thái nhấn để tạo hiệu ứng

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? now;
  }

  void _updateSelectedDate(DateTime? date, String? quickOption) {
    setState(() {
      if (date != null) {
        selectedDate = date;
      } else {
        selectedDate = now;
      }
      _selectedQuickOption = quickOption;
    });
    widget.onDateSelected(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Due Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularDateOption('Today', Colors.green, Icons.wb_sunny, now),
                _buildCircularDateOption('Tomorrow', Colors.blue, Icons.wb_sunny, now.add(const Duration(days: 1))),
                _buildCircularDateOption('This Week', Colors.purple, Icons.calendar_today, now.add(const Duration(days: 7))),
                _buildCircularDateOption('Planned', Colors.red, Icons.check_circle, null),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: TableCalendar(
                firstDay: now,
                lastDay: now.add(const Duration(days: 365 * 2)),
                focusedDay: selectedDate,
                selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                enabledDayPredicate: (day) {
                  return day.isAfter(now.subtract(const Duration(days: 1)));
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (selectedDay.isAfter(now.subtract(const Duration(days: 1)))) {
                    setState(() {
                      selectedDate = selectedDay;
                      _selectedQuickOption = null;
                    });
                    widget.onDateSelected(selectedDay);
                  }
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black, size: 20),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ),
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                  disabledTextStyle: TextStyle(color: Colors.grey),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  weekendStyle: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                daysOfWeekHeight: 20,
                rowHeight: 40,
                calendarFormat: CalendarFormat.month,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularDateOption(String label, Color color, IconData icon, DateTime? date) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        _updateSelectedDate(date, label);
        Navigator.pop(context); // Đóng bottom sheet ngay sau khi chọn
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _isTapped ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 90,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}