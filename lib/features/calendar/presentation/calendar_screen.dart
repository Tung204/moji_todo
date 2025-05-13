import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/domain/task_cubit.dart';
import '../../tasks/presentation/add_task/add_task_bottom_sheet.dart';
import '../../tasks/presentation/task_detail_screen.dart';
import '../../tasks/presentation/utils/tag_colors.dart';
import '../../tasks/data/models/project_tag_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    context.read<TaskCubit>().loadTasks();
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> tasks) {
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final selectedDate = DateTime(day.year, day.month, day.day);
      final isSameDay = taskDate.isAtSameMomentAs(selectedDate);
      print('Task: ${task.title}, DueDate: ${task.dueDate}, Same Day: $isSameDay');
      return isSameDay;
    }).toList();
  }

  bool _hasTasksOnDay(DateTime day, List<Task> tasks) {
    return tasks.any((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final selectedDate = DateTime(day.year, day.month, day.day);
      return taskDate.isAtSameMomentAs(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectTagRepository = ProjectTagRepository(
      projectBox: Hive.box('projects'),
      tagBox: Hive.box('tags'),
    );

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final tasks = state.tasks ?? [];
        print('Total tasks in state: ${tasks.length}');
        final tasksForSelectedDay = _selectedDay != null ? _getTasksForDay(_selectedDay!, tasks) : [];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Lịch',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.grey),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    builder: (context) => AddTaskBottomSheet(
                      repository: projectTagRepository,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  print('Selected Day: $selectedDay, Focused Day: $focusedDay');
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
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
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  weekendStyle: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                calendarFormat: CalendarFormat.month,
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  print('Page changed to: $focusedDay');
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final hasTasks = _hasTasksOnDay(day, tasks);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: hasTasks ? Colors.black : Colors.grey,
                              fontWeight: hasTasks ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasTasks)
                          Positioned(
                            bottom: 5,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final hasTasks = _hasTasksOnDay(day, tasks);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFD50F0F),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (hasTasks)
                          Positioned(
                            bottom: 5,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final hasTasks = _hasTasksOnDay(day, tasks);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (hasTasks)
                          Positioned(
                            bottom: 5,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks cho ${(_selectedDay != null) ? "${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}" : "ngày được chọn"}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      state.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : tasksForSelectedDay.isEmpty
                          ? const Center(
                        child: Text(
                          'Không có task nào cho ngày này.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                          : Expanded(
                        child: ListView.builder(
                          itemCount: tasksForSelectedDay.length,
                          itemBuilder: (context, index) {
                            final task = tasksForSelectedDay[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailScreen(task: task),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: task.isCompleted ?? false,
                                          onChanged: (value) {
                                            if (value != null) {
                                              context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                                            }
                                          },
                                          shape: const CircleBorder(),
                                          activeColor: Colors.green,
                                          checkColor: Colors.white,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task.title ?? 'Task không có tiêu đề',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: task.isCompleted == true ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                              if (task.tags != null && task.tags!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4.0),
                                                  child: Wrap(
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: task.tags!.map<Widget>((tag) {
                                                      final colors = TagColors.getTagColors(tag);
                                                      return Chip(
                                                        label: Text(
                                                          '#$tag',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: colors['text'],
                                                          ),
                                                        ),
                                                        backgroundColor: colors['background'],
                                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                                        labelPadding: EdgeInsets.zero,
                                                      );
                                                    }).toList().cast<Widget>(),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 24),
                                          onPressed: () {
                                            // Logic bắt đầu Pomodoro cho task
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFFF5733),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                builder: (context) => AddTaskBottomSheet(
                  repository: projectTagRepository,
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}