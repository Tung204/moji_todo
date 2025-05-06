import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';

class StrictModeMenu extends StatelessWidget {
  const StrictModeMenu({super.key});

  static const MethodChannel _permissionChannel = MethodChannel('com.example.moji_todo/permissions');
  static const MethodChannel _serviceChannel = MethodChannel('com.example.moji_todo/app_block_service');

  Future<bool> _checkAndRequestAccessibilityPermission(BuildContext context) async {
    final bool isPermissionEnabled = await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
    if (!isPermissionEnabled) {
      bool? granted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          title: const Text(
            'Yêu cầu quyền Accessibility',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: const Text(
            'Ứng dụng cần quyền Accessibility để chặn ứng dụng khi Strict Mode được bật. Vui lòng cấp quyền trong cài đặt.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Từ chối',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _permissionChannel.invokeMethod('requestAccessibilityPermission');
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF5733),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Cấp quyền',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
  }

  void _showStrictModeMenu(BuildContext context) {
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
            return BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                bool isAppBlockingEnabled = state.isAppBlockingEnabled;
                bool isFlipPhoneEnabled = state.isFlipPhoneEnabled;
                bool isExitBlockingEnabled = state.isExitBlockingEnabled;
                List<String> blockedApps = List.from(state.blockedApps);

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  backgroundColor: Colors.white,
                  title: const Text(
                    'Strict Mode Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          title: const Text(
                            'Tắt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
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
                          activeColor: const Color(0xFFFF5733),
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        CheckboxListTile(
                          title: const Text(
                            'Chặn ứng dụng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
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
                          activeColor: const Color(0xFFFF5733),
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        if (isAppBlockingEnabled)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (appDialogContext) {
                                        return StatefulBuilder(
                                          builder: (context, setAppDialogState) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              elevation: 8,
                                              backgroundColor: Colors.white,
                                              title: const Text(
                                                'Chọn ứng dụng để chặn',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: availableApps.map((app) {
                                                    return CheckboxListTile(
                                                      title: Text(
                                                        app['name']!,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.black87,
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
                                                      activeColor: const Color(0xFFFF5733),
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
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(appDialogContext);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.grey[200],
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  ),
                                                  child: const Text(
                                                    'Hủy',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      context.read<HomeCubit>().updateBlockedApps(blockedApps);
                                                      _serviceChannel.invokeMethod('setBlockedApps', {'apps': blockedApps});
                                                    });
                                                    Navigator.pop(appDialogContext);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: const Color(0xFFFF5733),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  ),
                                                  child: const Text(
                                                    'OK',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: const Text(
                                    'Danh sách ứng dụng',
                                    style: TextStyle(
                                      color: Color(0xFFFF5733),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        CheckboxListTile(
                          title: const Text(
                            'Lật điện thoại',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          value: isFlipPhoneEnabled,
                          onChanged: (value) {
                            setState(() {
                              isFlipPhoneEnabled = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFFFF5733),
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        CheckboxListTile(
                          title: const Text(
                            'Cấm thoát',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          value: isExitBlockingEnabled,
                          onChanged: (value) {
                            setState(() {
                              isExitBlockingEnabled = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFFFF5733),
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<HomeCubit>().updateStrictMode(
                          isAppBlockingEnabled: isAppBlockingEnabled,
                          isFlipPhoneEnabled: isFlipPhoneEnabled,
                          isExitBlockingEnabled: isExitBlockingEnabled,
                        );
                        Navigator.pop(dialogContext);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5733),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Column(
          children: [
            IconButton(
              icon: Icon(
                Icons.warning,
                color: state.isStrictModeEnabled ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                if (state.isTimerRunning) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể chỉnh Strict Mode khi timer đang chạy!'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  _showStrictModeMenu(context);
                }
              },
            ),
            Text(
              'Strict Mode ${state.isStrictModeEnabled ? 'On' : 'Off'}',
              style: TextStyle(
                color: state.isStrictModeEnabled ? Colors.red : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}