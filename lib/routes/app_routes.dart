import 'package:flutter/material.dart';
import 'package:moji_todo/features/splash/presentation/splash_screen.dart';
import 'package:moji_todo/features/home/presentation/home_screen.dart';
import 'package:moji_todo/features/auth/presentation/login_screen.dart';
import 'package:moji_todo/features/auth/presentation/register_screen.dart';
import 'package:moji_todo/features/auth/presentation/forgot_password_screen.dart';
import 'package:moji_todo/features/pomodoro/presentation/pomodoro_screen.dart';
import 'package:moji_todo/features/tasks/presentation/task_manage_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String pomodoro = '/pomodoro';
  static const String tasks = '/tasks';
  static const String calendar = '/calendar';
  static const String report = '/report';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      // case pomodoro:
      //   return MaterialPageRoute(builder: (_) => const PomodoroScreen());
      case tasks:
        return MaterialPageRoute(builder: (_) => const TaskManageScreen());
      case calendar:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Calendar Screen')),
          ),
        );
      case report:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Report Screen')),
          ),
        );
      // case settings:
      //   return MaterialPageRoute(
      //     builder: (_) => const Scaffold(
      //       body: Center(child: Text('Settings Screen')),
      //     ),
      //   );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}