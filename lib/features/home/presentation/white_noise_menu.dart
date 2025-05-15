import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';

class WhiteNoiseMenu extends StatelessWidget {
  const WhiteNoiseMenu({super.key});

  void _showWhiteNoiseMenu(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final currentState = homeCubit.state;
    bool isWhiteNoiseEnabled = currentState.isWhiteNoiseEnabled;
    String? selectedWhiteNoise = currentState.selectedWhiteNoise ?? 'none';
    double whiteNoiseVolume = currentState.whiteNoiseVolume;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).cardTheme.color,
              title: Text(
                'White Noise Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Volume: ${(whiteNoiseVolume * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Expanded(
                        child: Slider(
                          value: whiteNoiseVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedWhiteNoise,
                    hint: Text(
                      'Select Sound',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'none',
                        child: Text('None'),
                      ),
                      DropdownMenuItem(
                        value: 'clock_ticking',
                        child: Text('Clock Ticking'),
                      ),
                      DropdownMenuItem(
                        value: 'gentle-rain',
                        child: Text('Rain'),
                      ),
                      DropdownMenuItem(
                        value: 'metronome',
                        child: Text('Metronome'),
                      ),
                      DropdownMenuItem(
                        value: 'small-stream',
                        child: Text('Stream'),
                      ),
                      DropdownMenuItem(
                        value: 'water-stream',
                        child: Text('Water Stream'),
                      ),
                      DropdownMenuItem(
                        value: 'bonfire',
                        child: Text('Bonfire'),
                      ),
                      DropdownMenuItem(
                        value: 'cafe',
                        child: Text('Cafe'),
                      ),
                      DropdownMenuItem(
                        value: 'library',
                        child: Text('Library'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedWhiteNoise = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    homeCubit.toggleWhiteNoise(isWhiteNoiseEnabled);
                    if (selectedWhiteNoise != null) {
                      homeCubit.selectWhiteNoise(selectedWhiteNoise!);
                    } else {
                      homeCubit.selectWhiteNoise('clock_ticking');
                    }
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
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
                color: state.isWhiteNoiseEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                size: 28,
              ),
              onPressed: () => _showWhiteNoiseMenu(context),
            ),
            Text(
              'White Noise',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: state.isWhiteNoiseEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}