import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      emit(state.copyWith(isLoggedOut: true));
    } catch (e) {
      // Xử lý lỗi đăng xuất nếu cần
      emit(state.copyWith(isLoggedOut: false));
    }
  }
}