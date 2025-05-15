import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/sizes.dart';

class TimerModeMenu extends StatelessWidget {
  const TimerModeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.timerSeconds != current.timerSeconds ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        final isEditable = (!state.isTimerRunning && !state.isPaused) ||
            (!state.isCountingUp && state.timerSeconds <= 0);

        return Tooltip(
          message: isEditable ? 'Chỉnh Timer Mode' : 'Dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode',
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.hourglass_empty,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    size: AppSizes.iconSize,
                  ),
                  onPressed: () {
                    print('Timer Mode button pressed: isEditable=$isEditable');
                    if (isEditable) {
                      _showTimerModeDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vui lòng dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode!'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  splashRadius: 24,
                ),
                Text(
                  'Timer Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: GoogleFonts.inter().fontFamily,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimerModeDialog(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => TimerModeDialog(homeCubit: homeCubit),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          ),
        );
      },
    );
  }
}

class TimerModeDialog extends StatefulWidget {
  final HomeCubit homeCubit;

  const TimerModeDialog({super.key, required this.homeCubit});

  @override
  State<TimerModeDialog> createState() => _TimerModeDialogState();
}

class _TimerModeDialogState extends State<TimerModeDialog> {
  late String _timerMode;
  late int _workDuration;
  late int _breakDuration;
  late bool _soundEnabled;
  late bool _autoSwitch;
  late String _notificationSound;
  late int _totalSessions;
  late TextEditingController _workController;
  late TextEditingController _breakController;
  late TextEditingController _sessionsController;

  @override
  void initState() {
    super.initState();
    final state = widget.homeCubit.state;
    _timerMode = state.timerMode;
    _workDuration = state.workDuration;
    _breakDuration = state.breakDuration;
    _soundEnabled = state.soundEnabled;
    _autoSwitch = state.autoSwitch;
    _notificationSound = state.notificationSound;
    _totalSessions = state.totalSessions;
    _workController = TextEditingController(text: _workDuration.toString());
    _breakController = TextEditingController(text: _breakDuration.toString());
    _sessionsController = TextEditingController(text: _totalSessions.toString());
  }

  @override
  void dispose() {
    _workController.dispose();
    _breakController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Timer Mode',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: GoogleFonts.inter().fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            SizedBox(
              height: 500,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: DropdownButtonFormField<String>(
                            value: _timerMode,
                            decoration: _inputDecoration(label: 'Timer Mode', hint: 'Chọn chế độ thời gian làm việc và nghỉ.'),
                            items: const [
                              DropdownMenuItem(value: '25:00 - 00:00', child: Text('25:00 - 00:00')),
                              DropdownMenuItem(value: '00:00 - 0∞', child: Text('00:00 - 0∞')),
                              DropdownMenuItem(value: 'Tùy chỉnh', child: Text('Tùy chỉnh')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _timerMode = value ?? '25:00 - 00:00';
                                if (_timerMode == '25:00 - 00:00') {
                                  _workDuration = 25;
                                  _breakDuration = 5;
                                  _workController.text = '25';
                                  _breakController.text = '5';
                                } else if (_timerMode == '00:00 - 0∞') {
                                  _workDuration = 0;
                                  _breakDuration = 0;
                                  _workController.text = '0';
                                  _breakController.text = '0';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing),
                      if (_timerMode == 'Tùy chỉnh') ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: TextField(
                              controller: _workController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecoration(
                                label: 'Thời gian làm việc (phút)',
                                hint: 'Nhập thời gian làm việc.',
                                icon: Icons.timer,
                              ),
                              onSubmitted: _validateWorkDuration,
                              onChanged: (value) {
                                if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 480) {
                                  _workDuration = parsed;
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: TextField(
                              controller: _breakController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecoration(
                                label: 'Thời gian nghỉ (phút)',
                                hint: 'Nhập thời gian nghỉ.',
                                icon: Icons.timer,
                              ),
                              onSubmitted: _validateBreakDuration,
                              onChanged: (value) {
                                if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 60) {
                                  _breakDuration = parsed;
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing),
                      ],
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: TextField(
                            controller: _sessionsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDecoration(
                              label: 'Số phiên',
                              hint: 'Nhập số phiên Pomodoro.',
                              icon: Icons.repeat,
                            ),
                            onSubmitted: _validateSessions,
                            onChanged: (value) {
                              if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 10) {
                                _totalSessions = parsed;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              'Âm thanh',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: GoogleFonts.inter().fontFamily,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            subtitle: Text(
                              'Bật âm thanh thông báo khi kết thúc phiên.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: GoogleFonts.inter().fontFamily,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                  ),
                            ),
                            value: _soundEnabled,
                            onChanged: (value) {
                              setState(() {
                                _soundEnabled = value ?? true;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      if (_soundEnabled) ...[
                        const SizedBox(height: AppSizes.spacing),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding
```

### Phân tích và giải pháp hợp nhất
Để giải quyết xung đột Git trong `TimerModeMenu`, tôi sẽ hợp nhất các thay đổi từ cả hai nhánh, ưu tiên hỗ trợ Dark Mode nhất quán với `Theme.of(context)` và giữ các tính năng tốt từ `tinvo` như gradient, font `GoogleFonts.inter`, và validation chặt chẽ. Dưới đây là kế hoạch hợp nhất:

#### 1. Phần chính của widget (`TimerModeMenu`)
- **Ưu tiên nhánh `master`**: Sử dụng `IconButton` với `Opacity` để giữ hiệu ứng mờ khi không chỉnh sửa được, đảm bảo UX tốt hơn so với `GestureDetector` trong `tinvo`.
- **Kết hợp `GoogleFonts.inter` từ `tinvo`**: Áp dụng font này vào `Theme.of(context).textTheme.bodyMedium` để giữ thẩm mỹ.
- **Sử dụng `Icons.hourglass_empty` từ `master`**: Biểu tượng này đủ rõ ràng và nhất quán với các widget khác (ls12, ls18).
- **Giữ phương thức `_showTimerModeDialog` từ `tinvo`**: Gọi `TimerModeDialog` để hiển thị dialog, vì cấu trúc `StatefulWidget` riêng tái sử dụng tốt hơn.

#### 2. Dialog chỉnh sửa Timer Mode
- **Sử dụng `TimerModeDialog` từ `tinvo`**: Giữ cấu trúc `StatefulWidget` riêng để tái sử dụng, nhưng thay `AppColors` bằng `Theme.of(context)`.
- **Thêm gradient từ `tinvo`**: Sử dụng `Theme.of(context).colorScheme.primary` và `secondary` thay vì `AppColors.backgroundGradientStart` và `End`.
- **Kết hợp validation từ `tinvo`**: Giữ `inputFormatters` và `onSubmitted` để cải thiện UX khi nhập số.
- **Sử dụng `Theme.of(context)` từ `master`**: Áp dụng `Theme.of(context).textTheme`, `Theme.of(context).colorScheme` cho các thành phần (`Text`, `DropdownButtonFormField`, `TextField`, `CheckboxListTile`, `CustomButton`).
- **Giữ spacing từ `master`**: Sử dụng `AppSizes.spacing` thay vì `AppSizes.spacing / 2` để nhất quán với các dialog khác (ls12, ls14, ls15, ls18).
- **Loại bỏ `Scaffold` trong `TimerModeDialog`**: `Dialog` không cần `Scaffold`, vì nó đã được xử lý trong `showGeneralDialog`.

### Mã hợp nhất
Dưới đây là mã hợp nhất cho `timer_mode_menu.dart`, giải quyết xung đột và đảm bảo hỗ trợ Dark Mode:

**lib/features/home/presentation/timer_mode_menu.dart**:
```dart
<xaiArtifact artifact_id="1565a652-8238-4d5f-8ab6-d5d7c1ab2d5d" artifact_version_id="37f53513-561c-47fb-8b8e-1016096c006f" title="timer_mode_menu.dart" contentType="text/dart">
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/sizes.dart';

class TimerModeMenu extends StatelessWidget {
  const TimerModeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.timerSeconds != current.timerSeconds ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        final isEditable = (!state.isTimerRunning && !state.isPaused) ||
            (!state.isCountingUp && state.timerSeconds <= 0);

        return Tooltip(
          message: isEditable ? 'Chỉnh Timer Mode' : 'Dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode',
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.hourglass_empty,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    size: AppSizes.iconSize,
                  ),
                  onPressed: () {
                    print('Timer Mode button pressed: isEditable=$isEditable');
                    if (isEditable) {
                      _showTimerModeDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vui lòng dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode!'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  splashRadius: 24,
                ),
                Text(
                  'Timer Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: GoogleFonts.inter().fontFamily,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimerModeDialog(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => TimerModeDialog(homeCubit: homeCubit),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          ),
        );
      },
    );
  }
}

class TimerModeDialog extends StatefulWidget {
  final HomeCubit homeCubit;

  const TimerModeDialog({super.key, required this.homeCubit});

  @override
  State<TimerModeDialog> createState() => _TimerModeDialogState();
}

class _TimerModeDialogState extends State<TimerModeDialog> {
  late String _timerMode;
  late int _workDuration;
  late int _breakDuration;
  late bool _soundEnabled;
  late bool _autoSwitch;
  late String _notificationSound;
  late int _totalSessions;
  late TextEditingController _workController;
  late TextEditingController _breakController;
  late TextEditingController _sessionsController;

  @override
  void initState() {
    super.initState();
    final state = widget.homeCubit.state;
    _timerMode = state.timerMode;
    _workDuration = state.workDuration;
    _breakDuration = state.breakDuration;
    _soundEnabled = state.soundEnabled;
    _autoSwitch = state.autoSwitch;
    _notificationSound = state.notificationSound;
    _totalSessions = state.totalSessions;
    _workController = TextEditingController(text: _workDuration.toString());
    _breakController = TextEditingController(text: _breakDuration.toString());
    _sessionsController = TextEditingController(text: _totalSessions.toString());
  }

  @override
  void dispose() {
    _workController.dispose();
    _breakController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Timer Mode',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: GoogleFonts.inter().fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            SizedBox(
              height: 500,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: DropdownButtonFormField<String>(
                            value: _timerMode,
                            decoration: _inputDecoration(
                              label: 'Timer Mode',
                              hint: 'Chọn chế độ thời gian làm việc và nghỉ.',
                            ),
                            items: const [
                              DropdownMenuItem(value: '25:00 - 00:00', child: Text('25:00 - 00:00')),
                              DropdownMenuItem(value: '00:00 - 0∞', child: Text('00:00 - 0∞')),
                              DropdownMenuItem(value: 'Tùy chỉnh', child: Text('Tùy chỉnh')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _timerMode = value ?? '25:00 - 00:00';
                                if (_timerMode == '25:00 - 00:00') {
                                  _workDuration = 25;
                                  _breakDuration = 5;
                                  _workController.text = '25';
                                  _breakController.text = '5';
                                } else if (_timerMode == '00:00 - 0∞') {
                                  _workDuration = 0;
                                  _breakDuration = 0;
                                  _workController.text = '0';
                                  _breakController.text = '0';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing),
                      if (_timerMode == 'Tùy chỉnh') ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: TextField(
                              controller: _workController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecoration(
                                label: 'Thời gian làm việc (phút)',
                                hint: 'Nhập thời gian làm việc.',
                                icon: Icons.timer,
                              ),
                              onSubmitted: _validateWorkDuration,
                              onChanged: (value) {
                                if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 480) {
                                  _workDuration = parsed;
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: TextField(
                              controller: _breakController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecoration(
                                label: 'Thời gian nghỉ (phút)',
                                hint: 'Nhập thời gian nghỉ.',
                                icon: Icons.timer,
                              ),
                              onSubmitted: _validateBreakDuration,
                              onChanged: (value) {
                                if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 60) {
                                  _breakDuration = parsed;
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing),
                      ],
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: TextField(
                            controller: _sessionsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDecoration(
                              label: 'Số phiên',
                              hint: 'Nhập số phiên Pomodoro.',
                              icon: Icons.repeat,
                            ),
                            onSubmitted: _validateSessions,
                            onChanged: (value) {
                              if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 10) {
                                _totalSessions = parsed;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              'Âm thanh',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: GoogleFonts.inter().fontFamily,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            subtitle: Text(
                              'Bật âm thanh thông báo khi kết thúc phiên.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: GoogleFonts.inter().fontFamily,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                  ),
                            ),
                            value: _soundEnabled,
                            onChanged: (value) {
                              setState(() {
                                _soundEnabled = value ?? true;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      if (_soundEnabled) ...[
                        const SizedBox(height: AppSizes.spacing),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.cardPadding),
                            child: DropdownButtonFormField<String>(
                              value: _notificationSound,
                              decoration: _inputDecoration(
                                label: 'Âm thanh thông báo',
                                hint: 'Chọn âm thanh thông báo.',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'bell', child: Text('Bell')),
                                DropdownMenuItem(value: 'chime', child: Text('Chime')),
                                DropdownMenuItem(value: 'alarm', child: Text('Alarm')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _notificationSound = value ?? 'bell';
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.spacing),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.cardPadding),
                          child: CheckboxListTile(
                            title: Text(
                              'Tự động chuyển',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: GoogleFonts.inter().fontFamily,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            subtitle: Text(
                              'Tự động chuyển giữa làm việc và nghỉ.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: GoogleFonts.inter().fontFamily,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                  ),
                            ),
                            value: _autoSwitch,
                            onChanged: (value) {
                              setState(() {
                                _autoSwitch = value ?? false;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(
                    label: 'Hủy',
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    textColor: Theme.of(context).colorScheme.onError,
                    borderRadius: AppSizes.borderRadius,
                  ),
                  CustomButton(
                    label: 'OK',
                    onPressed: _saveSettings,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: AppSizes.borderRadius,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
      helperText: hint,
      helperStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: GoogleFonts.inter().fontFamily,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            )
          : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  void _validateWorkDuration(String value) {
    final parsed = int.tryParse(value);
    setState(() {
      if (parsed == null || parsed < 1 || parsed > 480) {
        _workDuration = 25;
        _workController.text = '25';
      } else {
        _workDuration = parsed;
      }
    });
  }

  void _validateBreakDuration(String value) {
    final parsed = int.tryParse(value);
    setState(() {
      if (parsed == null || parsed < 1 || parsed > 60) {
        _breakDuration = 5;
        _breakController.text = '5';
      } else {
        _breakDuration = parsed;
      }
    });
  }

  void _validateSessions(String value) {
    final parsed = int.tryParse(value);
    setState(() {
      if (parsed == null || parsed < 1 || parsed > 10) {
        _totalSessions = 4;
        _sessionsController.text = '4';
      } else {
        _totalSessions = parsed;
      }
    });
  }

  void _saveSettings() {
    if (_workController.text.isEmpty || _workDuration < 1 || _workDuration > 480) {
      _workDuration = 25;
    }
    if (_breakController.text.isEmpty || _breakDuration < 1 || _breakDuration > 60) {
      _breakDuration = 5;
    }
    if (_sessionsController.text.isEmpty || _totalSessions < 1 || _totalSessions > 10) {
      _totalSessions = 4;
    }
    widget.homeCubit.updateTimerMode(
      timerMode: _timerMode,
      workDuration: _workDuration,
      breakDuration: _breakDuration,
      soundEnabled: _soundEnabled,
      autoSwitch: _autoSwitch,
      notificationSound: _notificationSound,
      totalSessions: _totalSessions,
    );
    Navigator.pop(context);
  }
}