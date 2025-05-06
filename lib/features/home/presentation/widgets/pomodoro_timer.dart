import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/home_cubit.dart';
import '../../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';

class PomodoroTimer extends StatefulWidget {
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
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Thời gian animation: 0.5 giây
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final minutes = (widget.timerSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (widget.timerSeconds % 60).toString().padLeft(2, '0');
        final totalDuration = (state.isWorkSession ? state.workDuration : state.breakDuration) * 60;
        final targetProgress = totalDuration > 0 ? widget.timerSeconds / totalDuration : 0.0;

        // Cập nhật animation khi progress thay đổi
        if (_currentProgress != targetProgress) {
          _progressAnimation = Tween<double>(
            begin: _currentProgress,
            end: targetProgress,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeInOut,
            ),
          );
          _currentProgress = targetProgress;
          _progressController.forward(from: 0.0);
        }

        return Column(
          children: [
            Text(
              state.isWorkSession ? 'Phiên làm việc' : 'Phiên nghỉ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 20,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isRunning ? Colors.blue : Colors.red,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes:$seconds',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      widget.currentSession == 0
                          ? 'No sessions'
                          : '${widget.currentSession} of ${widget.totalSessions} sessions',
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
            if (!widget.isRunning && !widget.isPaused)
              CustomButton(
                label: state.isWorkSession ? 'Start to Focus' : 'Start Break',
                onPressed: widget.onStart,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                borderRadius: 20,
              ),
            if (widget.isRunning && !widget.isPaused)
              CustomButton(
                label: 'Pause',
                onPressed: widget.onPause,
                backgroundColor: Colors.grey,
                textColor: Colors.white,
                borderRadius: 20,
              ),
            if (widget.isPaused)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    label: 'Stop',
                    onPressed: widget.onStop,
                    backgroundColor: Colors.grey,
                    textColor: Colors.white,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    label: 'Continue',
                    onPressed: widget.onContinue,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    borderRadius: 20,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}