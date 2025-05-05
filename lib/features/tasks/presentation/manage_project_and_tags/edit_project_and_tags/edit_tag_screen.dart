import 'package:flutter/material.dart';
import '../../../data/models/project_tag_repository.dart';
import '../../../data/models/tag_model.dart';

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

class EditTagScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  final Tag tag;
  final int index;
  final VoidCallback? onTagUpdated;

  const EditTagScreen({
    super.key,
    required this.repository,
    required this.tag,
    required this.index,
    this.onTagUpdated,
  });

  @override
  State<EditTagScreen> createState() => _EditTagScreenState();
}

class _EditTagScreenState extends State<EditTagScreen> {
  late TextEditingController _nameController;
  Color? _selectedColor;

  final List<Map<String, Color>> colors = [
    {'background': Colors.blue, 'text': Colors.blue},
    {'background': Colors.pink, 'text': Colors.pink},
    {'background': Colors.green, 'text': Colors.green},
    {'background': Colors.orange, 'text': Colors.orange},
    {'background': Colors.purple, 'text': Colors.purple},
    {'background': Colors.yellow, 'text': Colors.yellow},
    {'background': Colors.cyan, 'text': Colors.cyan},
    {'background': Colors.red, 'text': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag.name);
    _selectedColor = widget.tag.textColor;
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
          'Edit Tag',
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
            onPressed: _updateTag,
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
                hintText: 'Tag Name',
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
                final color = colors[index]['text']!;
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
              onPressed: _updateTag,
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

  Future<void> _updateTag() async {
    if (_nameController.text.isNotEmpty && _selectedColor != null) {
      try {
        await widget.repository.updateTag(
          widget.index,
          Tag(
            name: _nameController.text,
            backgroundColor: colors.firstWhere((c) => c['text'] == _selectedColor)['background']!,
            textColor: _selectedColor!,
            isArchived: widget.tag.isArchived,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tag updated successfully!'),
            backgroundColor: kSuccessColor,
          ),
        );
        widget.onTagUpdated?.call();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update tag: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên tag và chọn màu!'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }
}