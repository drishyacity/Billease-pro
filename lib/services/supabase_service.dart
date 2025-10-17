import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;

  SupabaseClient get client => Supabase.instance.client;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  User? get currentUser => client.auth.currentUser;

  Future<void> initialize({required String url, required String anonKey}) async {
    if (_initialized) return;
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        // Persist session for desktop/mobile
        autoRefreshToken: true,
      ),
    );
    _initialized = true;
  }

  Future<void> sendEmailOtp(String email) async {
    await client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> verifyEmailOtp({required String email, required String code}) async {
    // Verify 6-digit code sent to email
    return client.auth.verifyOTP(
      token: code,
      type: OtpType.email,
      email: email,
    );
  }

  String? get currentUserId => client.auth.currentUser?.id;

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<AuthResponse> signUpWithPassword({required String email, required String password}) async {
    return client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithPassword({required String email, required String password}) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail({required String email, String? redirectTo}) async {
    await client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<UserResponse> updatePassword({required String newPassword}) async {
    return client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
