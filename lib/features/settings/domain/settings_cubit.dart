import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());
  Future<void> _loadSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final syncInterval = prefs.getInt('syncInterval') ?? 6; // Mặc định 6h
    emit(state.copyWith(syncInterval: syncInterval));
  }

  Future<void> setSyncInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('syncInterval', hours);
    emit(state.copyWith(syncInterval: hours));
  }
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      emit(state.copyWith(isLoggedOut: true, logoutError: null));
    } catch (e) {
      emit(state.copyWith(isLoggedOut: false, logoutError: e.toString()));
    }
  }
}