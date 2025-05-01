import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Khởi tạo video player
    _controller = VideoPlayerController.asset('images/splash_moji.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(false);
        // Chờ video chạy xong hoặc tối thiểu 3 giây trước khi chuyển hướng
        _waitAndNavigate();
      }).catchError((error) {
        // Nếu video lỗi, vẫn chờ 3 giây rồi chuyển hướng
        _waitAndNavigate();
      });
  }

  Future<void> _waitAndNavigate() async {
    // Chờ tối thiểu 3 giây và đảm bảo video chạy xong (nếu video dài hơn 3 giây)
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)), // Tối thiểu 3 giây
      // Chuyển duration của video thành một Future
      _controller.value.isInitialized
          ? Future.delayed(_controller.value.duration)
          : Future.value(), // Nếu không có video, bỏ qua
    ]);

    // Kiểm tra trạng thái đăng nhập
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      if (user != null) {
        // Đã đăng nhập -> vào HomeScreen
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // Chưa đăng nhập -> vào LoginScreen
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}