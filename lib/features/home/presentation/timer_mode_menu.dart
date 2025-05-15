import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/sizes.dart';

class TimerModeMenu extends StatelessWidget {
  const TimerModeMenu({super.key});

  void _showTimerModeMenu(BuildContext context) {
    final homeState = context.read<HomeCubit>().state;

    // Chỉ cho phép chỉnh sửa khi timer dừng hẳn hoặc hết giờ
    bool isEditable = (!homeState.isTimerRunning && !homeState.isPaused) ||
        (!homeState.isCountingUp && homeState.timerSeconds <= 0);

    if (!isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode!'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    print('Opening Timer Mode dialog');
    String timerMode = homeState.timerMode;
    int workDuration = homeState.workDuration;
    int breakDuration = homeState.breakDuration;
    bool soundEnabled = homeState.soundEnabled;
    bool autoSwitch = homeState.autoSwitch;
    String notificationSound = homeState.notificationSound;
    int totalSessions = homeState.totalSessions;

    TextEditingController workController = TextEditingController(text: workDuration.toString());
    TextEditingController breakController = TextEditingController(text: breakDuration.toString());
    TextEditingController sessionsController = TextEditingController(text: totalSessions.toString());

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
              title: Center(
                child: Text(
                  'Timer Mode',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              content: SizedBox(
                height: 500,
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
                          child: DropdownButtonFormField<String>(
                            value: timerMode,
                            decoration: InputDecoration(
                              labelText: 'Timer Mode',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                              helperText: 'Chọn chế độ thời gian làm việc và nghỉ.',
                              helperStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '25:00 - 00:00',
                                child: Text('25:00 - 00:00', style: TextStyle(fontSize: 16)),
                              ),
                              DropdownMenuItem(
                                value: '00:00 - 0∞',
                                child: Text('00:00 - 0∞', style: TextStyle(fontSize: 16)),
                              ),
                              DropdownMenuItem(
                                value: 'Tùy chỉnh',
                                child: Text('Tùy chỉnh', style: TextStyle(fontSize: 16)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                timerMode = value ?? '25:00 - 00:00';
                                if (timerMode == '25:00 - 00:00') {
                                  workDuration = 25;
                                  breakDuration = 5;
                                  workController.text = '25';
                                  breakController.text = '5';
                                } else if (timerMode == '00:00 - 0∞') {
                                  workDuration = 0;
                                  breakDuration = 0;
                                  workController.text = '0';
                                  breakController.text = '0';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing),
                      if (timerMode == 'Tùy chỉnh') ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: TextField(
                              controller: workController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Thời gian làm việc (phút)',
                                labelStyle: Theme.of(context).textTheme.bodyMedium,
                                helperText: 'Nhập thời gian làm việc.',
                                helperStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                workDuration = int.tryParse(value) ?? 1;
                              },
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
                            child: TextField(
                              controller: breakController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Thời gian nghỉ (phút)',
                                labelStyle: Theme.of(context).textTheme.bodyMedium,
                                helperText: 'Nhập thời gian nghỉ.',
                                helperStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                breakDuration = int.tryParse(value) ?? 5;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing),
                      ],
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: TextField(
                            controller: sessionsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Số phiên',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                              helperText: 'Nhập số phiên Pomodoro.',
                              helperStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              totalSessions = int.tryParse(value) ?? 4;
                            },
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
                              'Âm thanh',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Bật âm thanh thông báo khi kết thúc phiên.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                            ),
                            value: soundEnabled,
                            onChanged: (value) {
                              setState(() {
                                soundEnabled = value ?? true;
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
                      if (soundEnabled) ...[
                        const SizedBox(height: AppSizes.spacing),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: DropdownButtonFormField<String>(
                              value: notificationSound,
                              decoration: InputDecoration(
                                labelText: 'Âm thanh thông báo',
                                labelStyle: Theme.of(context).textTheme.bodyMedium,
                                helperText: 'Chọn âm thanh thông báo.',
                                helperStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'bell', child: Text('Bell', style: TextStyle(fontSize: 16))),
                                DropdownMenuItem(value: 'chime', child: Text('Chime', style: TextStyle(fontSize: 16))),
                                DropdownMenuItem(value: 'alarm', child: Text('Alarm', style: TextStyle(fontSize: 16))),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  notificationSound = value ?? 'bell';
                                });
                              },
                            ),
                          ),
                        ),
                      ],
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
                              'Tự động chuyển',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Tự động chuyển giữa làm việc và nghỉ.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                            ),
                            value: autoSwitch,
                            onChanged: (value) {
                              setState(() {
                                autoSwitch = value ?? false;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                        context.read<HomeCubit>().updateTimerMode(
                          timerMode: timerMode,
                          workDuration: workDuration,
                          breakDuration: breakDuration,
                          soundEnabled: soundEnabled,
                          autoSwitch: autoSwitch,
                          notificationSound: notificationSound,
                          totalSessions: totalSessions,
                        );
                        Navigator.pop(dialogContext);
                      },
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      borderRadius: AppSizes.borderRadius,
                    ),
                  ],
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
          previous.timerSeconds != current.timerSeconds ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        // Chỉ cho phép chỉnh Timer Mode khi timer dừng hẳn hoặc hết giờ
        final isEditable = (!state.isTimerRunning && !state.isPaused) ||
            (!state.isCountingUp && state.timerSeconds <= 0);
        print('Timer Mode button build: isEditable=$isEditable');

        return Tooltip(
          message: isEditable ? 'Chỉnh Timer Mode' : 'Dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode',
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.hourglass_empty,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    size: AppSizes.iconSize,
                  ),
                  onPressed: () {
                    print('Timer Mode button pressed: isEditable=$isEditable');
                    if (isEditable) {
                      _showTimerModeMenu(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vui lòng dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode!'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  splashRadius: 24,
                ),
                Text(
                  'Timer Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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