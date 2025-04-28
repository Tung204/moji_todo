import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Chuyển hướng sau 3 giây (hoặc tùy thời gian animation của GIF)
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Màu nền xanh
      body: Center(
        child: Image.asset(
          'images/splash_moji.gif', // Hiển thị GIF
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}