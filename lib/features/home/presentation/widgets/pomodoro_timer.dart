import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/home_cubit.dart';
import '../../domain/home_state.dart';
import '../home_screen_state_manager.dart';
import '../../../../core/widgets/custom_button.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
  Timer? _debounceTimer;
  bool _isActionLocked = false;

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
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedAction(String action) {
    if (_isActionLocked) {
      print('Action locked, ignoring: $action');
      return;
    }

    _isActionLocked = true;
    widget.stateManager?.handleTimerAction(action);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _isActionLocked = false;
    });
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.isTimerRunning
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes:$seconds',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.isCountingUp
                          ? 'Counting Up'
                          : (state.currentSession == 0
                          ? 'No sessions'
                          : '${state.currentSession} of ${state.totalSessions} sessions'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
                onPressed: () => _debouncedAction('start'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                textColor: Theme.of(context).colorScheme.onSecondary,
                borderRadius: 20,
              ),
            if (state.isTimerRunning && !state.isPaused)
              CustomButton(
                label: 'Pause',
                onPressed: () => _debouncedAction('pause'),
                backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                textColor: Theme.of(context).colorScheme.onSurface,
                borderRadius: 20,
              ),
            if (state.isPaused)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    label: 'Stop',
                    onPressed: () => _debouncedAction('stop'),
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    textColor: Theme.of(context).colorScheme.onSurface,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    label: 'Continue',
                    onPressed: () => _debouncedAction('continue'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    textColor: Theme.of(context).colorScheme.onSecondary,
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