import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isLoggedOut;
  final String? logoutError;

  const SettingsState({
    this.isLoggedOut = false,
    this.logoutError,
  });

  SettingsState copyWith({
    bool? isLoggedOut,
    String? logoutError,
  }) {
    return SettingsState(
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      logoutError: logoutError ?? this.logoutError,
    );
  }

  @override
  List<Object?> get props => [isLoggedOut, logoutError];
}