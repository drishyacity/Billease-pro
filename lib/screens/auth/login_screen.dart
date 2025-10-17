import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../onboarding/onboarding_basic_details_screen.dart';
import '../../services/database_service.dart';
import 'signup_screen.dart';
import '../../services/supabase_service.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await SupabaseService().signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await DatabaseService().setCurrentUser(SupabaseService().currentUserId);
      final profile = await DatabaseService().getCompanyProfile();
      if (profile == null) {
        Get.offAll(() => const OnboardingBasicDetailsScreen());
      } else {
        Get.offAll(() => const DashboardScreen());
      }
    } catch (e) {
      final msg = _friendlyLoginError(e);
      Get.snackbar('Login Failed', msg, snackPosition: SnackPosition.TOP);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _friendlyLoginError(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login credentials')) {
        return 'Invalid email or password.';
      }
      if (m.contains('email not confirmed') || m.contains('confirm')) {
        return 'Please confirm your email to continue.';
      }
      return 'Login failed: ${e.message}';
    }
    return 'Login failed. Please check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('BillEase Pro', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
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
                      validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Login'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.to(() => const ResetPasswordScreen()),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Get.to(() => const SignupScreen()),
                      child: const Text('Create an account'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


