import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/sizes.dart';

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
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Text(
              'Yêu cầu quyền Accessibility',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: Text(
              'Ứng dụng cần quyền Accessibility để chặn ứng dụng khi Strict Mode được bật. Vui lòng cấp quyền trong cài đặt.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              CustomButton(
                label: 'Từ chối',
                onPressed: () => Navigator.pop(context, false),
                backgroundColor: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.onError,
                borderRadius: AppSizes.borderRadius,
              ),
              CustomButton(
                label: 'Cấp quyền',
                onPressed: () async {
                  await _permissionChannel.invokeMethod('requestAccessibilityPermission');
                  Navigator.pop(context, true);
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
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
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  void _showStrictModeMenu(BuildContext context) {
    final homeState = context.read<HomeCubit>().state;

    // Chỉ cho phép chỉnh sửa khi timer tạm dừng, dừng hẳn, hoặc hết giờ
    bool isEditable = homeState.isPaused ||
        (!homeState.isTimerRunning && !homeState.isPaused) ||
        (!homeState.isCountingUp && homeState.timerSeconds <= 0);

    if (!isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode!'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('Opening Strict Mode dialog');
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
              backgroundColor: Theme.of(context).cardTheme.color,
              contentPadding: const EdgeInsets.all(AppSizes.dialogPadding),
              title: Text(
                'Strict Mode',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: SizedBox(
                height: 350,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              'Tắt Strict Mode',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Không áp dụng các hạn chế khi sử dụng timer.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              'Chặn ứng dụng',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Chặn các ứng dụng được chọn khi timer đang chạy.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
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
                                        backgroundColor: Theme.of(context).cardTheme.color,
                                        title: Text(
                                          'Chọn ứng dụng',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        content: SizedBox(
                                          height: 200,
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: availableApps.map((app) {
                                                return CheckboxListTile(
                                                  title: Text(
                                                    app['name']!,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
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
                                                  activeColor: Theme.of(context).colorScheme.primary,
                                                  checkColor: Theme.of(context).colorScheme.onPrimary,
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
                                            label: 'Hủy',
                                            onPressed: () => Navigator.pop(appDialogContext),
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                            textColor: Theme.of(context).colorScheme.onError,
                                            borderRadius: AppSizes.borderRadius,
                                          ),
                                          CustomButton(
                                            label: 'OK',
                                            onPressed: () {
                                              setState(() {
                                                context.read<HomeCubit>().updateBlockedApps(blockedApps);
                                                _serviceChannel.invokeMethod('setBlockedApps', {'apps': blockedApps});
                                              });
                                              Navigator.pop(appDialogContext);
                                            },
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            textColor: Theme.of(context).colorScheme.onPrimary,
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
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              'Chọn ứng dụng',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSizes.spacing),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              'Chế độ lật điện thoại',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Yêu cầu lật điện thoại để tiếp tục timer.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                            ),
                            value: isFlipPhoneEnabled,
                            onChanged: (value) {
                              setState(() {
                                isFlipPhoneEnabled = value ?? false;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              'Chặn thoát ứng dụng',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Ngăn thoát ứng dụng khi timer đang chạy.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                            ),
                            value: isExitBlockingEnabled,
                            onChanged: (value) {
                              setState(() {
                                isExitBlockingEnabled = value ?? false;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
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
                  label: 'Hủy',
                  onPressed: () => Navigator.pop(dialogContext),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  textColor: Theme.of(context).colorScheme.onError,
                  borderRadius: AppSizes.borderRadius,
                ),
                CustomButton(
                  label: 'OK',
                  onPressed: () {
                    context.read<HomeCubit>().updateStrictMode(
                      isAppBlockingEnabled: isAppBlockingEnabled,
                      isFlipPhoneEnabled: isFlipPhoneEnabled,
                      isExitBlockingEnabled: isExitBlockingEnabled,
                    );
                    Navigator.pop(dialogContext);
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
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
          previous.isStrictModeEnabled != current.isStrictModeEnabled ||
          previous.timerSeconds != current.timerSeconds ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        // Chỉ cho phép chỉnh Strict Mode khi timer tạm dừng, dừng hẳn, hoặc hết giờ
        final isEditable = state.isPaused ||
            (!state.isTimerRunning && !state.isPaused) ||
            (!state.isCountingUp && state.timerSeconds <= 0);
        print('Strict Mode button build: isEditable=$isEditable');

        return Tooltip(
          message: isEditable ? 'Chỉnh Strict Mode' : 'Tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode',
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.warning,
                    color: state.isStrictModeEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    size: AppSizes.iconSize,
                  ),
                  onPressed: () {
                    print('Strict Mode button pressed: isEditable=$isEditable');
                    if (isEditable) {
                      _showStrictModeMenu(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vui lòng tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode!'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  splashRadius: 24,
                ),
                Text(
                  'Strict Mode ${state.isStrictModeEnabled ? 'On' : 'Off'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: state.isStrictModeEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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