import 'package:flutter/material.dart';
import '../../data/models/project_model.dart'; // Đảm bảo ProjectModel đã được cập nhật với iconCodePoint, iconFontFamily
import '../../data/models/project_tag_repository.dart';

// Hằng số cho màu sắc và kích thước (giữ nguyên các hằng số của bạn)
const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;
const double kIconPickerItemSize = 48.0; // Kích thước cho mỗi item trong icon picker (có thể điều chỉnh)
const double kButtonHeight = 48.0;
// Màu sắc có thể lấy từ Theme sau này, tạm thời giữ nguyên
const Color kBackgroundColor = Colors.white; // Sẽ được thay bằng Theme.of(context).scaffoldBackgroundColor
const Color kTextFieldFillColor = Color(0xFFE0E0E0);
const Color kBorderColor = Color(0xFFB0BEC5);
const Color kHintTextColor = Colors.grey;
const Color kTitleColor = Colors.black; // Sẽ được thay bằng Theme.of(context).textTheme.titleLarge.color
const Color kButtonColor = Colors.blue; // Sẽ được thay bằng Theme.of(context).colorScheme.primary
const Color kSuccessColor = Colors.green;
const Color kErrorColor = Colors.red;

class AddProjectScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  final VoidCallback? onProjectAdded;

  const AddProjectScreen({super.key, required this.repository, this.onProjectAdded});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  Color? _selectedColor;
  // NEW: Biến state để lưu IconData đã chọn
  IconData? _selectedIcon;

  final List<Color> colors = [
    Colors.red.shade400, Colors.pink.shade300, Colors.purple.shade300, Colors.deepPurple.shade300,
    Colors.indigo.shade300, Colors.blue.shade400, Colors.lightBlue.shade300, Colors.cyan.shade400,
    Colors.teal.shade400, Colors.green.shade400, Colors.lightGreen.shade400, Colors.lime.shade400,
    Colors.yellow.shade600, Colors.amber.shade400, Colors.orange.shade400, Colors.deepOrange.shade400,
    Colors.brown.shade400, Colors.grey.shade500, Colors.blueGrey.shade400,
  ];

  // NEW: Danh sách các IconData có thể chọn (có thể mở rộng thêm)
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color currentBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color currentTitleColor = Theme.of(context).textTheme.titleLarge?.color ?? (isDarkMode ? Colors.white : Colors.black);
    final Color currentTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? (isDarkMode ? Colors.white70 : Colors.black87);
    final Color currentHintTextColor = isDarkMode ? Colors.grey[500]! : kHintTextColor;
    final Color currentTextFieldFillColor = Theme.of(context).inputDecorationTheme.fillColor ?? (isDarkMode ? Colors.grey[800]! : const Color(0xFFE0E0E0));
    final Color currentBorderColor = Theme.of(context).dividerColor;
    final Color currentIconColor = Theme.of(context).iconTheme.color ?? (isDarkMode ? Colors.white70 : Colors.grey[600]!);


    return Scaffold(
      backgroundColor: currentBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: currentIconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Add New Project',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: currentTitleColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary), // Sử dụng màu primary cho nút check
            onPressed: _addProject,
          ),
        ],
      ),
      body: SingleChildScrollView( // NEW: Bọc Column bằng SingleChildScrollView để tránh overflow khi bàn phím hiện
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                style: TextStyle(color: currentTextColor),
                decoration: InputDecoration(
                  hintText: 'Project Name',
                  hintStyle: TextStyle(color: currentHintTextColor),
                  filled: true,
                  fillColor: currentTextFieldFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: currentBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: currentBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding),
              Text(
                'Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: currentTitleColor,
                ),
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
                    child: Container(
                      width: kCircleAvatarRadius * 1.8, // Điều chỉnh kích thước
                      height: kCircleAvatarRadius * 1.8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2.5)
                            : Border.all(color: currentBorderColor.withOpacity(0.3), width: 1),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: kCircleAvatarRadius * 0.9)
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: kDefaultPadding),

              // NEW: Phần chọn Icon
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: currentTitleColor,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, // Số icon trên một dòng
                  crossAxisSpacing: kDefaultPadding / 2,
                  mainAxisSpacing: kDefaultPadding / 2,
                  childAspectRatio: 1, // Giữ cho item vuông
                ),
                itemCount: selectableIcons.length,
                itemBuilder: (context, index) {
                  final iconData = selectableIcons[index];
                  final isSelected = _selectedIcon == iconData;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconData;
                      });
                    },
                    child: Container(
                      width: kIconPickerItemSize * 0.8, // Điều chỉnh kích thước
                      height: kIconPickerItemSize * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : currentBorderColor.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        color: isSelected ? Theme.of(context).colorScheme.primary : currentIconColor,
                        size: 22, // Kích thước icon bên trong
                      ),
                    ),
                  );
                },
              ),
              // --- Hết phần chọn Icon ---
              SizedBox(height: MediaQuery.of(context).size.height * 0.1), // Để tạo khoảng trống cho nút ở dưới

              // MODIFIED: Bỏ Spacer và nút Add Project ở dưới cùng
              // const Spacer(),
              // ElevatedButton( ... ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addProject() async {
    // MODIFIED: Kiểm tra thêm _selectedIcon
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên project!'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn màu cho project!'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }
    // NEW: Kiểm tra _selectedIcon
    if (_selectedIcon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn một icon cho project!'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    try {
      await widget.repository.addProject(
        Project(
          name: _nameController.text.trim(),
          color: _selectedColor!,
          // NEW: Truyền thông tin icon
          iconCodePoint: _selectedIcon!.codePoint,
          iconFontFamily: _selectedIcon!.fontFamily,
          // fontPackage thường là null cho MaterialIcons, ProjectModel đã xử lý default
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project added successfully!'),
          backgroundColor: kSuccessColor,
        ),
      );
      widget.onProjectAdded?.call();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add project: $e'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }
}