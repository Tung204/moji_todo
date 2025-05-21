// auth_cubit.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

// Đảm bảo các đường dẫn import là chính xác với cấu trúc thư mục của bạn
import '../../../../core/services/backup_service.dart';
import '../../tasks/data/models/project_model.dart';
import '../../tasks/data/models/project_tag_repository.dart';
import '../../tasks/data/models/tag_model.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/data/task_repository.dart';
import '../data/auth_repository.dart';

part 'auth_state.dart'; // File này bạn đã tạo/cập nhật ở bước trước

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final BackupService _backupService;
  final ProjectTagRepository _projectTagRepository;
  final TaskRepository _taskRepository;
  final Box<Project> _projectBox;
  final Box<Tag> _tagBox;
  final Box<Task> _taskBox;
  final Box<DateTime> _syncInfoBox;
  final Box<dynamic> _appStatusBox; // Box để lưu 'lastModified_...'

  StreamSubscription<User?>? _authStateSubscription;

  AuthCubit(
      this._authRepository,
      this._backupService,
      this._projectTagRepository,
      this._taskRepository,
      this._projectBox,
      this._tagBox,
      this._taskBox,
      this._syncInfoBox,
      this._appStatusBox,
      ) : super(AuthInitial()) {
    _authStateSubscription = _authRepository.authStateChanges.listen((user) async {
      if (user == null) {
        if (state is! AuthUnauthenticated && state is! AuthInitial) {
          print('AuthCubit: User is null via authStateChanges. Clearing local data and emitting AuthUnauthenticated.');
          await _clearLocalUserData();
          emit(AuthUnauthenticated());
        } else if (state is AuthInitial) {
          emit(AuthUnauthenticated());
        }
      } else {
        if (state is AuthUnauthenticated || state is AuthInitial) {
          print('AuthCubit: User found via authStateChanges (${user.uid}). Processing authentication flow...');
          await _onUserAuthenticated(user);
        }
      }
    });
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  Future<void> _onUserAuthenticated(User user) async {
    if (state is AuthAuthenticated && (state as AuthAuthenticated).user.uid == user.uid) {
      return;
    }
    emit(AuthLoading(message: "Đang tải dữ liệu người dùng..."));
    try {
      await _backupService.restoreFromFirestore();
      await _createDefaultDataForCurrentUserIfEmpty(user.uid);
      emit(AuthAuthenticated(user));
    } catch (e) {
      print("Lỗi khi _onUserAuthenticated: ${e.toString()}");
      emit(AuthError("Lỗi khi tải dữ liệu người dùng: ${e.toString().replaceFirst("Exception: ", "")}"));
    }
  }

  Future<void> _createDefaultDataForCurrentUserIfEmpty(String userId) async {
    try {
      // Kiểm tra xem người dùng này đã có dữ liệu nào chưa sau khi restore
      // ProjectTagRepository và TaskRepository đã được cập nhật để lọc theo userId
      final userProjects = _projectTagRepository.getProjects();
      final userTags = _projectTagRepository.getTags();
      final userTasks = await _taskRepository.getTasks();

      bool needsDefaultProjects = userProjects.isEmpty;
      bool needsDefaultTags = userTags.isEmpty;
      bool needsDefaultTasks = userTasks.isEmpty;

      if (needsDefaultProjects) {
        print('AuthCubit: Tạo projects mẫu cho người dùng: $userId');
        final defaultProjects = [
          Project(name: 'Công việc', color: Colors.blue, userId: userId, iconCodePoint: Icons.work_outline_rounded.codePoint, iconFontFamily: Icons.work_outline_rounded.fontFamily),
          Project(name: 'Cá nhân', color: Colors.green, userId: userId, iconCodePoint: Icons.person_outline_rounded.codePoint, iconFontFamily: Icons.person_outline_rounded.fontFamily),
          Project(name: 'Học tập', color: Colors.orange, userId: userId, iconCodePoint: Icons.school_outlined.codePoint, iconFontFamily: Icons.school_outlined.fontFamily),
        ];
        for (var project in defaultProjects) {
          // addProject trong repository đã được sửa để tự gán userId nếu cần
          await _projectTagRepository.addProject(project.copyWith(userId: userId));
        }
      }

      if (needsDefaultTags) {
        print('AuthCubit: Tạo tags mẫu cho người dùng: $userId');
        final defaultTags = [
          Tag(name: 'Quan trọng', textColor: Colors.red.shade700, userId: userId),
          Tag(name: 'Ưu tiên', textColor: Colors.amber.shade700, userId: userId),
          Tag(name: 'Ý tưởng', textColor: Colors.lightBlue.shade600, userId: userId),
        ];
        for (var tag in defaultTags) {
          await _projectTagRepository.addTag(tag.copyWith(userId: userId));
        }
      }

      if (needsDefaultTasks && _projectTagRepository.getProjects().isNotEmpty) { // Kiểm tra lại project của user
        print('AuthCubit: Tạo task mẫu cho người dùng: $userId');
        final List<Project> currentUserProjects = _projectTagRepository.getProjects();
        if (currentUserProjects.isNotEmpty) {
          final sampleTask = Task(
            title: 'Chào mừng! Hoàn thành task đầu tiên của bạn.',
            dueDate: DateTime.now().add(const Duration(days: 1)),
            priority: 'Medium',
            userId: userId,
            projectId: currentUserProjects.first.id,
            createdAt: DateTime.now(),
            estimatedPomodoros: 1,
          );
          await _taskRepository.addTask(sampleTask.copyWith(userId: userId));
        }
      }
    } catch (e) {
      print("Lỗi khi tạo dữ liệu mẫu: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    if (state is AuthLoading) return;
    emit(AuthLoading(message: "Đang đăng nhập với Google..."));
    try {
      await _authRepository.signInWithGoogle();
      final user = _authRepository.currentUser;
      if (user != null) {
        await _onUserAuthenticated(user);
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError("Đăng nhập Google thất bại: ${e.toString().replaceFirst("Exception: ", "")}"));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (state is AuthLoading) return;
    emit(AuthLoading(message: "Đang đăng nhập..."));
    try {
      await _authRepository.signInWithEmail(email, password);
      final user = _authRepository.currentUser;
      if (user != null) {
        await _onUserAuthenticated(user);
      } else {
        emit(AuthError("Không thể lấy thông tin người dùng sau khi đăng nhập."));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    if (state is AuthLoading) return;
    emit(AuthLoading(message: "Đang đăng ký..."));
    try {
      await _authRepository.signUpWithEmail(email, password);
      final user = _authRepository.currentUser;
      if (user != null) {
        await _onUserAuthenticated(user);
      } else {
        emit(AuthError("Không thể lấy thông tin người dùng sau khi đăng ký."));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _clearLocalUserData() async {
    // Chỉ clear nếu các box đã được mở
    if (_taskBox.isOpen) await _taskBox.clear();
    if (_projectBox.isOpen) await _projectBox.clear();
    if (_tagBox.isOpen) await _tagBox.clear();
    if (_appStatusBox.isOpen) await _appStatusBox.clear();
    if (_syncInfoBox.isOpen) await _syncInfoBox.clear();
    print("AuthCubit: Đã clear tất cả dữ liệu người dùng cục bộ và thông tin sync/modification.");
  }

  Future<void> signOut({bool forceSignOut = false}) async {
    if (state is AuthLoading && !(state as AuthLoading).message!.contains("Đang kiểm tra dữ liệu...")) {
      return;
    }

    final user = _authRepository.currentUser;

    if (user == null && !forceSignOut) {
      if (state is! AuthUnauthenticated) {
        await _clearLocalUserData();
        emit(AuthUnauthenticated());
      }
      return;
    }

    emit(AuthLoading(message: "Đang kiểm tra dữ liệu..."));

    if (!forceSignOut && user != null) {
      bool needsSync = false;
      try {
        final DateTime? lastSyncTime = await _backupService.getLastBackupTime();
        // Đảm bảo box đã mở trước khi get
        final String? lastModifiedProjectsStr = _appStatusBox.isOpen ? _appStatusBox.get('lastModified_projects') : null;
        final String? lastModifiedTagsStr = _appStatusBox.isOpen ? _appStatusBox.get('lastModified_tags') : null;
        final String? lastModifiedTasksStr = _appStatusBox.isOpen ? _appStatusBox.get('lastModified_tasks') : null;

        if (lastSyncTime == null) {
          if ((_taskBox.isOpen && _taskBox.values.any((t) => t.userId == user.uid)) ||
              (_projectBox.isOpen && _projectBox.values.any((p) => p.userId == user.uid)) ||
              (_tagBox.isOpen && _tagBox.values.any((t) => t.userId == user.uid))) {
            needsSync = true;
          }
        } else {
          if (lastModifiedTasksStr != null && DateTime.tryParse(lastModifiedTasksStr)?.isAfter(lastSyncTime) == true) needsSync = true;
          if (!needsSync && lastModifiedProjectsStr != null && DateTime.tryParse(lastModifiedProjectsStr)?.isAfter(lastSyncTime) == true) needsSync = true;
          if (!needsSync && lastModifiedTagsStr != null && DateTime.tryParse(lastModifiedTagsStr)?.isAfter(lastSyncTime) == true) needsSync = true;
        }

        if (needsSync) {
          emit(AuthSyncRequiredBeforeLogout());
          return;
        }
      } catch (e) {
        print("Lỗi khi kiểm tra đồng bộ trước khi logout: $e");
      }
    }
    await _performActualSignOut();
  }

  Future<void> syncDataAndProceedWithSignOut() async {
    if (state is AuthLoading && (state as AuthLoading).message == "Đang đồng bộ và đăng xuất...") return;
    emit(AuthLoading(message: "Đang đồng bộ và đăng xuất..."));
    try {
      await _backupService.backupToFirestore();
      await _performActualSignOut();
    } catch (e) {
      print("Lỗi khi syncDataAndProceedWithSignOut: ${e.toString()}");
      final currentUser = _authRepository.currentUser;
      emit(AuthError("Lỗi đồng bộ: ${e.toString().replaceFirst("Exception: ", "")}. Bạn vẫn đang đăng nhập."));
      if (currentUser != null) {
        emit(AuthAuthenticated(currentUser));
      } else {
        await _performActualSignOut();
      }
    }
  }

  Future<void> signOutAnyway() async { // Đổi tên từ _performActualSignOut để UI có thể gọi
    await _performActualSignOut(calledFromSignOutAnyway: true);
  }

  Future<void> _performActualSignOut({bool calledFromSignOutAnyway = false}) async {
    if (state is AuthLoading && (state as AuthLoading).message == "Đang đăng xuất..." && !calledFromSignOutAnyway) return;
    emit(AuthLoading(message: "Đang đăng xuất..."));
    try {
      // Nếu _authStateSubscription đã xử lý (user thành null), nó sẽ gọi _clearLocalUserData và emit AuthUnauthenticated.
      // Gọi signOut() của Firebase sẽ trigger _authStateSubscription.
      await _authRepository.signOut();

      // Tuy nhiên, để đảm bảo clean up ngay lập tức và phát trạng thái nếu listener chưa kịp chạy hoặc có vấn đề.
      if (state is! AuthUnauthenticated) { // Chỉ clear và emit nếu chưa ở trạng thái unauthenticated
        await _clearLocalUserData();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print("Lỗi khi _performActualSignOut: ${e.toString()}");
      emit(AuthError("Lỗi khi đăng xuất: ${e.toString().replaceFirst("Exception: ", "")}"));
      await _clearLocalUserData(); // Vẫn cố gắng clear data
      emit(AuthUnauthenticated());
    }
  }
}