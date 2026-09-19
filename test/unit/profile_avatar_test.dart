import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:calora/core/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ProfileService Avatar Unit Tests', () {
    late ProfileService profileService;

    setUpAll(() {
      final client = SupabaseClient('https://example.supabase.co', 'dummy_key');
      profileService = ProfileService(client);
    });

    test('1. Allowed file extensions include jpg, jpeg, png, webp', () {
      expect(ProfileService.allowedAvatarExtensions.contains('jpg'), isTrue);
      expect(ProfileService.allowedAvatarExtensions.contains('jpeg'), isTrue);
      expect(ProfileService.allowedAvatarExtensions.contains('png'), isTrue);
      expect(ProfileService.allowedAvatarExtensions.contains('webp'), isTrue);
      expect(ProfileService.allowedAvatarExtensions.contains('gif'), isFalse);
      expect(ProfileService.allowedAvatarExtensions.contains('svg'), isFalse);
      expect(ProfileService.allowedAvatarExtensions.contains('pdf'), isFalse);
    });

    test('2. uploadAvatar rejects files exceeding 5 MB limit', () async {
      final oversizedBytes = Uint8List(5 * 1024 * 1024 + 1);

      expect(
        () => profileService.uploadAvatar(
          userId: 'test-user-id',
          bytes: oversizedBytes,
          fileExtension: 'jpg',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('5 MB limit'),
        )),
      );
    });

    test('3. uploadAvatar rejects unsupported file types', () async {
      final validBytes = Uint8List(100);

      expect(
        () => profileService.uploadAvatar(
          userId: 'test-user-id',
          bytes: validBytes,
          fileExtension: 'gif',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Unsupported file type'),
        )),
      );

      expect(
        () => profileService.uploadAvatar(
          userId: 'test-user-id',
          bytes: validBytes,
          fileExtension: 'exe',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('4. deleteAvatarFile handles empty or whitespace strings gracefully without error', () async {
      await expectLater(
        profileService.deleteAvatarFile('', userId: 'user-123'),
        completes,
      );
      await expectLater(
        profileService.deleteAvatarFile('   ', userId: 'user-123'),
        completes,
      );
    });

    test('5. deleteAvatarFile prevents deleting files belonging to another user', () async {
      expect(
        () => profileService.deleteAvatarFile(
          'https://example.supabase.co/storage/v1/object/public/avatars/other-user/avatar_123.jpg',
          userId: 'my-user-id',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Access denied'),
        )),
      );

      expect(
        () => profileService.deleteAvatarFile(
          'other-user/avatar_123.jpg',
          userId: 'my-user-id',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Access denied'),
        )),
      );
    });
  });
}
