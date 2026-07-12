import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection.dart';
import '../../../../auth/domain/repositories/auth_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _currentController.text.isNotEmpty &&
      _newController.text.length >= 6 &&
      _newController.text == _confirmController.text &&
      _newController.text != _currentController.text;

  String? get _footerError {
    if (_newController.text.isNotEmpty && _newController.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (_confirmController.text.isNotEmpty && _newController.text != _confirmController.text) {
      return 'Passwords do not match.';
    }
    if (_newController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _newController.text == _currentController.text) {
      return 'New password must be different from the current one.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await sl<AuthRepository>().changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Password Updated'),
          content: const Text(
              'Your password has been changed successfully. Please use your new password next time you sign in.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = _mapError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Current password is incorrect. Please try again.';
    }
    if (msg.contains('requires-recent-login')) {
      return 'Your session has expired. Please sign out and sign in again before changing your password.';
    }
    if (msg.contains('weak-password')) {
      return 'The new password is too weak. Choose a stronger password.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final footerError = _footerError;
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('VERIFY IDENTITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _currentController,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Current Password', border: InputBorder.none),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text("Enter your current password to confirm it's you.",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('NEW PASSWORD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                TextField(
                  controller: _newController,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'New Password', border: InputBorder.none),
                ),
                const Divider(height: 1, color: AppColors.divider),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Confirm New Password', border: InputBorder.none),
                ),
              ],
            ),
          ),
          if (footerError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(footerError, style: const TextStyle(fontSize: 12, color: AppColors.expense)),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: AppColors.expense)),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isValid && !_isLoading ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
