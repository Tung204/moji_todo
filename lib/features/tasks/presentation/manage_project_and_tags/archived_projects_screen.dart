import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/adapters.dart';
import 'dart:async';
import '../../../../core/themes/theme.dart'; // Đảm bảo import này đúng
import '../../data/models/project_model.dart';
import '../../data/models/project_tag_repository.dart';

class ArchivedProjectsScreen extends StatefulWidget {
  final ProjectTagRepository repository;

  const ArchivedProjectsScreen({super.key, required this.repository});

  @override
  State<ArchivedProjectsScreen> createState() => _ArchivedProjectsScreenState();
}

class _ArchivedProjectsScreenState extends State<ArchivedProjectsScreen> {
  Timer? _debounce;

  void _debounceAction(VoidCallback action) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), action);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color successColorWithTheme = theme.extension<SuccessColor>()?.success ?? Colors.green;

    return ValueListenableBuilder(
      valueListenable: widget.repository.projectBox.listenable(),
      builder: (context, Box<Project> box, _) {
        // getArchivedProjects đã được sửa để lọc theo userId trong repository
        final archivedProjects = widget.repository.getArchivedProjects();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Archived Projects',
              style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 24) ??
                  TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: archivedProjects.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline,
                      size: 64, color: theme.iconTheme.color?.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Không có project nào trong thùng rác.',
                    style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                ],
              ),
            )
                : AnimationLimiter(
              child: ListView.builder(
                itemCount: archivedProjects.length,
                itemBuilder: (context, index) {
                  final project = archivedProjects[index];
                  final IconData projectIconData = project.icon ?? Icons.folder_zip_outlined;
                  final projectKey = project.key; // Lấy key của project

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  projectIconData,
                                  color: project.color,
                                  size: 36,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    project.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.restore, color: successColorWithTheme, size: 24),
                                  onPressed: () {
                                    _debounceAction(() async {
                                      try {
                                        // SỬA: Gọi restoreProjectByKey và truyền projectKey
                                        await widget.repository.restoreProjectByKey(projectKey);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Project đã được khôi phục!'),
                                            backgroundColor: successColorWithTheme,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi khi khôi phục: $e'),
                                            backgroundColor: theme.colorScheme.error,
                                          ),
                                        );
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_forever, color: theme.colorScheme.error, size: 24),
                                  onPressed: () {
                                    _debounceAction(() {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          bool isLoading = false;
                                          return StatefulBuilder(
                                            builder: (stfContext, stfSetState) {
                                              return AlertDialog(
                                                backgroundColor: theme.cardTheme.color ?? theme.dialogBackgroundColor,
                                                title: Text('Xóa vĩnh viễn', style: theme.textTheme.titleLarge),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Bạn có chắc muốn xóa vĩnh viễn project "${project.name}" không?',
                                                      style: theme.textTheme.bodyMedium,
                                                    ),
                                                    if (isLoading) ...[
                                                      const SizedBox(height: 16),
                                                      CircularProgressIndicator(color: theme.colorScheme.primary),
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
                                                    child: Text('Hủy', style: TextStyle(color: theme.colorScheme.primary)),
                                                  ),
                                                  TextButton(
                                                    onPressed: isLoading
                                                        ? null
                                                        : () async {
                                                      stfSetState(() {
                                                        isLoading = true;
                                                      });
                                                      try {
                                                        // SỬA: Gọi deleteProjectByKey và truyền projectKey
                                                        await widget.repository.deleteProjectByKey(projectKey, context);
                                                        if (!mounted) return;
                                                        Navigator.pop(dialogContext);
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: const Text('Project đã được xóa vĩnh viễn!'),
                                                              backgroundColor: theme.colorScheme.error,
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        stfSetState(() {
                                                          isLoading = false;
                                                        });
                                                        if (!mounted) return;
                                                        // Không pop dialog ở đây để người dùng biết lỗi
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Lỗi khi xóa: $e'),
                                                              backgroundColor: theme.colorScheme.error,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: Text(
                                                      'Xóa vĩnh viễn',
                                                      style: TextStyle(color: theme.colorScheme.error),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}