import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/themes/theme.dart';
import '../../data/models/project_tag_repository.dart';
import '../../data/models/tag_model.dart'; // Model đã được cập nhật

// Hằng số (giữ nguyên)
const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;
const double kButtonHeight = 48.0;
// ... (các hằng số màu khác nếu bạn vẫn dùng trực tiếp)

class AddTagScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  final VoidCallback? onTagAdded;

  const AddTagScreen({super.key, required this.repository, this.onTagAdded});

  @override
  State<AddTagScreen> createState() => _AddTagScreenState();
}

class _AddTagScreenState extends State<AddTagScreen> {
  final TextEditingController _nameController = TextEditingController();
  Color? _selectedTextColor; // Chỉ còn chọn màu chữ

  // Danh sách màu để người dùng chọn cho textColor
  final List<Color> textColorOptions = [
    Colors.blue.shade700, Colors.pink.shade700, Colors.green.shade700, Colors.orange.shade700,
    Colors.purple.shade700, Colors.yellow.shade900, Colors.cyan.shade700, Colors.red.shade700,
    Colors.teal.shade700, Colors.lime.shade900, Colors.brown.shade700, Colors.grey.shade800,
    Colors.black, // Thêm các màu cơ bản nếu muốn
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addTag() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập tên tag!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_selectedTextColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn màu chữ cho tag!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bạn cần đăng nhập để thêm tag!'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }
    final String userId = currentUser.uid;

    try {
      await widget.repository.addTag(
        Tag(
          name: _nameController.text.trim(),
          textColor: _selectedTextColor!,
          userId: userId,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tag added successfully!'),
          backgroundColor: Theme.of(context).extension<SuccessColor>()?.success ?? Colors.green,
        ),
      );
      widget.onTagAdded?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add tag: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ... (lấy các màu từ theme như trước) ...
    final Color currentElevatedButtonColor = theme.colorScheme.primary;


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Tag',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: theme.colorScheme.primary),
            onPressed: _addTag,
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
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                labelText: 'Tag Name',
                // ... (các thuộc tính decoration khác như cũ) ...
                hintStyle: TextStyle(color: theme.hintColor),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? (theme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade800),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            Text(
              'Tag Color', // Chỉ còn chọn 1 màu (cho chữ)
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: kDefaultPadding / 2,
                mainAxisSpacing: kDefaultPadding / 2,
                childAspectRatio: 1,
              ),
              itemCount: textColorOptions.length,
              itemBuilder: (context, index) {
                final color = textColorOptions[index];
                final isSelected = _selectedTextColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTextColor = color;
                    });
                  },
                  child: Container(
                    width: kCircleAvatarRadius * 1.8,
                    height: kCircleAvatarRadius * 1.8,
                    decoration: BoxDecoration(
                      color: color, // Hiển thị màu sẽ được chọn
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                          : Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: kCircleAvatarRadius * 0.9)
                        : null,
                  ),
                );
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentElevatedButtonColor,
                minimumSize: const Size(double.infinity, kButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Tag',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }
}