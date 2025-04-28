import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FA), // Màu nền nhạt (từ theme của mày)
      appBar: AppBar(
        title: const Text(
          'Moji ToDo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00C4FF), // Màu xanh của logo
      ),
      body: const Center(
        child: Text(
          'Welcome to Moji ToDo! 🥳',
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFFFF69B4), // Màu hồng của chữ Moji
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}