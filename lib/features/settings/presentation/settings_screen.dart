import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../routes/app_routes.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../domain/settings_cubit.dart';
import '../domain/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Bỏ nút back
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
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
              const SizedBox(height: 16),
              BlocConsumer<SettingsCubit, SettingsState>(
                listener: (context, state) {
                  if (state.isLoggedOut) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
                builder: (context, state) {
                  return _buildSettingItem(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: Colors.red,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<SettingsCubit>().logout();
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
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 4,
          onTap: (index) {
            if (index == 4) return; // Đã ở màn hình Settings, không làm gì

            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, AppRoutes.pomodoro);
                break;
              case 1:
                Navigator.pushReplacementNamed(context, AppRoutes.tasks);
                break;
              case 2:
                Navigator.pushReplacementNamed(context, AppRoutes.calendar);
                break;
              case 3:
                Navigator.pushReplacementNamed(context, AppRoutes.report);
                break;
            }
          },
        ),
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