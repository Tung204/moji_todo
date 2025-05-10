import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/home/presentation/widgets/task_card.dart';
import '../../../routes/app_routes.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/domain/task_cubit.dart';

class TaskBottomSheet {
  static void show(
      BuildContext context,
      Function(String, int) onPlay,
      Function(Task) onComplete,
      ) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Task',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Color(0xFFFF5733)),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.tasks);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search task...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        autofocus: true,
                        onChanged: (value) {
                          setBottomSheetState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<TaskCubit, TaskState>(
                        builder: (context, state) {
                          final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
                          final todayTasks = categorizedTasks['Today'] ?? [];
                          final filteredTasks = searchQuery.isEmpty
                              ? todayTasks
                              : todayTasks
                              .where((task) => task.title?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Today Tasks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (filteredTasks.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(child: Text('No tasks found.')),
                                )
                              else
                                SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: filteredTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = filteredTasks[index];
                                      return TaskCard(
                                        task: task,
                                        onPlay: () {
                                          onPlay(
                                            task.title ?? 'Untitled Task',
                                            task.estimatedPomodoros ?? 4,
                                          );
                                          Navigator.pop(context);
                                        },
                                        onComplete: () {
                                          onComplete(task);
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}