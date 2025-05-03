import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isLoggedOut;

  const SettingsState({this.isLoggedOut = false});

  SettingsState copyWith({bool? isLoggedOut}) {
    return SettingsState(
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
    );
  }

  @override
  List<Object?> get props => [isLoggedOut];
}