import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/strings.dart';

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
          backgroundColor: AppColors.snackbarError,
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
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.all(AppSizes.dialogPadding),
              title: Center(
                child: Text(
                  AppStrings.timerModeTitle,
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              content: SizedBox(
                height: 500,
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
                          child: DropdownButtonFormField<String>(
                            value: timerMode,
                            decoration: InputDecoration(
                              labelText: AppStrings.timerModeLabel,
                              labelStyle: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                color: AppColors.textPrimary,
                              ),
                              helperText: AppStrings.timerModeHelper,
                              helperStyle: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: const BorderSide(color: AppColors.textDisabled),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: const BorderSide(color: AppColors.textDisabled),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
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
                          color: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: TextField(
                              controller: workController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: AppStrings.workDurationLabel,
                                labelStyle: GoogleFonts.poppins(
                                  fontSize: AppSizes.labelFontSize,
                                  color: AppColors.textPrimary,
                                ),
                                helperText: AppStrings.workDurationHelper,
                                helperStyle: GoogleFonts.poppins(
                                  fontSize: AppSizes.helperFontSize,
                                  color: AppColors.textDisabled,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(color: AppColors.textDisabled),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(color: AppColors.textDisabled),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
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
                          color: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: TextField(
                              controller: breakController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: AppStrings.breakDurationLabel,
                                labelStyle: GoogleFonts.poppins(
                                  fontSize: AppSizes.labelFontSize,
                                  color: AppColors.textPrimary,
                                ),
                                helperText: AppStrings.breakDurationHelper,
                                helperStyle: GoogleFonts.poppins(
                                  fontSize: AppSizes.helperFontSize,
                                  color: AppColors.textDisabled,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(color: AppColors.textDisabled),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(color: AppColors.textDisabled),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
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
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: TextField(
                            controller: sessionsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppStrings.sessionsLabel,
                              labelStyle: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                color: AppColors.textPrimary,
                              ),
                              helperText: AppStrings.sessionsHelper,
                              helperStyle: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: const BorderSide(color: AppColors.textDisabled),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: const BorderSide(color: AppColors.textDisabled),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
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
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              AppStrings.soundLabel,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              AppStrings.soundHelper,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            value: soundEnabled,
                            onChanged: (value) {
                              setState(() {
                                soundEnabled = value ?? true;
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
                      if (soundEnabled) ...[
                        const SizedBox(height: AppSizes.spacing),
                        Card(
                          elevation: 2,
                          color: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: DropdownButtonFormField<String>(
                              value: notificationSound,
                              decoration: InputDecoration(
                                labelText: AppStrings.notificationSoundLabel,
                                labelStyle: GoogleFonts.poppins(
                                  fontSize: AppSizes.labelFontSize,
                                  color: AppColors.textPrimary,
                                ),
                                helperText: AppStrings.notificationSoundHelper,
                                helperStyle: GoogleFonts.poppins(
                                  fontSize: AppSizes.helperFontSize,
                                  color: AppColors.textDisabled,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(color: AppColors.textDisabled),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(color: AppColors.textDisabled),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
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
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              AppStrings.autoSwitchLabel,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              AppStrings.autoSwitchHelper,
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            value: autoSwitch,
                            onChanged: (value) {
                              setState(() {
                                autoSwitch = value ?? false;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
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
                  icon: const Icon(
                    Icons.hourglass_empty,
                    color: AppColors.textDisabled,
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
                          backgroundColor: AppColors.snackbarError,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  splashRadius: 24,
                ),
                Text(
                  'Timer Mode',
                  style: GoogleFonts.poppins(
                    color: AppColors.textDisabled,
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