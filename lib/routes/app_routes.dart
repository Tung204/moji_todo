import 'package:flutter/material.dart';
import '../features/ai_chat/presentation/ai_chat_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/tasks/presentation/task_manage_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

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
  static const String profile = '/profile';
  static const String pomodoroPreferences = '/pomodoro-preferences';
  static const String dateTime = '/date-time';
  static const String notifications = '/notifications';
  static const String accountSecurity = '/account-security';
  static const String appAppearance = '/app-appearance';
  static const String helpSupport = '/help-support';
  static const String aiChat = '/ai-chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.home:
      case AppRoutes.pomodoro:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case AppRoutes.tasks:
        return MaterialPageRoute(builder: (_) => const TaskManageScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case aiChat:
        return MaterialPageRoute(builder: (_) => const AIChatScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('My Profile Screen')),
          ),
        );
      case AppRoutes.pomodoroPreferences:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Pomodoro Preferences Screen')),
          ),
        );
      case AppRoutes.dateTime:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Date & Time Screen')),
          ),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Notifications Screen')),
          ),
        );
      case AppRoutes.accountSecurity:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Account & Security Screen')),
          ),
        );
      case AppRoutes.appAppearance:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('App Appearance Screen')),
          ),
        );
      case AppRoutes.helpSupport:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Help & Support Screen')),
          ),
        );
      case AppRoutes.calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());
      case AppRoutes.report:
        return MaterialPageRoute(builder: (_) => const ReportScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}