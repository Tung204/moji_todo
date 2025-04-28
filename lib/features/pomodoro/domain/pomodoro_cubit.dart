import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/pomodoro_repository.dart';

part 'pomodoro_state.dart';

class PomodoroCubit extends Cubit<PomodoroState> {
  final PomodoroRepository repository;
  PomodoroCubit(this.repository) : super(const PomodoroState());

  void startTimer() {
    if (!state.isRunning) {
      emit(state.copyWith(isRunning: true));
      repository.startTimer(
        duration: _getCurrentDuration(),
        onTick: (secondsLeft) => emit(state.copyWith(secondsLeft: secondsLeft)),
        onComplete: () {
          emit(state.copyWith(
            isRunning: false,
            secondsLeft: _getCurrentDuration(),
            cycleCount: state.cycleCount + 1,
            sessionType: _getNextSessionType(),
          ));
          repository.showNotification(
            title: 'Pomodoro',
            body: '${state.sessionType} completed!',
          );
        },
      );
    }
  }

  void pauseTimer() {
    if (state.isRunning) {
      repository.pauseTimer();
      emit(state.copyWith(isRunning: false));
    }
  }

  void resetTimer() {
    repository.resetTimer();
    emit(const PomodoroState());
  }

  void updateDurations({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
  }) {
    emit(state.copyWith(
      workDuration: workDuration ?? state.workDuration,
      shortBreakDuration: shortBreakDuration ?? state.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? state.longBreakDuration,
      secondsLeft: _getCurrentDuration(),
    ));
  }

  int _getCurrentDuration() {
    switch (state.sessionType) {
      case SessionType.work:
        return state.workDuration * 60;
      case SessionType.shortBreak:
        return state.shortBreakDuration * 60;
      case SessionType.longBreak:
        return state.longBreakDuration * 60;
    }
  }

  SessionType _getNextSessionType() {
    if (state.sessionType == SessionType.work) {
      return (state.cycleCount + 1) % 4 == 0
          ? SessionType.longBreak
          : SessionType.shortBreak;
    }
    return SessionType.work;
  }
}