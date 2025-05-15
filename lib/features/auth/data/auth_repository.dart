// auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/firebase_service.dart';

class AuthRepository {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Đăng nhập bằng Google bị hủy');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _firebaseService.signInWithEmail(email, password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Không tìm thấy người dùng với email này');
        case 'wrong-password':
          throw Exception('Mật khẩu không đúng');
        case 'invalid-email':
          throw Exception('Email không hợp lệ');
        default:
          throw Exception('Lỗi đăng nhập: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập bằng email: $e');
    }
  }
}