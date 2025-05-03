import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isLoggedOut;
  final String? logoutError;
  final int syncInterval; // Khoảng thời gian đồng bộ (giờ)

  const SettingsState({
    this.isLoggedOut = false,
    this.logoutError,
    this.syncInterval = 6, // Mặc định 6h
  });

  SettingsState copyWith({
    bool? isLoggedOut,
    String? logoutError,
    int? syncInterval,
  }) {
    return SettingsState(
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      logoutError: logoutError ?? this.logoutError,
      syncInterval: syncInterval ?? this.syncInterval,
    );
  }

  @override
  List<Object?> get props => [isLoggedOut, logoutError];
}