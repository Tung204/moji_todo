import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_tag_repository.dart';
import '../../data/models/tag_model.dart';
import '../add_project_and_tags/add_project_screen.dart';
import '../add_project_and_tags/add_tag_screen.dart';
import 'edit_project_and_tags/edit_project_screen.dart';
import 'edit_project_and_tags/edit_tag_screen.dart';
import 'archived_projects_screen.dart';
import 'archived_tags_screen.dart';

class ManageProjectsTagsScreen extends StatefulWidget {
  final ProjectTagRepository repository;

  const ManageProjectsTagsScreen({super.key, required this.repository});

  @override
  State<ManageProjectsTagsScreen> createState() => _ManageProjectsTagsScreenState();
}

class _ManageProjectsTagsScreenState extends State<ManageProjectsTagsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Manage Projects and Tags',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Projects'),
            Tab(text: 'Tags'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Projects
          ValueListenableBuilder( // SỬA: Thêm ValueListenableBuilder để tự động làm mới
            valueListenable: widget.repository.projectBox.listenable(),
            builder: (context, Box<Project> box, _) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: widget.repository.getProjects().length + 1,
                      itemBuilder: (context, index) {
                        if (index == widget.repository.getProjects().length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                title: const Text(
                                  'Archived Projects',
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArchivedProjectsScreen(repository: widget.repository),
                                    ),
                                  ); // SỬA: Không cần then setState vì ValueListenableBuilder sẽ tự làm mới
                                },
                              ),
                            ),
                          );
                        }

                        final project = widget.repository.getProjects()[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.work,
                                color: project.color,
                                size: 40,
                              ),
                              title: Text(
                                project.name,
                                style: const TextStyle(fontSize: 16, color: Colors.black),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (value) {
                                  if (value == 'Edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProjectScreen(
                                          repository: widget.repository,
                                          project: project,
                                          index: index,
                                          onProjectUpdated: () {}, // SỬA: Không cần setState
                                        ),
                                      ),
                                    );
                                  } else if (value == 'Lưu trữ') {
                                    widget.repository.archiveProject(index);
                                    // SỬA: Không cần setState vì ValueListenableBuilder sẽ tự làm mới
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'Edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Lưu trữ',
                                    child: Text('Lưu trữ'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddProjectScreen(
                              repository: widget.repository,
                              onProjectAdded: () {}, // SỬA: Không cần setState
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Add New Project',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Tab Tags
          ValueListenableBuilder( // SỬA: Thêm ValueListenableBuilder để tự động làm mới
            valueListenable: widget.repository.tagBox.listenable(),
            builder: (context, Box<Tag> box, _) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: widget.repository.getTags().length + 1,
                      itemBuilder: (context, index) {
                        if (index == widget.repository.getTags().length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                title: const Text(
                                  'Archived Tags',
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArchivedTagsScreen(repository: widget.repository),
                                    ),
                                  ); // SỬA: Không cần then setState
                                },
                              ),
                            ),
                          );
                        }

                        final tag = widget.repository.getTags()[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.label,
                                color: tag.textColor,
                                size: 40,
                              ),
                              title: Text(
                                tag.name,
                                style: const TextStyle(fontSize: 16, color: Colors.black),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (value) {
                                  if (value == 'Edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditTagScreen(
                                          repository: widget.repository,
                                          tag: tag,
                                          index: index,
                                          onTagUpdated: () {}, // SỬA: Không cần setState
                                        ),
                                      ),
                                    );
                                  } else if (value == 'Lưu trữ') {
                                    widget.repository.archiveTag(index);
                                    // SỬA: Không cần setState
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'Edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Lưu trữ',
                                    child: Text('Lưu trữ'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTagScreen(
                              repository: widget.repository,
                              onTagAdded: () {}, // SỬA: Không cần setState
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Add New Tag',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}