import 'package:flutter/material.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/project_tag_repository.dart';

// Hằng số cho màu sắc và kích thước
const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;
const double kButtonHeight = 48.0;
const Color kBackgroundColor = Colors.white;
const Color kTextFieldFillColor = Color(0xFFE0E0E0);
const Color kBorderColor = Color(0xFFB0BEC5);
const Color kHintTextColor = Colors.grey;
const Color kTitleColor = Colors.black;
const Color kButtonColor = Colors.blue;
const Color kSuccessColor = Colors.green;
const Color kErrorColor = Colors.red;

class EditProjectScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  final Project project;
  final int index;
  final VoidCallback? onProjectUpdated;

  const EditProjectScreen({
    super.key,
    required this.repository,
    required this.project,
    required this.index,
    this.onProjectUpdated,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _nameController;
  Color? _selectedColor;

  final List<Color> colors = [
    Colors.red,
    Colors.pink[200]!,
    Colors.green[200]!,
    Colors.blue[200]!,
    Colors.purple[200]!,
    Colors.orange[200]!,
    Colors.cyan[200]!,
    Colors.yellow[200]!,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _selectedColor = widget.project.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kHintTextColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit Project',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kTitleColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: kSuccessColor),
            onPressed: _updateProject,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Project Name',
                hintStyle: const TextStyle(color: kHintTextColor),
                filled: true,
                fillColor: kTextFieldFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorderColor),
                ),
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTitleColor,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: kDefaultPadding,
                mainAxisSpacing: kDefaultPadding,
                childAspectRatio: 1,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: CircleAvatar(
                    radius: kCircleAvatarRadius,
                    backgroundColor: color,
                    child: isSelected
                        ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    )
                        : null,
                  ),
                );
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _updateProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonColor,
                minimumSize: const Size(double.infinity, kButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProject() async {
    if (_nameController.text.isNotEmpty && _selectedColor != null) {
      try {
        await widget.repository.updateProject(
          widget.index,
          Project(
            name: _nameController.text,
            color: _selectedColor!,
            isArchived: widget.project.isArchived,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project updated successfully!'),
            backgroundColor: kSuccessColor,
          ),
        );
        widget.onProjectUpdated?.call();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update project: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên project và chọn màu!'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }
}