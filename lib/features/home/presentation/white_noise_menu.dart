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
              title: Text(
                'White Noise Settings',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Volume: ${(whiteNoiseVolume * 100).round()}%',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      Expanded(
                        child: Slider(
                          value: whiteNoiseVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
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
                      style: GoogleFonts.poppins(fontSize: 16),
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
                        child: Text('metronome'),
                      ),
                      DropdownMenuItem(
                        value: 'small-stream',
                        child: Text('Stream'),
                      ),
                      DropdownMenuItem(
                        value: 'water-stream',
                        child: Text('water stream'),
                      ),
                      DropdownMenuItem(
                        value: 'bonfire',
                        child: Text('bonfire'),
                      ),
                      DropdownMenuItem(
                        value: 'cafe',
                        child: Text('cafe'),
                      ),
                      DropdownMenuItem(
                        value: 'library',
                        child: Text('library'),
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
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    homeCubit.toggleWhiteNoise(isWhiteNoiseEnabled);
                    if (selectedWhiteNoise != null) {
                      homeCubit.selectWhiteNoise(selectedWhiteNoise!);
                    }else {
                      // Cung cấp giá trị mặc định nếu selectedWhiteNoise là null
                      homeCubit.selectWhiteNoise('clock_ticking');
                    }
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
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
                color: state.isWhiteNoiseEnabled ? Colors.red : Colors.grey,
                size: 28,
              ),
              onPressed: () => _showWhiteNoiseMenu(context),
            ),
            Text(
              'White Noise',
              style: GoogleFonts.poppins(
                color: state.isWhiteNoiseEnabled ? Colors.red : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}