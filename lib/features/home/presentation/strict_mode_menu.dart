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
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
            ),
            elevation: 10,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.backgroundGradientStart,
                    AppColors.backgroundGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text(
                      'Yêu cầu quyền Accessibility',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Ứng dụng cần quyền Accessibility để chặn ứng dụng khi Strict Mode được bật. Vui lòng cấp quyền trong cài đặt.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomButton(
                          label: AppStrings.cancel,
                          onPressed: () => Navigator.pop(context, false),
                          backgroundColor: AppColors.cancelButton,
                          textColor: AppColors.textPrimary,
                          borderRadius: 12,
                        ),
                        CustomButton(
                          label: 'Cấp quyền',
                          onPressed: () async {
                            await _permissionChannel.invokeMethod('requestAccessibilityPermission');
                            Navigator.pop(context, true);
                          },
                          backgroundColor: AppColors.primary,
                          textColor: Colors.white,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    final homeState = context.read<HomeCubit>().state;

    bool isEditable = homeState.isPaused ||
        (!homeState.isTimerRunning && !homeState.isPaused) ||
        (!homeState.isCountingUp && homeState.timerSeconds <= 0);

    if (!isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode!'),
          backgroundColor: AppColors.snackbarError,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    bool isAppBlockingEnabled = homeState.isAppBlockingEnabled;
    bool isFlipPhoneEnabled = homeState.isFlipPhoneEnabled;
    bool isExitBlockingEnabled = homeState.isExitBlockingEnabled;
    List<String> blockedApps = List.from(homeState.blockedApps);

    final List<Map<String, String>> availableApps = [
      {'name': 'Facebook', 'package': 'com.facebook.katana'},
      {'name': 'YouTube', 'package': 'com.google.android.youtube'},
      {'name': 'Instagram', 'package': 'com.instagram.android'},
      {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically'},
      {'name': 'Twitter', 'package': 'com.twitter.android'},
    ];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
              ),
              elevation: 10,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.backgroundGradientStart,
                      AppColors.backgroundGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Text(
                        AppStrings.strictModeTitle,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 350),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildCard(
                              child: CheckboxListTile(
                                title: Text(
                                  AppStrings.strictModeOffLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.labelFontSize - 2,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  AppStrings.strictModeOffHelper,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.helperFontSize,
                                    color: AppColors.textSecondary,
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
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacing / 2),
                            _buildCard(
                              child: CheckboxListTile(
                                title: Text(
                                  AppStrings.appBlockingLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.labelFontSize - 2,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  AppStrings.appBlockingHelper,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.helperFontSize,
                                    color: AppColors.textSecondary,
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
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (isAppBlockingEnabled)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: OutlinedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (appDialogContext) {
                                        return StatefulBuilder(
                                          builder: (context, setAppDialogState) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                                              ),
                                              elevation: 10,
                                              backgroundColor: Colors.transparent,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      AppColors.backgroundGradientStart,
                                                      AppColors.backgroundGradientEnd,
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                                      child: Text(
                                                        AppStrings.selectAppsTitle,
                                                        style: GoogleFonts.inter(
                                                          fontSize: AppSizes.titleFontSize,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      constraints: const BoxConstraints(maxHeight: 200),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          children: availableApps.map((app) {
                                                            return _buildCard(
                                                              child: CheckboxListTile(
                                                                title: Text(
                                                                  app['name']!,
                                                                  style: GoogleFonts.inter(
                                                                    fontSize: AppSizes.labelFontSize - 2,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: AppColors.textPrimary,
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
                                                                contentPadding: EdgeInsets.zero,
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(16),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          CustomButton(
                                                            label: AppStrings.cancel,
                                                            onPressed: () => Navigator.pop(appDialogContext),
                                                            backgroundColor: AppColors.cancelButton,
                                                            textColor: AppColors.textPrimary,
                                                            borderRadius: 12,
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
                                                            borderRadius: 12,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text(
                                    AppStrings.selectApps,
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontSize: AppSizes.helperFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSizes.spacing / 2),
                            _buildCard(
                              child: CheckboxListTile(
                                title: Text(
                                  AppStrings.flipPhoneLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.labelFontSize - 2,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  AppStrings.flipPhoneHelper,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.helperFontSize,
                                    color: AppColors.textSecondary,
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
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacing / 2),
                            _buildCard(
                              child: CheckboxListTile(
                                title: Text(
                                  AppStrings.exitBlockingLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.labelFontSize - 2,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  AppStrings.exitBlockingHelper,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.helperFontSize,
                                    color: AppColors.textSecondary,
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
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomButton(
                            label: AppStrings.cancel,
                            onPressed: () => Navigator.pop(context),
                            backgroundColor: AppColors.cancelButton,
                            textColor: AppColors.textPrimary,
                            borderRadius: 12,
                          ),
                          CustomButton(
                            label: AppStrings.ok,
                            onPressed: () {
                              context.read<HomeCubit>().updateStrictMode(
                                isAppBlockingEnabled: isAppBlockingEnabled,
                                isFlipPhoneEnabled: isFlipPhoneEnabled,
                                isExitBlockingEnabled: isExitBlockingEnabled,
                              );
                              Navigator.pop(context);
                            },
                            backgroundColor: AppColors.primary,
                            textColor: Colors.white,
                            borderRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
      previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.isStrictModeEnabled != current.isStrictModeEnabled ||
          previous.timerSeconds != current.timerSeconds ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        final isEditable = state.isPaused ||
            (!state.isTimerRunning && !state.isPaused) ||
            (!state.isCountingUp && state.timerSeconds <= 0);

        return GestureDetector(
          onTap: () {
            if (isEditable) {
              _showStrictModeMenu(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vui lòng tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode!'),
                  backgroundColor: AppColors.snackbarError,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: Tooltip(
            message: isEditable
                ? 'Chỉnh Strict Mode'
                : 'Tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode',
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: state.isStrictModeEnabled ? AppColors.primary : AppColors.textDisabled,
                    size: AppSizes.iconSize,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Strict Mode ${state.isStrictModeEnabled ? 'On' : 'Off'}',
                    style: GoogleFonts.inter(
                      color: state.isStrictModeEnabled ? AppColors.primary : AppColors.textDisabled,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}