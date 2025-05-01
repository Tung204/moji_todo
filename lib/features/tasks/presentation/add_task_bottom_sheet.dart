import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../domain/task_cubit.dart';
import '../data/models/task_model.dart';

class AddTaskBottomSheet extends StatefulWidget {
  const AddTaskBottomSheet({super.key});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  int _estimatedPomodoros = 1;
  DateTime? _dueDate;
  String? _priority;
  List<String> _tags = [];
  String? _project;

  final List<String> _availableTags = [
    'Urgent', 'Personal', 'Work', 'Home', 'Important', 'Design', 'Research', 'Productive'
  ];
  final List<String> _availableProjects = [
    'General', 'Pomodoro App', 'Fashion App', 'AI Chatbot App', 'Dating App', 'Quiz App', 'News App', 'Work Project'
  ];

  void _showDueDatePicker(BuildContext context) {
    DateTime selectedDate = _dueDate ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép cuộn
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // Thêm SingleChildScrollView để cuộn
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Due Date',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildDateCard('Today', Colors.green, Icons.wb_sunny, DateTime.now()),
                    _buildDateCard('Tomorrow', Colors.blue, Icons.wb_sunny, DateTime.now().add(const Duration(days: 1))),
                    _buildDateCard('This Week', Colors.purple, Icons.calendar_today, DateTime.now().add(const Duration(days: 7))),
                    _buildDateCard('Planned', Colors.red, Icons.check_circle, null),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300, // Đặt chiều cao cố định cho TableCalendar
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime(2030),
                    focusedDay: selectedDate,
                    selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        selectedDate = selectedDay;
                      });
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _dueDate = selectedDate;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateCard(String label, Color color, IconData icon, DateTime? date) {
    return GestureDetector(
      onTap: () {
        if (date != null) {
          setState(() {
            _dueDate = date;
          });
          Navigator.pop(context);
        }
      },
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Priority',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPriorityOption(context, 'High', Colors.red),
              _buildPriorityOption(context, 'Medium', Colors.orange),
              _buildPriorityOption(context, 'Low', Colors.green),
              _buildPriorityOption(context, 'No Priority', Colors.grey),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityOption(BuildContext context, String label, Color color) {
    return ListTile(
      leading: Icon(Icons.flag, color: color),
      title: Text('$label Priority'),
      trailing: _priority == label ? const Icon(Icons.check, color: Colors.red) : null,
      onTap: () {
        setState(() {
          _priority = label;
        });
      },
    );
  }

  void _showTagsPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tags',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableTags.length,
                  itemBuilder: (context, index) {
                    final tag = _availableTags[index];
                    final isSelected = _tags.contains(tag);
                    return ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                      title: Text(tag),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.red) : null,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _tags.remove(tag);
                          } else {
                            _tags.add(tag);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProjectPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Project',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableProjects.length,
                  itemBuilder: (context, index) {
                    final project = _availableProjects[index];
                    final isSelected = _project == project;
                    return ListTile(
                      leading: const Icon(Icons.work, color: Colors.grey),
                      title: Text(project),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.red) : null,
                      onTap: () {
                        setState(() {
                          _project = project;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Add a Task...',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Estimated Pomodoros',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(8, (index) {
                final pomodoros = index + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text('$pomodoros'),
                    selected: _estimatedPomodoros == pomodoros,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _estimatedPomodoros = pomodoros;
                        });
                      }
                    },
                    selectedColor: Colors.red,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _estimatedPomodoros == pomodoros ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.green),
                    onPressed: () => _showDueDatePicker(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag, color: Colors.orange),
                    onPressed: () => _showPriorityPicker(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.label, color: Colors.blue),
                    onPressed: () => _showTagsPicker(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.work, color: Colors.red),
                    onPressed: () => _showProjectPicker(context),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty) {
                    final task = Task(
                      id: DateTime.now().millisecondsSinceEpoch,
                      title: _titleController.text,
                      estimatedPomodoros: _estimatedPomodoros,
                      completedPomodoros: 0,
                      dueDate: _dueDate,
                      priority: _priority,
                      tags: _tags,
                      project: _project,
                    );
                    context.read<TaskCubit>().addTask(task);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}