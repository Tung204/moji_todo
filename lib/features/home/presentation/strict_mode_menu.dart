import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/strings.dart';

class StrictModeMenu extends StatelessWidget {
  const StrictModeMenu({super.key});

  static const MethodChannel _permissionChannel = MethodChannel('com.example.moji_todo/permissions');
  static const MethodChannel _serviceChannel = MethodChannel('com.example.moji_todo/app_block_service');

  Future<bool> _checkAndRequestAccessibilityPermission(BuildContext context) async {
    try {
      final bool isPermissionEnabled = await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
      if (!isPermissionEnabled) {
        bool? granted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
            title: Text(
              'Yêu cầu quyền Accessibility',
              style: GoogleFonts.poppins(
                fontSize: AppSizes.titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'Ứng dụng cần quyền Accessibility để chặn ứng dụng khi Strict Mode được bật. Vui lòng cấp quyền trong cài đặt.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              CustomButton(
                label: AppStrings.cancel,
                onPressed: () => Navigator.pop(context, false),
                backgroundColor: AppColors.cancelButton,
                textColor: AppColors.textPrimary,
                borderRadius: AppSizes.borderRadius,
              ),
              CustomButton(
                label: 'Cấp quyền',
                onPressed: () async {
                  await _permissionChannel.invokeMethod('requestAccessibilityPermission');
                  Navigator.pop(context, true);
                },
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                borderRadius: AppSizes.borderRadius,
              ),
            ],
          ),
        );

        if (granted != true) {
          SystemNavigator.pop();
          return false;
        }

        return await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
      }
      return true;
    } catch (e) {
      print('Error checking accessibility permission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi kiểm tra quyền Accessibility: $e'),
          backgroundColor: AppColors.snackbarError,
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  void _showStrictModeMenu(BuildContext context) {
    print('Opening Strict Mode dialog');
    bool isAppBlockingEnabled = context.read<HomeCubit>().state.isAppBlockingEnabled;
    bool isFlipPhoneEnabled = context.read<HomeCubit>().state.isFlipPhoneEnabled;
    bool isExitBlockingEnabled = context.read<HomeCubit>().state.isExitBlockingEnabled;
    List<String> blockedApps = List.from(context.read<HomeCubit>().state.blockedApps);

    final List<Map<String, String>> availableApps = [
      {'name': 'Facebook', 'package': 'com.facebook.katana'},
      {'name': 'YouTube', 'package': 'com.google.android.youtube'},
      {'name': 'Instagram', 'package': 'com.instagram.android'},
      {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically'},
      {'name': 'Twitter', 'package': 'com.twitter.android'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.all(AppSizes.dialogPadding),
              title: Text(
                AppStrings.strictModeTitle,
                style: GoogleFonts.poppins(
                  fontSize: AppSizes.titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                height: 350,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 2,
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              AppStrings.strictModeOffLabel,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              AppStrings.strictModeOffHelper,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            value: !isAppBlockingEnabled && !isFlipPhoneEnabled && !isExitBlockingEnabled,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  isAppBlockingEnabled = false;
                                  isFlipPhoneEnabled = false;
                                  isExitBlockingEnabled = false;
                                  blockedApps = [];
                                }
                              });
                            },
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing),
                      Card(
                        elevation: 2,
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              AppStrings.appBlockingLabel,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              AppStrings.appBlockingHelper,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            value: isAppBlockingEnabled,
                            onChanged: (value) async {
                              if (value == true) {
                                bool permissionGranted = await _checkAndRequestAccessibilityPermission(context);
                                if (!permissionGranted) {
                                  return;
                                }
                              }
                              setState(() {
                                isAppBlockingEnabled = value ?? false;
                                if (!isAppBlockingEnabled) {
                                  blockedApps = [];
                                }
                              });
                            },
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      if (isAppBlockingEnabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: AppSizes.spacing),
                          child: OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (appDialogContext) {
                                  return StatefulBuilder(
                                    builder: (context, setAppDialogState) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                                        ),
                                        elevation: 8,
                                        backgroundColor: Colors.white,
                                        title: Text(
                                          AppStrings.selectAppsTitle,
                                          style: GoogleFonts.poppins(
                                            fontSize: AppSizes.titleFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        content: SizedBox(
                                          height: 200,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: availableApps.map((app) {
                                                return CheckboxListTile(
                                                  title: Text(
                                                    app['name']!,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: AppSizes.labelFontSize,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                  value: blockedApps.contains(app['package']),
                                                  onChanged: (value) {
                                                    setAppDialogState(() {
                                                      if (value == true) {
                                                        blockedApps.add(app['package']!);
                                                      } else {
                                                        blockedApps.remove(app['package']);
                                                      }
                                                    });
                                                  },
                                                  activeColor: AppColors.primary,
                                                  checkColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  controlAffinity: ListTileControlAffinity.leading,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          CustomButton(
                                            label: AppStrings.cancel,
                                            onPressed: () => Navigator.pop(appDialogContext),
                                            backgroundColor: AppColors.cancelButton,
                                            textColor: AppColors.textPrimary,
                                            borderRadius: AppSizes.borderRadius,
                                          ),
                                          CustomButton(
                                            label: AppStrings.ok,
                                            onPressed: () {
                                              setState(() {
                                                context.read<HomeCubit>().updateBlockedApps(blockedApps);
                                                _serviceChannel.invokeMethod('setBlockedApps', {'apps': blockedApps});
                                              });
                                              Navigator.pop(appDialogContext);
                                            },
                                            backgroundColor: AppColors.primary,
                                            textColor: Colors.white,
                                            borderRadius: AppSizes.borderRadius,
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              AppStrings.selectApps,
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontSize: AppSizes.helperFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSizes.spacing),
                      Card(
                        elevation: 2,
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              AppStrings.flipPhoneLabel,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              AppStrings.flipPhoneHelper,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            value: isFlipPhoneEnabled,
                            onChanged: (value) {
                              setState(() {
                                isFlipPhoneEnabled = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing),
                      Card(
                        elevation: 2,
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              AppStrings.exitBlockingLabel,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              AppStrings.exitBlockingHelper,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            value: isExitBlockingEnabled,
                            onChanged: (value) {
                              setState(() {
                                isExitBlockingEnabled = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                CustomButton(
                  label: AppStrings.cancel,
                  onPressed: () => Navigator.pop(dialogContext),
                  backgroundColor: AppColors.cancelButton,
                  textColor: AppColors.textPrimary,
                  borderRadius: AppSizes.borderRadius,
                ),
                CustomButton(
                  label: AppStrings.ok,
                  onPressed: () {
                    context.read<HomeCubit>().updateStrictMode(
                      isAppBlockingEnabled: isAppBlockingEnabled,
                      isFlipPhoneEnabled: isFlipPhoneEnabled,
                      isExitBlockingEnabled: isExitBlockingEnabled,
                    );
                    Navigator.pop(dialogContext);
                  },
                  backgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  borderRadius: AppSizes.borderRadius,
                ),
              ],
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
      previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.isStrictModeEnabled != current.isStrictModeEnabled,
      builder: (context, state) {
        final isEditable = !state.isTimerRunning || state.isPaused;
        print('Strict Mode button build: isEditable=$isEditable');
        return Tooltip(
          message: isEditable ? 'Chỉnh Strict Mode' : 'Tạm dừng timer để chỉnh Strict Mode',
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.warning,
                    color: state.isStrictModeEnabled ? AppColors.primary : AppColors.textDisabled,
                    size: AppSizes.iconSize,
                  ),
                  onPressed: () {
                    print('Strict Mode button pressed: isEditable=$isEditable');
                    if (isEditable) {
                      _showStrictModeMenu(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.timerRunningError),
                          backgroundColor: AppColors.snackbarError,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  splashRadius: 24,
                ),
                Text(
                  'Strict Mode ${state.isStrictModeEnabled ? 'On' : 'Off'}',
                  style: GoogleFonts.poppins(
                    color: state.isStrictModeEnabled ? AppColors.primary : AppColors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}