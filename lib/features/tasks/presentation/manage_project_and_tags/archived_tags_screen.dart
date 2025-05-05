import 'package:flutter/material.dart';
import '../../data/models/project_tag_repository.dart';

class ArchivedTagsScreen extends StatefulWidget {
  final ProjectTagRepository repository;

  const ArchivedTagsScreen({super.key, required this.repository});

  @override
  State<ArchivedTagsScreen> createState() => _ArchivedTagsScreenState();
}

class _ArchivedTagsScreenState extends State<ArchivedTagsScreen> {
  @override
  Widget build(BuildContext context) {
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
            ? const Center(child: Text('Không có tag nào trong thùng rác.'))
            : ListView.builder(
          itemCount: archivedTags.length,
          itemBuilder: (context, index) {
            final tag = archivedTags[index];
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
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: tag.textColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tag.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green, size: 24),
                        onPressed: () async {
                          try {
                            await widget.repository.restoreTag(index);
                            setState(() {});
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
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                        onPressed: () async {
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
                                        Text('Bạn có chắc muốn xóa vĩnh viễn tag "${tag.name}" không?'),
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
                                            await widget.repository.deleteTag(index);
                                            Navigator.pop(dialogContext);
                                            setState(() {});
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
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}