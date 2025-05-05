import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../routes/app_routes.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController _usernameController;
  String? _photoUrl;
  bool _isEditingUsername = false;
  bool _isGoogleAccount = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _usernameController = TextEditingController(text: user?.displayName ?? 'User');
    _photoUrl = user?.photoURL; // Không sử dụng placeholder nữa
    _isGoogleAccount = user?.providerData.any((provider) => provider.providerId == 'google.com') ?? false;
  }

  Future<void> _updateUsername() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(_usernameController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditingUsername = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating username: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        await _auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending password reset email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        // Tải ảnh lên Firebase Storage
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_avatars')
            .child('${user.uid}.jpg');

        final file = File(pickedFile.path);
        await storageRef.putFile(file);

        // Lấy URL của ảnh
        final downloadUrl = await storageRef.getDownloadURL();

        // Cập nhật URL ảnh vào Firebase Auth
        await user.updatePhotoURL(downloadUrl);

        setState(() {
          _photoUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    backgroundColor: Colors.grey[200],
                    child: _photoUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.blue),
                      onPressed: _pickAvatar,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Username
            ListTile(
              title: _isEditingUsername
                  ? TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              )
                  : Text(
                'Username: ${_usernameController.text}',
                style: const TextStyle(fontSize: 16),
              ),
              trailing: IconButton(
                icon: Icon(_isEditingUsername ? Icons.save : Icons.edit),
                onPressed: () {
                  if (_isEditingUsername) {
                    _updateUsername();
                  } else {
                    setState(() {
                      _isEditingUsername = true;
                    });
                  }
                },
              ),
            ),
            // Account Type
            ListTile(
              title: Text(
                'Account: ${_isGoogleAccount ? "Google" : "Email"}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            // Change Password (chỉ hiển thị nếu là tài khoản Email)
            if (!_isGoogleAccount)
              ListTile(
                title: const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                onTap: _changePassword,
              ),
            // Sign Out
            ListTile(
              title: const Text(
                'Sign Out',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.black54),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Confirm Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _signOut();
                          },
                          child: const Text(
                            'Yes',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}