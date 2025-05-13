import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/home_cubit.dart';
import '../../domain/home_state.dart';
import '../home_screen_state_manager.dart';
import '../../../../core/widgets/custom_button.dart';
import 'package:flutter/services.dart';

class PomodoroTimer extends StatefulWidget {
  final HomeScreenStateManager? stateManager;

  const PomodoroTimer({super.key, this.stateManager});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.0;
  static const MethodChannel _notificationChannel = MethodChannel('com.example.moji_todo/notification');

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
      buildWhen: (previous, current) =>
      previous.timerSeconds != current.timerSeconds ||
          previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.isWorkSession != current.isWorkSession ||
          previous.workDuration != current.workDuration ||
          previous.breakDuration != current.breakDuration ||
          previous.currentSession != current.currentSession ||
          previous.totalSessions != current.totalSessions ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        final homeCubit = context.read<HomeCubit>();

        final minutes = (state.timerSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (state.timerSeconds % 60).toString().padLeft(2, '0');
        final totalDuration = (state.isWorkSession ? state.workDuration : state.breakDuration) * 60;
        final targetProgress = state.isCountingUp ? 0.0 : (totalDuration > 0 ? state.timerSeconds / totalDuration : 0.0);

        print('PomodoroTimer rebuild: timerSeconds=${state.timerSeconds}, isCountingUp=${state.isCountingUp}, targetProgress=$targetProgress');

        if (!state.isCountingUp && _currentProgress != targetProgress) {
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
              state.isCountingUp
                  ? 'Đếm lên'
                  : (state.isWorkSession ? 'Phiên làm việc' : 'Phiên nghỉ'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value: state.isCountingUp ? null : _progressAnimation.value,
                    strokeWidth: 20,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.isTimerRunning ? Colors.blue : Colors.red,
                    ),
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
                      state.isCountingUp
                          ? 'Counting Up'
                          : (state.currentSession == 0
                          ? 'No sessions'
                          : '${state.currentSession} of ${state.totalSessions} sessions'),
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
                label: state.isCountingUp
                    ? 'Start Counting Up'
                    : (state.isWorkSession ? 'Start to Focus' : 'Start Break'),
                onPressed: () {
                  widget.stateManager?.handleTimerAction('start');
                },
                backgroundColor: Colors.red,
                textColor: Colors.white,
                borderRadius: 20,
              ),
            if (state.isTimerRunning && !state.isPaused)
              CustomButton(
                label: 'Pause',
                onPressed: () {
                  widget.stateManager?.handleTimerAction('pause');
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
                      widget.stateManager?.handleTimerAction('stop');
                    },
                    backgroundColor: Colors.grey,
                    textColor: Colors.white,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    label: 'Continue',
                    onPressed: () {
                      widget.stateManager?.handleTimerAction('continue');
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