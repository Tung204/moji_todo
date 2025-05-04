import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/settings_cubit.dart';
import '../domain/settings_state.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';

class BackupSyncScreen extends StatelessWidget {
  final BackupService backupService;

  const BackupSyncScreen({super.key, required this.backupService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: Scaffold(
        appBar: const CustomAppBar(showBackButton: true),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              const Text(
                'Backup & Sync',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<DateTime?>(
                future: backupService.getLastBackupTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading backup status...',
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Error loading backup status',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      'Last backup: ${snapshot.data!.toString()}',
                      style: const TextStyle(color: Colors.grey),
                    );
                  }
                  return const Text(
                    'No backup yet',
                    style: TextStyle(color: Colors.grey),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  final validIntervals = [1, 2, 4, 6, 12, 24];
                  final isValidInterval = validIntervals.contains(state.syncInterval);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Sync Interval: ${isValidInterval ? '${state.syncInterval} hours' : 'Custom (${state.syncInterval} hours)'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: isValidInterval ? state.syncInterval : -1,
                        decoration: const InputDecoration(
                          labelText: 'Sync Interval (hours)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ...validIntervals.map((hours) {
                            return DropdownMenuItem<int>(
                              value: hours,
                              child: Text('$hours hours'),
                            );
                          }),
                          const DropdownMenuItem<int>(
                            value: -1,
                            child: Text('Custom'),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == -1) {
                            int? customHours = await _showCustomIntervalDialog(context);
                            if (customHours != null) {
                              context.read<SettingsCubit>().setSyncInterval(customHours);
                            }
                          } else if (value != null) {
                            context.read<SettingsCubit>().setSyncInterval(value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSettingItem(
                        context,
                        icon: Icons.cloud_upload,
                        title: 'Backup Now',
                        onTap: () async {
                          try {
                            await backupService.backupToFirestore();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Backup completed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            (context as Element).markNeedsBuild();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Backup failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      _buildSettingItem(
                        context,
                        icon: Icons.cloud_download,
                        title: 'Restore from Cloud',
                        onTap: () async {
                          try {
                            await backupService.restoreFromFirestore();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Restore completed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Restore failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      _buildSettingItem(
                        context,
                        icon: Icons.delete_forever,
                        title: 'Delete Cloud Backup',
                        titleColor: Colors.red,
                        onTap: () async {
                          showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text('Are you sure you want to delete your cloud backup?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogContext);
                                      try {
                                        await backupService.deleteFirestoreBackup();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cloud backup deleted successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        (context as Element).markNeedsBuild();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to delete cloud backup: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
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
                      ),
                      _buildSettingItem(
                        context,
                        icon: Icons.file_download,
                        title: 'Export to Local JSON',
                        onTap: () async {
                          try {
                            final filePath = await backupService.exportToLocalJson();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exported to $filePath'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Export failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
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

  Future<int?> _showCustomIntervalDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Custom Sync Interval'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter hours',
              hintText: 'e.g., 8',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final hours = int.tryParse(controller.text);
                if (hours != null && hours > 0) {
                  Navigator.pop(dialogContext, hours);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number of hours'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}