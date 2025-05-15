import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/adapters.dart';
import 'dart:async';
import '../../data/models/project_tag_repository.dart';
import '../../data/models/tag_model.dart';

class ArchivedTagsScreen extends StatefulWidget {
  final ProjectTagRepository repository;

  const ArchivedTagsScreen({super.key, required this.repository});

  @override
  State<ArchivedTagsScreen> createState() => _ArchivedTagsScreenState();
}

class _ArchivedTagsScreenState extends State<ArchivedTagsScreen> {
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
    return ValueListenableBuilder(
      valueListenable: widget.repository.tagBox.listenable(),
      builder: (context, Box<Tag> box, _) {
        final archivedTags = widget.repository.getArchivedTags();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'Archived Tags',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: archivedTags.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có tag nào trong thùng rác.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : AnimationLimiter(
              child: ListView.builder(
                itemCount: archivedTags.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: FadeInAnimation(
                      child: Padding(
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
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: archivedTags[index].textColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    archivedTags[index].name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.restore, color: Colors.green, size: 24),
                                  onPressed: () {
                                    _debounceAction(() async {
                                      try {
                                        await widget.repository.restoreTag(index);
                                        // SỬA: Không cần setState vì ValueListenableBuilder sẽ tự làm mới UI
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Tag đã được khôi phục!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi khi khôi phục: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                                  onPressed: () {
                                    _debounceAction(() {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          bool isLoading = false;
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                title: const Text('Xóa vĩnh viễn'),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text('Bạn có chắc muốn xóa vĩnh viễn tag "${archivedTags[index].name}" không?'),
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
                                                    child: const Text('Hủy'),
                                                  ),
                                                  TextButton(
                                                    onPressed: isLoading
                                                        ? null
                                                        : () async {
                                                      setState(() {
                                                        isLoading = true;
                                                      });
                                                      try {
                                                        await widget.repository.deleteTag(index, context);
                                                        Navigator.pop(dialogContext);
                                                        // SỬA: Không cần setState vì ValueListenableBuilder sẽ tự làm mới UI
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Tag đã được xóa vĩnh viễn!'),
                                                            backgroundColor: Colors.red,
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        setState(() {
                                                          isLoading = false;
                                                        });
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('Lỗi khi xóa: $e'),
                                                            backgroundColor: Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: const Text(
                                                      'Xóa vĩnh viễn',
                                                      style: TextStyle(color: Colors.red),
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