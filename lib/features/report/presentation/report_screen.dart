import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: const Center(
        child: Text('Report Screen'),
      ),
    );
  }
}