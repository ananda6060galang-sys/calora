import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';

/// Provider for accessing the global SupabaseClient instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for accessing the AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

/// Provider for accessing the ProfileService instance.
final profileServiceProvider = Provider<ProfileService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileService(client);
});

/// StreamProvider exposing Supabase AuthState changes.
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.onAuthStateChange;
});

/// Provider returning the current authenticated User (or null).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateStreamProvider);
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});
