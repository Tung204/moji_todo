import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../core/themes/theme.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/project_tag_repository.dart';

const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;
const double kIconPickerItemSize = 48.0; // Thêm lại nếu đã xóa

class EditProjectScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  final dynamic projectKey;
  final VoidCallback? onProjectUpdated;

  const EditProjectScreen({
    super.key,
    required this.repository,
    required this.projectKey,
    this.onProjectUpdated,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _nameController;
  Color? _selectedColor;
  IconData? _selectedIconData; // Đổi tên từ _newSelectedIcon để nhất quán
  Project? _projectToEdit;
  bool _isLoading = true;

  final List<Color> _selectableColors = [
    Colors.red.shade400, Colors.pink.shade300, Colors.purple.shade300, Colors.deepPurple.shade300,
    Colors.indigo.shade300, Colors.blue.shade400, Colors.lightBlue.shade300, Colors.cyan.shade400,
    Colors.teal.shade400, Colors.green.shade400, Colors.lightGreen.shade400, Colors.lime.shade400,
    Colors.yellow.shade600, Colors.amber.shade400, Colors.orange.shade400, Colors.deepOrange.shade400,
    Colors.brown.shade400, Colors.grey.shade500, Colors.blueGrey.shade400,
  ];

  // Danh sách icon tương tự AddProjectScreen
  final List<IconData> selectableIcons = [
    Icons.work_outline_rounded, Icons.school_outlined, Icons.home_outlined, Icons.lightbulb_outline_rounded,
    Icons.book_outlined, Icons.fitness_center_outlined, Icons.code_rounded, Icons.palette_outlined,
    Icons.shopping_bag_outlined, Icons.flight_takeoff_rounded, Icons.account_balance_wallet_outlined, Icons.music_note_outlined,
    Icons.movie_outlined, Icons.restaurant_outlined, Icons.spa_outlined, Icons.pets_rounded,
    Icons.build_outlined, Icons.brush_outlined, Icons.camera_alt_outlined, Icons.star_border_rounded,
    Icons.category_outlined, Icons.folder_outlined, Icons.attach_money_outlined, Icons.bar_chart_outlined,
    Icons.settings_outlined, Icons.group_outlined, Icons.public_outlined, Icons.eco_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadProjectData();
  }

  void _loadProjectData() {
    final project = widget.repository.projectBox.get(widget.projectKey);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (project != null) {
      if (currentUser != null && project.userId == currentUser.uid) {
        setState(() {
          _projectToEdit = project;
          _nameController.text = _projectToEdit!.name;
          _selectedColor = _projectToEdit!.color;
          _selectedIconData = _projectToEdit!.icon; // Gán icon hiện tại
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorAndPop('Bạn không có quyền chỉnh sửa project này hoặc project không tồn tại.');
      }
    } else {
      setState(() => _isLoading = false);
      _showErrorAndPop('Không tìm thấy project để chỉnh sửa.');
    }
  }

  void _showErrorAndPop(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
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

  Future<void> _updateProject() async {
    if (_projectToEdit == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _projectToEdit!.userId != currentUser.uid) {
      _showErrorAndPop('Không thể cập nhật project. Vui lòng thử lại.');
      return;
    }

    final String newName = _nameController.text.trim();
    final Color? newColor = _selectedColor;
    final IconData? newIcon = _selectedIconData; // Icon mới đã được chọn từ UI

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng nhập tên project!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (newColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng chọn màu cho project!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (newIcon == null) { // Kiểm tra nếu icon là bắt buộc
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng chọn một icon cho project!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    final updatedProject = _projectToEdit!.copyWith(
      name: newName,
      color: newColor,
      iconCodePoint: newIcon.codePoint, // Cập nhật icon
      iconFontFamily: newIcon.fontFamily, // Cập nhật icon
      iconFontPackage: newIcon.fontPackage, // Cập nhật icon
      userId: _projectToEdit!.userId,
      isArchived: _projectToEdit!.isArchived,
    );

    try {
      await widget.repository.updateProject(widget.projectKey, updatedProject);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Project updated successfully!'), backgroundColor: Theme.of(context).extension<SuccessColor>()?.success ?? Colors.green));
      widget.onProjectUpdated?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update project: $e'), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ... (lấy các màu từ theme như cũ) ...
    final Color currentIconColor = theme.iconTheme.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey[600]!);


    if (_isLoading) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, appBar: AppBar(title: Text('Edit Project', style: theme.appBarTheme.titleTextStyle), backgroundColor: Colors.transparent, elevation: 0), body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }
    if (_projectToEdit == null) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, appBar: AppBar(title: Text('Edit Project', style: theme.appBarTheme.titleTextStyle), backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color), onPressed: () => Navigator.of(context).pop())), body: const Center(child: Text('Không thể tải dữ liệu project.')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color), onPressed: () => Navigator.pop(context)),
        title: Text('Edit Project', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.check, color: theme.colorScheme.primary), onPressed: _updateProject)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                labelText: 'Project Name',
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
              'Color',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder( // GridView chọn màu
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: kDefaultPadding / 2, mainAxisSpacing: kDefaultPadding / 2, childAspectRatio: 1),
              itemCount: _selectableColors.length,
              itemBuilder: (context, index) {
                final color = _selectableColors[index];
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 2.5) : Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1),
                    ),
                    child: isSelected ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: kCircleAvatarRadius * 0.9) : null,
                  ),
                );
              },
            ),
            const SizedBox(height: kDefaultPadding),

            // PHẦN CHỌN ICON MỚI (Tương tự AddProjectScreen)
            Text(
              'Icon',
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
              itemCount: selectableIcons.length,
              itemBuilder: (context, index) {
                final iconData = selectableIcons[index];
                final isSelected = _selectedIconData == iconData; // So sánh với _selectedIconData
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIconData = iconData; // Cập nhật icon đã chọn
                    });
                  },
                  child: Container(
                    width: kIconPickerItemSize * 0.8,
                    height: kIconPickerItemSize * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? theme.colorScheme.primary : currentIconColor,
                      size: 22,
                    ),
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