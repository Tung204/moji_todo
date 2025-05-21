import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../core/themes/theme.dart';
import '../../../data/models/project_tag_repository.dart';
import '../../../data/models/tag_model.dart'; // Model đã được cập nhật

const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;

class EditTagScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  final dynamic tagKey;
  final VoidCallback? onTagUpdated;

  const EditTagScreen({
    super.key,
    required this.repository,
    required this.tagKey,
    this.onTagUpdated,
  });

  @override
  State<EditTagScreen> createState() => _EditTagScreenState();
}

class _EditTagScreenState extends State<EditTagScreen> {
  late TextEditingController _nameController;
  Color? _selectedTextColor;
  Tag? _tagToEdit;
  bool _isLoading = true;

  final List<Color> _selectableTextColors = [ // Giống AddTagScreen
    Colors.blue.shade700, Colors.pink.shade700, Colors.green.shade700, Colors.orange.shade700,
    Colors.purple.shade700, Colors.yellow.shade900, Colors.cyan.shade700, Colors.red.shade700,
    Colors.teal.shade700, Colors.lime.shade900, Colors.brown.shade700, Colors.grey.shade800,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadTagData();
  }

  void _loadTagData() {
    final tag = widget.repository.tagBox.get(widget.tagKey);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (tag != null) {
      if (currentUser != null && tag.userId == currentUser.uid) {
        setState(() {
          _tagToEdit = tag;
          _nameController.text = _tagToEdit!.name;
          _selectedTextColor = _tagToEdit!.textColor;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorAndPop('Bạn không có quyền chỉnh sửa tag này hoặc tag không tồn tại.');
      }
    } else {
      setState(() => _isLoading = false);
      _showErrorAndPop('Không tìm thấy tag để chỉnh sửa.');
    }
  }

  void _showErrorAndPop(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateTag() async {
    if (_tagToEdit == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _tagToEdit!.userId != currentUser.uid) {
      _showErrorAndPop('Không thể cập nhật tag. Vui lòng thử lại.');
      return;
    }

    final String newName = _nameController.text.trim();
    final Color? newTextColor = _selectedTextColor;

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng nhập tên tag!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (newTextColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng chọn màu chữ cho tag!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    final updatedTag = _tagToEdit!.copyWith(
      name: newName,
      textColor: newTextColor,
      // Không có backgroundColor để giữ lại nữa
      userId: _tagToEdit!.userId,
      isArchived: _tagToEdit!.isArchived,
    );

    try {
      await widget.repository.updateTag(widget.tagKey, updatedTag);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Tag updated successfully!'), backgroundColor: Theme.of(context).extension<SuccessColor>()?.success ?? Colors.green,));
      widget.onTagUpdated?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update tag: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, appBar: AppBar(title: Text('Edit Tag', style: theme.appBarTheme.titleTextStyle), backgroundColor: Colors.transparent, elevation: 0), body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }
    if (_tagToEdit == null) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, appBar: AppBar(title: Text('Edit Tag', style: theme.appBarTheme.titleTextStyle), backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color), onPressed: () => Navigator.of(context).pop())), body: const Center(child: Text('Không thể tải dữ liệu tag.')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color), onPressed: () => Navigator.pop(context)),
        title: Text('Edit Tag', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.check, color: theme.colorScheme.primary), onPressed: _updateTag)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Chip( // Chip preview
                label: Text(
                  _nameController.text.isNotEmpty ? _nameController.text : "Tag Preview",
                  style: TextStyle(color: _selectedTextColor ?? _tagToEdit!.textColor),
                ),
                // backgroundColor của chip có thể là màu nhẹ dựa trên theme hoặc màu cố định
                backgroundColor: theme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            TextField(
              controller: _nameController,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                labelText: 'Tag Name',
                // ... (các thuộc tính decoration khác như cũ) ...
                labelStyle: TextStyle(color: theme.hintColor),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? (theme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade800),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            Text(
              'Tag Color', // Chỉ còn chọn màu chữ
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
              itemCount: _selectableTextColors.length,
              itemBuilder: (context, index) {
                final color = _selectableTextColors[index];
                final isSelected = _selectedTextColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTextColor = color),
                  child: Container(
                    width: kCircleAvatarRadius * 1.8,
                    height: kCircleAvatarRadius * 1.8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                          : Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1),
                    ),
                    child: isSelected ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: kCircleAvatarRadius * 0.9) : null,
                  ),
                );
              },
            ),
            const SizedBox(height: kDefaultPadding * 2),
          ],
        ),
      ),
    );
  }
}