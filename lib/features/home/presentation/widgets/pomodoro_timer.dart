import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/home_cubit.dart';
import '../../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

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
      duration: const Duration(milliseconds: 500),
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
        final minutes = (state.timerSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (state.timerSeconds % 60).toString().padLeft(2, '0');
        final totalDuration = (state.isWorkSession ? state.workDuration : state.breakDuration) * 60;
        final targetProgress = totalDuration > 0 ? state.timerSeconds / totalDuration : 0.0;

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
                          state.isTimerRunning ? Colors.blue : Colors.red,
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
                      state.currentSession == 0
                          ? 'No sessions'
                          : '${state.currentSession} of ${state.totalSessions} sessions',
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
            if (!state.isTimerRunning && !state.isPaused)
              CustomButton(
                label: state.isWorkSession ? 'Start to Focus' : 'Start Break',
                onPressed: () {
                  context.read<HomeCubit>().startTimer();
                },
                backgroundColor: Colors.red,
                textColor: Colors.white,
                borderRadius: 20,
              ),
            if (state.isTimerRunning && !state.isPaused)
              CustomButton(
                label: 'Pause',
                onPressed: () {
                  context.read<HomeCubit>().pauseTimer();
                },
                backgroundColor: Colors.grey,
                textColor: Colors.white,
                borderRadius: 20,
              ),
            if (state.isPaused)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    label: 'Stop',
                    onPressed: () {
                      context.read<HomeCubit>().stopTimer();
                    },
                    backgroundColor: Colors.grey,
                    textColor: Colors.white,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    label: 'Continue',
                    onPressed: () {
                      context.read<HomeCubit>().continueTimer();
                    },
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