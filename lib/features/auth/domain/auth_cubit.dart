// auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(AuthInitial());

  // Đăng nhập bằng Google
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await _repository.signInWithGoogle();
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Đăng nhập bằng email và mật khẩu
  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      await _repository.signInWithEmail(email, password);
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}