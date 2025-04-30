import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void selectTask(String? task) {
    emit(state.copyWith(selectedTask: task));
  }

  void startTimer() {
    emit(state.copyWith(isTimerRunning: true));
  }

  void stopTimer() {
    emit(state.copyWith(isTimerRunning: false));
  }

  void setTimerMinutes(int minutes) {
    emit(state.copyWith(timerMinutes: minutes));
  }
}