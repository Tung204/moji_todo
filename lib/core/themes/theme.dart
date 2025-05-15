import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF00C4FF),
    scaffoldBackgroundColor: const Color(0xFFE6F7FA),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFF69B4)),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.grey),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFFFF5733),
      textTheme: ButtonTextTheme.primary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF5733),
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
    ).copyWith(secondary: const Color(0xFFFF5733)),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color(0xFF00C4FF),
    scaffoldBackgroundColor: const Color(0xFF2A2A2A), // Xám đậm nhẹ thay vì đen
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFF69B4)),
      bodyMedium: TextStyle(color: Color(0xFFB0BEC5)), // Xám sáng nhẹ thay vì trắng
      titleLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold), // Trắng xám
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Color(0xFFB0BEC5)),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF3A3A3A), // Xám đậm hơn nền
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFFFF5733),
      textTheme: ButtonTextTheme.primary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF5733),
      foregroundColor: Color(0xFFE0E0E0),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFFFF5733),
      surface: const Color(0xFF3A3A3A), // Màu bề mặt nhẹ
      onSurface: const Color(0xFFB0BEC5), // Màu chữ trên bề mặt
    ),
  );
}