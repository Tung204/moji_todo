import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../routes/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/navigation/navigation_manager.dart';
import '../domain/settings_cubit.dart';
import '../domain/settings_state.dart';
import '../../../core/services/backup_service.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';
import 'package:hive/hive.dart';
import 'backup_sync_screen.dart';
import 'package:moji_todo/main.dart'; // Import AppData

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy taskBox, syncInfoBox, projectBox và tagBox từ AppData
    final appData = AppData.of(context);
    final backupService = BackupService(
      appData.taskBox,
      appData.syncInfoBox,
      appData.projectBox,
      appData.tagBox,
    );

    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(showBackButton: true),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              _buildSettingItem(
                context,
                icon: Icons.person,
                title: 'My Profile',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.timer,
                title: 'Pomodoro Preferences',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.pomodoroPreferences);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.date_range,
                title: 'Date & Time',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.dateTime);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.security,
                title: 'Account & Security',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.accountSecurity);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.color_lens,
                title: 'App Appearance',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.appAppearance);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.help,
                title: 'Help & Support',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.helpSupport);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.cloud_sync,
                title: 'Backup & Sync',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BackupSyncScreen(backupService: backupService),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocConsumer<SettingsCubit, SettingsState>(
                listener: (context, state) {
                  if (state.isLoggedOut) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                  if (state.logoutError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: ${state.logoutError}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return _buildSettingItem(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: Colors.red,
                    onTap: () {
                      final settingsCubit = context.read<SettingsCubit>();
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  settingsCubit.logout();
                                },
                                child: const Text(
                                  'Yes',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(),
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        Color titleColor = Colors.black,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: titleColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
      onTap: onTap,
    );
  }
}