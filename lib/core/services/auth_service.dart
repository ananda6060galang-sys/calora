import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Clean AuthService wrapping Supabase authentication methods.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Get the currently authenticated Supabase user.
  User? get currentUser => _client.auth.currentUser;

  /// Get the current Supabase session.
  Session? get currentSession => _client.auth.currentSession;

  /// Stream of authentication state changes.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Sign up a new user using email and password.
  ///
  /// [fullName], when provided, is stored in the auth user's metadata
  /// (`full_name`) so onboarding can prefill it instead of asking again.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final trimmedName = fullName?.trim();
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: (trimmedName != null && trimmedName.isNotEmpty)
          ? {'full_name': trimmedName}
          : null,
    );
  }

  /// Sign in an existing user using email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in or register using Google OAuth via Supabase.
  ///
  /// On mobile, [redirectTo] defaults to 'io.supabase.calora://login-callback/'.
  /// On web, [redirectTo] is omitted so it redirects back to the app domain.
  Future<bool> signInWithGoogle({String? redirectTo}) async {
    final effectiveRedirectTo = redirectTo ??
        (kIsWeb ? null : 'io.supabase.calora://login-callback/');
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: effectiveRedirectTo,
    );
  }

  /// Send a password reset email via Supabase Auth (contains 6-digit recovery OTP).
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    final effectiveRedirectTo = redirectTo ??
        (kIsWeb ? null : 'io.supabase.calora://login-callback/');
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: effectiveRedirectTo,
    );
  }

  /// Verify the 6-digit recovery OTP sent to the user's email.
  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
  }

  /// Update the current user's password (called after OTP verification).
  Future<UserResponse> updatePassword({
    required String newPassword,
  }) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sign out the current user and clear local session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

