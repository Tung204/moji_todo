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
  late Animation<double> _progressAnimation; // Vẫn giữ late
  double _currentProgress = 0.0;
  Timer? _debounceTimer;
  bool _isActionLocked = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Khởi tạo _progressAnimation ngay lập tức với giá trị 0.0
    // Đây là thay đổi quan trọng để khắc phục LateInitializationError.
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    // Vẫn giữ lại postFrameCallback để cập nhật animation dựa trên trạng thái ban đầu của Cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Đảm bảo Cubit đã có trạng thái để truyền vào _updateProgressAnimation
      if (mounted) { // Kiểm tra widget còn mounted trước khi truy cập context
        _updateProgressAnimation(context.read<HomeCubit>().state);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _updateProgressAnimation(HomeState state) {
    final totalDuration = (state.isWorkSession ? state.workDuration : state.breakDuration) * 60;
    // Đảm bảo targetProgress không NaN hoặc vô cực nếu totalDuration là 0
    final targetProgress = state.isCountingUp ? 0.0 : (totalDuration > 0 ? state.timerSeconds / totalDuration : 0.0);

    // Log để kiểm tra giá trị targetProgress
    print('Updating progress animation: targetProgress=$targetProgress, currentProgress=$_currentProgress, isPaused=${state.isPaused}, isCountingUp=${state.isCountingUp}');


    // Chỉ cập nhật animation nếu không phải chế độ đếm lên, tiến độ thay đổi và không bị tạm dừng
    // Nếu targetProgress rất nhỏ (gần 0), có thể reset animation để tránh các lỗi nhỏ
    if (!state.isCountingUp && (targetProgress - _currentProgress).abs() > 0.001 && !state.isPaused) {
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
    } else if (state.isPaused && _progressController.isAnimating) {
      _progressController.stop();
    } else if (!state.isTimerRunning && !state.isPaused && _progressController.isAnimating) {
      _progressController.stop();
    } else if (!state.isTimerRunning && !state.isPaused && targetProgress == 0.0 && _currentProgress != 0.0) {
      // Khi timer dừng hoàn toàn và về 0, reset animation về 0
      _currentProgress = 0.0;
      _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeInOut,
        ),
      );
      _progressController.value = 0.0; // Đặt giá trị controller về 0
      _progressController.stop();
    }
  }


  void _debouncedAction(String action, {int? estimatedPomodoros}) {
    if (_isActionLocked) {
      print('Action locked, ignoring: $action');
      return;
    }

    _isActionLocked = true;
    print('Handling action: $action');
    widget.stateManager?.handleTimerAction(
      action,
      estimatedPomodoros: estimatedPomodoros,
    );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _isActionLocked = false;
      print('Action lock released');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
      previous.timerSeconds != current.timerSeconds ||
          previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.isWorkSession != current.isWorkSession ||
          previous.workDuration != current.workDuration ||
          previous.breakDuration != current.breakDuration ||
          previous.isCountingUp != current.isCountingUp,
      listener: (context, state) {
        _updateProgressAnimation(state);
      },
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
        final minutes = (state.timerSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (state.timerSeconds % 60).toString().padLeft(2, '0');

        print('PomodoroTimer rebuild: timerSeconds=${state.timerSeconds}, isRunning=${state.isTimerRunning}, isPaused=${state.isPaused}, isCountingUp=${state.isCountingUp}, isWorkSession=${state.isWorkSession}, currentSession=${state.currentSession}, totalSessions=${state.totalSessions}');

        String sessionStatusText;
        if (state.isCountingUp) {
          sessionStatusText = 'Counting Up';
        } else if (state.isTimerRunning || state.isPaused) {
          sessionStatusText = '${state.currentSession} of ${state.totalSessions} sessions';
        } else {
          if (state.selectedTask != null) {
            if (state.isWorkSession) {
              sessionStatusText = 'Ready for Work (Session ${state.currentSession + 1})';
            } else {
              sessionStatusText = 'Ready for Break';
            }
          } else {
            sessionStatusText = 'No session selected';
          }
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
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: state.isCountingUp ? null : _progressAnimation.value,
                        strokeWidth: 20,
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          state.isPaused
                              ? Theme.of(context).colorScheme.secondary
                              : state.isTimerRunning
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      sessionStatusText,
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