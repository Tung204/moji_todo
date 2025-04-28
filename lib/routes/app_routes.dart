import 'package:flutter/material.dart';
import 'package:moji_todo/features/splash/presentation/splash_screen.dart';
import 'package:moji_todo/features/home/presentation/home_screen.dart';
import 'package:moji_todo/features/auth/presentation/login_screen.dart';
import 'package:moji_todo/features/pomodoro/presentation/pomodoro_screen.dart';
import 'package:moji_todo/features/tasks/presentation/task_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String login = '/login';
  static const String pomodoro = '/pomodoro';
  static const String tasks = '/tasks';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      // case login:
      //   return MaterialPageRoute(builder: (_) => const LoginScreen());
      // case pomodoro:
      //   return MaterialPageRoute(builder: (_) => const PomodoroScreen());
      // case tasks:
      //   return MaterialPageRoute(builder: (_) => const TaskScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}