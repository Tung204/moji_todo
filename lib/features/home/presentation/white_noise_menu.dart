import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/sizes.dart';

class WhiteNoiseMenu extends StatelessWidget {
  const WhiteNoiseMenu({super.key});

  void _showWhiteNoiseMenu(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final currentState = homeCubit.state;
    bool isWhiteNoiseEnabled = currentState.isWhiteNoiseEnabled;
    String selectedWhiteNoise = currentState.selectedWhiteNoise ?? 'none';
    double whiteNoiseVolume = currentState.whiteNoiseVolume;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
          ),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8),
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
                    'White Noise Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: GoogleFonts.inter().fontFamily,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 350),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
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
                                    'Tắt White Noise',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontFamily: GoogleFonts.inter().fontFamily,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  subtitle: Text(
                                    'Tắt âm thanh White Noise',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontFamily: GoogleFonts.inter().fontFamily,
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
                            if (isWhiteNoiseEnabled) ...[
                              const SizedBox(height: AppSizes.spacing),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSizes.cardPadding),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Volume: ${(whiteNoiseVolume * 100).round()}%',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontFamily: GoogleFonts.inter().fontFamily,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: whiteNoiseVolume,
                                          min: 0.0,
                                          max: 1.0,
                                          divisions: 20,
                                          activeColor: Theme.of(context).colorScheme.primary,
                                          inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSizes.cardPadding),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedWhiteNoise,
                                    decoration: InputDecoration(
                                      labelText: 'Chọn âm thanh',
                                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontFamily: GoogleFonts.inter().fontFamily,
                                          ),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.surface,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'none', child: Text('Không có')),
                                      DropdownMenuItem(value: 'clock_ticking', child: Text('Tiếng đồng hồ')),
                                      DropdownMenuItem(value: 'gentle-rain', child: Text('Mưa nhẹ')),
                                      DropdownMenuItem(value: 'metronome', child: Text('Nhịp điệu')),
                                      DropdownMenuItem(value: 'small-stream', child: Text('Suối nhỏ')),
                                      DropdownMenuItem(value: 'water-stream', child: Text('Dòng nước')),
                                      DropdownMenuItem(value: 'bonfire', child: Text('Lửa trại')),
                                      DropdownMenuItem(value: 'cafe', child: Text('Quán cà phê')),
                                      DropdownMenuItem(value: 'library', child: Text('Thư viện')),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomButton(
                          label: 'Hủy',
                          onPressed: () => Navigator.pop(context),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          textColor: Theme.of(context).colorScheme.onError,
                          borderRadius: AppSizes.borderRadius,
                        ),
                        CustomButton(
                          label: 'OK',
                          onPressed: () {
                            homeCubit.toggleWhiteNoise(isWhiteNoiseEnabled);
                            homeCubit.selectWhiteNoise(selectedWhiteNoise);
                            homeCubit.setWhiteNoiseVolume(whiteNoiseVolume);
                            Navigator.pop(context);
                          },
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          borderRadius: AppSizes.borderRadius,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                color: state.isWhiteNoiseEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                size: AppSizes.iconSize,
              ),
              onPressed: () => _showWhiteNoiseMenu(context),
            ),
            Text(
              'White Noise',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: GoogleFonts.inter().fontFamily,
                    color: state.isWhiteNoiseEnabled
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );
      },
    );
  }
}