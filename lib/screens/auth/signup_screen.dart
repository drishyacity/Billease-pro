import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../onboarding/onboarding_basic_details_screen.dart';
import '../../services/supabase_service.dart';
import '../../services/database_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscure = true;
  bool _obscure2 = true;

  bool _isStrong(String p) {
    if (p.length < 6) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(p);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(p);
    final hasDigit = RegExp(r'\d').hasMatch(p);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
    return hasLower && hasUpper && hasDigit && hasSymbol;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      Get.snackbar('Mismatch', 'Passwords do not match', snackPosition: SnackPosition.TOP);
      return;
    }
    if (!_isStrong(_passwordController.text)) {
      Get.snackbar('Weak password', 'Use 6+ chars with lowercase, uppercase, digit, and symbol', snackPosition: SnackPosition.TOP);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await SupabaseService().sendEmailOtp(_emailController.text.trim());
      setState(() => _codeSent = true);
      Get.snackbar('OTP Sent', 'Check your email for a 6-digit code', snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.TOP);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      Get.snackbar('Invalid Code', 'Enter the 6-digit OTP', snackPosition: SnackPosition.TOP);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await SupabaseService().verifyEmailOtp(
        email: _emailController.text.trim(),
        code: _otpController.text.trim(),
      );
      await SupabaseService().updatePassword(newPassword: _passwordController.text);
      await DatabaseService().setCurrentUser(SupabaseService().currentUserId);
      Get.offAll(() => const OnboardingBasicDetailsScreen());
    } catch (e) {
      Get.snackbar('Verification Failed', e.toString(), snackPosition: SnackPosition.TOP);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter password';
                            if (!_isStrong(v)) return 'Use lower, UPPER, digit, symbol (min 6)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscure2,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure2 = !_obscure2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirm password';
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_codeSent)
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(labelText: 'Enter 6-digit OTP'),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : (_codeSent ? _verifyOtp : _sendOtp),
                            child: _isLoading
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_codeSent ? 'Verify OTP' : 'Send OTP'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


