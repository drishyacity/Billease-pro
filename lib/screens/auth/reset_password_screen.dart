import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSending = false;
  bool _isUpdating = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  bool _isStrong(String p) {
    if (p.length < 6) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(p);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(p);
    final hasDigit = RegExp(r'\\d').hasMatch(p);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
    return hasLower && hasUpper && hasDigit && hasSymbol;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPassController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Enter email', 'Please enter your email', snackPosition: SnackPosition.TOP);
      return;
    }
    setState(() => _isSending = true);
    try {
      await SupabaseService().sendPasswordResetEmail(email: email);
      Get.snackbar('Email sent', 'Password reset email sent to $email', snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Failed', e.toString(), snackPosition: SnackPosition.TOP);
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _updatePasswordLoggedIn() async {
    if (!_isStrong(_newPassController.text)) {
      Get.snackbar('Weak password', 'Use 6+ chars with lowercase, uppercase, digit, and symbol', snackPosition: SnackPosition.TOP);
      return;
    }
    if (_newPassController.text != _confirmController.text) {
      Get.snackbar('Mismatch', 'Passwords do not match', snackPosition: SnackPosition.TOP);
      return;
    }
    setState(() => _isUpdating = true);
    try {
      await SupabaseService().updatePassword(newPassword: _newPassController.text);
      Get.snackbar('Updated', 'Password changed successfully', snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Failed', e.toString(), snackPosition: SnackPosition.TOP);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = SupabaseService().currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!loggedIn) ...[
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSending ? null : _sendResetEmail,
                        child: _isSending
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Send reset email'),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _newPassController,
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmController,
                      obscureText: _obscure2,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isUpdating ? null : _updatePasswordLoggedIn,
                        child: _isUpdating
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Update Password'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
