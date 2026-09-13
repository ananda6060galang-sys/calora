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
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email.trim(), password: password);
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

  /// Sign out the current user and clear local session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
