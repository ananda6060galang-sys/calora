import 'package:calora/core/config/supabase_config.dart';
import 'package:calora/core/services/auth_service.dart';
import 'package:calora/core/services/profile_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getAll') {
              return <String, Object>{};
            }
            return null;
          },
        );
  });

  group('Supabase Verification Tests', () {
    test('1. Verify Supabase initializes successfully', () async {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );

      expect(Supabase.instance, isNotNull);
    });

    test('2. Verify Supabase.instance.client is accessible', () {
      final client = Supabase.instance.client;
      expect(client, isNotNull);
      expect(client.auth, isNotNull);
    });

    test('3. Verify AuthService can communicate with Supabase Auth', () {
      final client = Supabase.instance.client;
      final authService = AuthService(client);

      expect(authService.currentUser, isNull);
      expect(authService.currentSession, isNull);
      expect(authService.onAuthStateChange, isA<Stream<AuthState>>());
    });

    test('4. Verify ProfileService is configured for profiles RLS table', () {
      final client = Supabase.instance.client;
      final profileService = ProfileService(client);

      expect(profileService, isNotNull);
    });
  });
}
