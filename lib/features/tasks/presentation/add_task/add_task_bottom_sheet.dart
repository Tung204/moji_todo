import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_tag_repository.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../domain/task_cubit.dart';
import 'due_date_picker.dart';
import 'priority_picker.dart';
import 'tags_picker.dart';
import 'project_picker.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final ProjectTagRepository repository;

  const AddTaskBottomSheet({super.key, required this.repository});

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
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
                      icon: Icon(
                        Icons.wb_sunny,
                        color: _dueDate != null ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => DueDatePicker(
                            initialDate: _dueDate,
                            onDateSelected: (date) {
                              setState(() {
                                _dueDate = date;
                              });
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.flag,
                        color: _priority != null ? Colors.orange : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => PriorityPicker(
                            initialPriority: _priority,
                            onPrioritySelected: (priority) {
                              setState(() {
                                _priority = priority;
                              });
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.local_offer,
                        color: _tags.isNotEmpty ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => TagsPicker(
                            initialTags: _tags,
                            repository: widget.repository,
                            onTagsSelected: (tags) {
                              setState(() {
                                _tags = tags;
                              });
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.work,
                        color: _project != null ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => ProjectPicker(
                            initialProject: _project,
                            repository: widget.repository,
                            onProjectSelected: (project) {
                              setState(() {
                                _project = project;
                              });
                            },
                          ),
                        );
                      },
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}