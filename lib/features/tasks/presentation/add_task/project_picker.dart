import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/presentation/add_project_and_tags/add_project_screen.dart';
import '../../data/models/project_tag_repository.dart';

class ProjectPicker extends StatefulWidget {
  final String? initialProject;
  final ValueChanged<String?> onProjectSelected;

  const ProjectPicker({
    super.key,
    this.initialProject,
    required this.onProjectSelected,
  });

  @override
  State<ProjectPicker> createState() => _ProjectPickerState();
}

class _ProjectPickerState extends State<ProjectPicker> {
  late String? selectedProject;

  // Map để gán màu sắc cho từng project
  final Map<String, Color> projectColors = {
    'General': Colors.green,
    'Pomodoro App': Colors.red,
    'Fashion App': Colors.green,
    'AI Chatbot App': Colors.cyan,
    'Dating App': Colors.pink,
    'Quiz App': Colors.blue,
    'News App': Colors.teal,
    'Work Project': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    selectedProject = widget.initialProject;
  }

  void _updateProject(String? project) {
    setState(() {
      selectedProject = project;
    });
    widget.onProjectSelected(project);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Project',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.red),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProjectScreen(
                          repository: ProjectTagRepository(
                            projectBox: Hive.box('projects'),
                            tagBox: Hive.box('tags'),
                          ),
                          onProjectAdded: () {
                            // Không cần setState vì ValueListenableBuilder sẽ tự rebuild
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: Hive.box<Project>('projects').listenable(),
              builder: (context, Box<Project> box, _) {
                final availableProjects = box.values
                    .where((project) => !project.isArchived)
                    .map((project) => project.name)
                    .toList();
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: availableProjects.length,
                  itemBuilder: (context, index) {
                    final project = availableProjects[index];
                    final isSelected = selectedProject == project;
                    final projectColor = projectColors[project] ?? Colors.grey;
                    return ListTile(
                      leading: Icon(
                        Icons.work,
                        color: projectColor,
                        size: 24,
                      ),
                      title: Text(project),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.red) : null,
                      onTap: () {
                        _updateProject(project);
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}