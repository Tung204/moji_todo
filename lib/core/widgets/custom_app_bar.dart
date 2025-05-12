import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationPressed;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    this.onNotificationPressed,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.grey),
        onPressed: () {
          Navigator.pop(context); // Quay về màn hình trước đó
        },
      )
          : null,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF8F0404), Color(0xFFFF7379)],
        ).createShader(bounds),
        child: const Text(
          'DNTU Focus',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.grey),
          onPressed: onNotificationPressed ?? () {},
        ),
        if (!showBackButton) // Chỉ hiển thị icon Settings nếu không có nút back
          _SettingsIconButton(),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SettingsIconButton extends StatefulWidget {
  @override
  _SettingsIconButtonState createState() => _SettingsIconButtonState();
}

class _SettingsIconButtonState extends State<_SettingsIconButton> {
  Color _iconColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.settings,
        color: _iconColor,
      ),
      onPressed: () {
        setState(() {
          _iconColor = Colors.blue; // Đổi màu khi nhấn
        });
        Navigator.pushNamed(context, AppRoutes.settings);
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _iconColor = Colors.grey; // Quay lại màu gốc sau 300ms
          });
        });
      },
    );
  }
}