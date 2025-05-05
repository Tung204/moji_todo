import 'package:flutter/material.dart';
import '../../data/models/project_tag_repository.dart';
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
          Column(
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
                              ).then((_) => setState(() {}));
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
                            Icons.work, // Biểu tượng balo
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
                                      onProjectUpdated: () {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              } else if (value == 'Lưu trữ') {
                                widget.repository.archiveProject(index);
                                setState(() {});
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
                          onProjectAdded: () {
                            setState(() {});
                          },
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
          ),
          // Tab Tags
          Column(
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
                              ).then((_) => setState(() {}));
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
                            Icons.label, // Biểu tượng thẻ
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
                                      onTagUpdated: () {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              } else if (value == 'Lưu trữ') {
                                widget.repository.archiveTag(index);
                                setState(() {});
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
                          onTagAdded: () {
                            setState(() {});
                          },
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
          ),
        ],
      ),
    );
  }
}