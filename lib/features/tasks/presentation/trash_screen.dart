import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/task_cubit.dart';
import 'task_detail_screen.dart';
import '../../../core/widgets/custom_app_bar.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
        final trashTasks = categorizedTasks['Trash'] ?? [];
        final filteredTasks = _searchQuery.isEmpty
            ? trashTasks
            : trashTasks.where((task) => task.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                if (state.isSelectionMode) {
                  context.read<TaskCubit>().toggleSelectionMode();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: state.isSelectionMode
                ? Text(
              '${state.selectedTasks.length} đã chọn',
              style: Theme.of(context).textTheme.titleLarge,
            )
                : Text(
              'Thùng rác',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            actions: state.isSelectionMode
                ? [
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                onPressed: () async {
                  try {
                    await context.read<TaskCubit>().restoreSelectedTasks();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã khôi phục các task!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Lỗi khi khôi phục: $e',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      bool isLoading = false;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: Text(
                              'Xóa vĩnh viễn',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Bạn có chắc muốn xóa vĩnh viễn ${state.selectedTasks.length} task không?',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (isLoading) ...[
                                  const SizedBox(height: 16),
                                  const CircularProgressIndicator(),
                                ],
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(
                                  'Hủy',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  try {
                                    await context.read<TaskCubit>().deleteSelectedTasks();
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã xóa vĩnh viễn các task!',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Lỗi khi xóa: $e',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  'Xóa vĩnh viễn',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ]
                : [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                onSelected: (value) {
                  if (value == 'Sort by Title') {
                    context.read<TaskCubit>().sortTasksInTrash('title');
                  } else if (value == 'Sort by Deleted Date') {
                    context.read<TaskCubit>().sortTasksInTrash('deletedDate');
                  } else if (value == 'Select Multiple') {
                    context.read<TaskCubit>().toggleSelectionMode();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Sort by Title', child: Text('Sắp xếp theo tiêu đề')),
                  const PopupMenuItem(value: 'Sort by Deleted Date', child: Text('Sắp xếp theo ngày xóa')),
                  const PopupMenuItem(value: 'Select Multiple', child: Text('Chọn nhiều task')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm trong thùng rác...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    context.read<TaskCubit>().searchTasksInTrash(value);
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredTasks.isEmpty
                      ? Center(
                    child: Text(
                      'Thùng rác trống.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      if (task == null) {
                        return const SizedBox.shrink();
                      }
                      final isSelected = state.isSelectionMode && state.selectedTasks.contains(task);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (state.isSelectionMode)
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      context.read<TaskCubit>().toggleTaskSelection(task);
                                    },
                                    activeColor: Colors.green,
                                    checkColor: Theme.of(context).colorScheme.onSurface,
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title ?? 'Task không có tiêu đề',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      if (task.tags != null && task.tags!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: task.tags!
                                                .map((tag) => Chip(
                                              label: Text(
                                                '#$tag',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontSize: 10,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              backgroundColor: Theme.of(context).colorScheme.surface,
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              labelPadding: EdgeInsets.zero,
                                            ))
                                                .toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!state.isSelectionMode)
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                                    onSelected: (value) async {
                                      if (value == 'Restore') {
                                        try {
                                          await context.read<TaskCubit>().restoreTask(task);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Task đã được khôi phục!',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Lỗi khi khôi phục: $e',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } else if (value == 'Delete Permanently') {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) {
                                            bool isLoading = false;
                                            return StatefulBuilder(
                                              builder: (context, setState) {
                                                return AlertDialog(
                                                  title: Text(
                                                    'Xóa vĩnh viễn',
                                                    style: Theme.of(context).textTheme.titleLarge,
                                                  ),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Bạn có chắc muốn xóa vĩnh viễn task "${task.title}" không?',
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                      ),
                                                      if (isLoading) ...[
                                                        const SizedBox(height: 16),
                                                        const CircularProgressIndicator(),
                                                      ],
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: isLoading
                                                          ? null
                                                          : () {
                                                        Navigator.pop(dialogContext);
                                                      },
                                                      child: Text(
                                                        'Hủy',
                                                        style: Theme.of(context).textTheme.bodyMedium,
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: isLoading
                                                          ? null
                                                          : () async {
                                                        setState(() {
                                                          isLoading = true;
                                                        });
                                                        try {
                                                          await context.read<TaskCubit>().deleteTask(task);
                                                          Navigator.pop(dialogContext);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Task đã được xóa vĩnh viễn!',
                                                                style: Theme.of(context).textTheme.bodyMedium,
                                                              ),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        } catch (e) {
                                                          setState(() {
                                                            isLoading = false;
                                                          });
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Lỗi khi xóa: $e',
                                                                style: Theme.of(context).textTheme.bodyMedium,
                                                              ),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: Text(
                                                        'Xóa vĩnh viễn',
                                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'Restore', child: Text('Khôi phục')),
                                      const PopupMenuItem(value: 'Delete Permanently', child: Text('Xóa vĩnh viễn')),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}