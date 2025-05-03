import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';

class PomodoroTimer extends StatelessWidget {
  final int timerSeconds;
  final bool isRunning;
  final bool isPaused;
  final int currentSession;
  final int totalSessions;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onContinue;
  final VoidCallback onStop;

  const PomodoroTimer({
    super.key,
    required this.timerSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.currentSession,
    required this.totalSessions,
    required this.onStart,
    required this.onPause,
    required this.onContinue,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = timerSeconds ~/ 60;
    final seconds = timerSeconds % 60;
    final double progress = timerSeconds / (25 * 60); // Tiến độ vòng tròn (25 phút = 1500 giây)

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 25,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isRunning ? Colors.blue : Colors.red,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  currentSession == 0
                      ? 'No sessions'
                      : '$currentSession of $totalSessions sessions',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 56),
        if (!isRunning && !isPaused)
          CustomButton(
            label: 'Start to Focus',
            onPressed: onStart,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            borderRadius: 20,
          ),
        if (isRunning && !isPaused)
          CustomButton(
            label: 'Pause',
            onPressed: onPause,
            backgroundColor: Colors.grey,
            textColor: Colors.white,
            borderRadius: 20,
          ),
        if (isPaused)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                label: 'Stop',
                onPressed: onStop,
                backgroundColor: Colors.grey,
                textColor: Colors.white,
                borderRadius: 20,
              ),
              const SizedBox(width: 16),
              CustomButton(
                label: 'Continue',
                onPressed: onContinue,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                borderRadius: 20,
              ),
            ],
          ),
      ],
    );
  }
}