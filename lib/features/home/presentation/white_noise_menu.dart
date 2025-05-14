import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/strings.dart';

class WhiteNoiseMenu extends StatelessWidget {
  const WhiteNoiseMenu({super.key});

  void _showWhiteNoiseMenu(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final currentState = homeCubit.state;
    bool isWhiteNoiseEnabled = currentState.isWhiteNoiseEnabled;
    String selectedWhiteNoise = currentState.selectedWhiteNoise ?? 'none';
    double whiteNoiseVolume = currentState.whiteNoiseVolume;

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
                  'Cài đặt White Noise',
                  style: GoogleFonts.poppins(
                    fontSize: AppSizes.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
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
                              'Tắt White Noise',
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.labelFontSize,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              'Tắt âm thanh White Noise',
                              style: GoogleFonts.poppins(
                                fontSize: AppSizes.helperFontSize,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            value: !isWhiteNoiseEnabled,
                            onChanged: (value) {
                              setState(() {
                                isWhiteNoiseEnabled = !(value ?? false);
                                if (!isWhiteNoiseEnabled) {
                                  selectedWhiteNoise = 'none';
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
                      if (isWhiteNoiseEnabled) ...[
                        const SizedBox(height: AppSizes.spacing),
                        Card(
                          elevation: 2,
                          color: AppColors.cardBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Âm lượng: ${(whiteNoiseVolume * 100).round()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: AppSizes.labelFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: whiteNoiseVolume,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 10,
                                    activeColor: AppColors.primary,
                                    inactiveColor: AppColors.textDisabled,
                                    onChanged: (value) {
                                      setState(() {
                                        whiteNoiseVolume = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
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
                            child: DropdownButtonFormField<String>(
                              value: selectedWhiteNoise,
                              decoration: InputDecoration(
                                labelText: 'Chọn âm thanh',
                                labelStyle: GoogleFonts.poppins(
                                  fontSize: AppSizes.labelFontSize,
                                  color: AppColors.textPrimary,
                                ),
                                helperText: 'Chọn âm thanh White Noise',
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
                                  value: 'none',
                                  child: Text('Không có', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownMenuItem(
                                  value: 'clock_ticking',
                                  child: Text('Tiếng đồng hồ', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownMenuItem(
                                  value: 'gentle-rain',
                                  child: Text('Mưa nhẹ', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownMenuItem(
                                  value: 'metronome',
                                  child: Text('Nhịp điệu', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownMenuItem(
                                  value: 'small-stream',
                                  child: Text('Suối nhỏ', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownMenuItem(
                                  value: 'water-stream',
                                  child: Text('Dòng nước', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownMenuItem(
                                  value: 'bonfire',
                                  child: Text('Lửa trại', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownMenuItem(
                                  value: 'cafe',
                                  child: Text('Quán cà phê', style: TextStyle(fontSize: 16)),
                                ),
                                DropdownMenuItem(
                                  value: 'library',
                                  child: Text('Thư viện', style: TextStyle(fontSize: 16)),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedWhiteNoise = value ?? 'none';
                                  isWhiteNoiseEnabled = value != 'none';
                                });
                              },
                            ),
                          ),
                        ),
                      ],
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
                        homeCubit.toggleWhiteNoise(isWhiteNoiseEnabled);
                        homeCubit.selectWhiteNoise(selectedWhiteNoise);
                        homeCubit.setWhiteNoiseVolume(whiteNoiseVolume);
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
      previous.isWhiteNoiseEnabled != current.isWhiteNoiseEnabled ||
          previous.selectedWhiteNoise != current.selectedWhiteNoise,
      builder: (context, state) {
        return Column(
          children: [
            IconButton(
              icon: Icon(
                Icons.music_note,
                color: state.isWhiteNoiseEnabled ? AppColors.primary : AppColors.textDisabled,
                size: AppSizes.iconSize,
              ),
              onPressed: () => _showWhiteNoiseMenu(context),
              splashRadius: 24,
            ),
            Text(
              'White Noise',
              style: GoogleFonts.poppins(
                color: state.isWhiteNoiseEnabled ? AppColors.primary : AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}