import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';

class TimerModeMenu extends StatelessWidget {
  const TimerModeMenu({super.key});

  void _showTimerModeMenu(BuildContext context) {
    String timerMode = context.read<HomeCubit>().state.timerMode;
    int workDuration = context.read<HomeCubit>().state.workDuration;
    int breakDuration = context.read<HomeCubit>().state.breakDuration;
    bool soundEnabled = context.read<HomeCubit>().state.soundEnabled;
    bool autoSwitch = context.read<HomeCubit>().state.autoSwitch;
    String notificationSound = context.read<HomeCubit>().state.notificationSound;
    int totalSessions = context.read<HomeCubit>().state.totalSessions;

    TextEditingController workController = TextEditingController(text: workDuration.toString());
    TextEditingController breakController = TextEditingController(text: breakDuration.toString());
    TextEditingController sessionsController = TextEditingController(text: totalSessions.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              title: const Text(
                'Timer Mode Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: timerMode,
                      decoration: InputDecoration(
                        labelText: 'Chế độ timer',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Pomodoro', child: Text('Pomodoro (1/5)')),
                        DropdownMenuItem(value: '50/10', child: Text('50/10')),
                        DropdownMenuItem(value: 'Custom', child: Text('Tùy chỉnh')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          timerMode = value ?? 'Pomodoro';
                          if (timerMode == 'Pomodoro') {
                            workDuration = 1;
                            breakDuration = 5;
                            workController.text = '1';
                            breakController.text = '5';
                          } else if (timerMode == '50/10') {
                            workDuration = 50;
                            breakDuration = 10;
                            workController.text = '50';
                            breakController.text = '10';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (timerMode == 'Custom') ...[
                      TextField(
                        controller: workController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Thời gian làm việc (phút)',
                          labelStyle: const TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        onChanged: (value) {
                          workDuration = int.tryParse(value) ?? 1;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: breakController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Thời gian nghỉ (phút)',
                          labelStyle: const TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        onChanged: (value) {
                          breakDuration = int.tryParse(value) ?? 5;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: sessionsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số phiên Pomodoro',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                      onChanged: (value) {
                        totalSessions = int.tryParse(value) ?? 4;
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text(
                        'Âm thanh thông báo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      value: soundEnabled,
                      onChanged: (value) {
                        setState(() {
                          soundEnabled = value ?? true;
                        });
                      },
                      activeColor: const Color(0xFFFF5733),
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    if (soundEnabled) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: notificationSound,
                        decoration: InputDecoration(
                          labelText: 'Âm thanh thông báo',
                          labelStyle: const TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'bell', child: Text('bell')),
                          DropdownMenuItem(value: 'chime', child: Text('chime')),
                          DropdownMenuItem(value: 'alarm', child: Text('alarm')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            notificationSound = value ?? 'bell';
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text(
                        'Tự động chuyển phiên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      value: autoSwitch,
                      onChanged: (value) {
                        setState(() {
                          autoSwitch = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFFFF5733),
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<HomeCubit>().updateTimerMode(
                      timerMode: timerMode,
                      workDuration: workDuration,
                      breakDuration: breakDuration,
                      soundEnabled: soundEnabled,
                      autoSwitch: autoSwitch,
                      notificationSound: notificationSound,
                      totalSessions: totalSessions,
                    );
                    Navigator.pop(dialogContext);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5733),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Column(
          children: [
            IconButton(
              icon: const Icon(
                Icons.hourglass_empty,
                color: Colors.grey,
              ),
              onPressed: () {
                if (state.isTimerRunning) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể chỉnh Timer Mode khi timer đang chạy!'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  _showTimerModeMenu(context);
                }
              },
            ),
            const Text(
              'Timer Mode',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}