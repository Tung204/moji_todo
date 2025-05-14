import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/strings.dart';

// Widget chính cho Timer Mode Menu
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

        return GestureDetector(
          onTap: () => isEditable ? _showTimerModeDialog(context) : _showErrorSnackBar(context),
          child: Tooltip(
            message: isEditable
                ? 'Chỉnh Timer Mode'
                : 'Dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode',
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    color: isEditable ? AppColors.primary : AppColors.textDisabled,
                    size: AppSizes.iconSize,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Timer Mode',
                    style: GoogleFonts.inter(
                      color: isEditable ? AppColors.primary : AppColors.textDisabled,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Hiển thị SnackBar khi không thể chỉnh sửa
  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vui lòng dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode!'),
        backgroundColor: AppColors.snackbarError,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Hiển thị dialog chỉnh sửa Timer Mode
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

// Widget cho Dialog chỉnh sửa Timer Mode
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
        ),
        elevation: 10,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.backgroundGradientStart,
                AppColors.backgroundGradientEnd,
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
            children: [_buildTitle(), _buildForm(), _buildButtons()],
          ),
        ),
      ),
    );
  }

  // Widget tiêu đề
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(
        AppStrings.timerModeTitle,
        style: GoogleFonts.inter(
          fontSize: AppSizes.titleFontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // Widget form nhập liệu
  Widget _buildForm() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 350),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTimerModeDropdown(),
            if (_timerMode == 'Tùy chỉnh') ...[
              const SizedBox(height: AppSizes.spacing / 2),
              _buildWorkDurationField(),
              const SizedBox(height: AppSizes.spacing / 2),
              _buildBreakDurationField(),
            ],
            const SizedBox(height: AppSizes.spacing / 2),
            _buildSessionsField(),
            const SizedBox(height: AppSizes.spacing / 2),
            _buildSoundCheckbox(),
            if (_soundEnabled) ...[
              const SizedBox(height: AppSizes.spacing / 2),
              _buildNotificationSoundDropdown(),
            ],
            const SizedBox(height: AppSizes.spacing / 2),
            _buildAutoSwitchCheckbox(),
          ],
        ),
      ),
    );
  }

  // Dropdown chọn Timer Mode
  Widget _buildTimerModeDropdown() {
    return _buildCard(
      child: DropdownButtonFormField<String>(
        value: _timerMode,
        decoration: _inputDecoration(label: AppStrings.timerModeLabel),
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
    );
  }

  // TextField thời gian làm việc
  Widget _buildWorkDurationField() {
    return _buildCard(
      child: TextField(
        controller: _workController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _inputDecoration(
          label: AppStrings.workDurationLabel,
          hint: AppStrings.workDurationHelper,
          icon: Icons.timer,
        ),
        onSubmitted: (value) => _validateWorkDuration(value),
        onChanged: (value) {
          if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 480) {
            _workDuration = parsed;
          }
        },
      ),
    );
  }

  // TextField thời gian nghỉ
  Widget _buildBreakDurationField() {
    return _buildCard(
      child: TextField(
        controller: _breakController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _inputDecoration(
          label: AppStrings.breakDurationLabel,
          hint: AppStrings.breakDurationHelper,
          icon: Icons.timer,
        ),
        onSubmitted: (value) => _validateBreakDuration(value),
        onChanged: (value) {
          if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 60) {
            _breakDuration = parsed;
          }
        },
      ),
    );
  }

  // TextField số phiên
  Widget _buildSessionsField() {
    return _buildCard(
      child: TextField(
        controller: _sessionsController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _inputDecoration(
          label: AppStrings.sessionsLabel,
          hint: AppStrings.sessionsHelper,
          icon: Icons.repeat,
        ),
        onSubmitted: (value) => _validateSessions(value),
        onChanged: (value) {
          if (int.tryParse(value) case int parsed when parsed >= 1 && parsed <= 10) {
            _totalSessions = parsed;
          }
        },
      ),
    );
  }

  // Checkbox bật/tắt âm thanh
  Widget _buildSoundCheckbox() {
    return _buildCard(
      child: CheckboxListTile(
        title: Text(
          AppStrings.soundLabel,
          style: GoogleFonts.inter(
            fontSize: AppSizes.labelFontSize - 2,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          AppStrings.soundHelper,
          style: GoogleFonts.inter(
            fontSize: AppSizes.helperFontSize,
            color: AppColors.textSecondary,
          ),
        ),
        value: _soundEnabled,
        onChanged: (value) => setState(() => _soundEnabled = value ?? true),
        activeColor: AppColors.primary,
        checkColor: Colors.white,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // Dropdown chọn âm thanh thông báo
  Widget _buildNotificationSoundDropdown() {
    return _buildCard(
      child: DropdownButtonFormField<String>(
        value: _notificationSound,
        decoration: _inputDecoration(label: AppStrings.notificationSoundLabel),
        items: const [
          DropdownMenuItem(value: 'bell', child: Text('Bell')),
          DropdownMenuItem(value: 'chime', child: Text('Chime')),
          DropdownMenuItem(value: 'alarm', child: Text('Alarm')),
        ],
        onChanged: (value) => setState(() => _notificationSound = value ?? 'bell'),
      ),
    );
  }

  // Checkbox tự động chuyển đổi
  Widget _buildAutoSwitchCheckbox() {
    return _buildCard(
      child: CheckboxListTile(
        title: Text(
          AppStrings.autoSwitchLabel,
          style: GoogleFonts.inter(
            fontSize: AppSizes.labelFontSize - 2,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          AppStrings.autoSwitchHelper,
          style: GoogleFonts.inter(
            fontSize: AppSizes.helperFontSize,
            color: AppColors.textSecondary,
          ),
        ),
        value: _autoSwitch,
        onChanged: (value) => setState(() => _autoSwitch = value ?? false),
        activeColor: AppColors.primary,
        checkColor: Colors.white,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // Nút Cancel và OK
  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CustomButton(
            label: AppStrings.cancel,
            onPressed: () => Navigator.pop(context),
            backgroundColor: AppColors.cancelButton,
            textColor: AppColors.textPrimary,
            borderRadius: 12,
          ),
          CustomButton(
            label: AppStrings.ok,
            onPressed: _saveSettings,
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }

  // InputDecoration chung
  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        fontSize: AppSizes.labelFontSize - 2,
        color: AppColors.textPrimary,
      ),
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: AppSizes.helperFontSize,
        color: AppColors.textDisabled,
      ),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textDisabled) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Card wrapper
  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  // Validate thời gian làm việc
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

  // Validate thời gian nghỉ
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

  // Validate số phiên
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

  // Lưu cài đặt
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