import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:calora/core/services/barcode_service.dart';

void main() {
  group('BarcodeUtils.normalize Tests', () {
    test('1. Normalizes standard 13-digit EAN-13 barcode', () {
      expect(BarcodeUtils.normalize('8992753123456'), '8992753123456');
    });

    test('2. Normalizes 12-digit UPC-A barcode with leading zero', () {
      expect(BarcodeUtils.normalize('089686010955'), '089686010955');
    });

    test('3. Normalizes 8-digit EAN-8 barcode', () {
      expect(BarcodeUtils.normalize('12345670'), '12345670');
    });

    test('4. Normalizes 6-digit and 8-digit UPC-E barcodes', () {
      expect(BarcodeUtils.normalize('012345'), '012345');
      expect(BarcodeUtils.normalize('01234567'), '01234567');
    });

    test('5. Normalizes 14-digit ITF-14 barcode', () {
      expect(BarcodeUtils.normalize('10012345678902'), '10012345678902');
    });

    test('6. Strips spaces and hyphens from human-readable barcode prints', () {
      expect(
        BarcodeUtils.normalize(' 8 992-753 123456 '),
        '8992753123456',
      );
      expect(
        BarcodeUtils.normalize('0-89686-01095-5'),
        '089686010955',
      );
    });

    test('7. Accepts valid alphanumeric retail barcodes (Code 128 / Code 39)', () {
      expect(BarcodeUtils.normalize('ITEM-9824'), 'ITEM-9824');
      expect(BarcodeUtils.normalize('BAKERY01'), 'BAKERY01');
    });

    test('8. Rejects empty, whitespace, and null inputs', () {
      expect(BarcodeUtils.normalize(null), isNull);
      expect(BarcodeUtils.normalize(''), isNull);
      expect(BarcodeUtils.normalize('   '), isNull);
    });

    test('9. Rejects inputs that are too short (< 4 chars)', () {
      expect(BarcodeUtils.normalize('12'), isNull);
      expect(BarcodeUtils.normalize('123'), isNull);
      expect(BarcodeUtils.normalize('ABC'), isNull);
    });
  });

  group('BarcodeService Open Food Facts & Parser Tests', () {
    test('10. Successfully parses Open Food Facts product response with nutriments', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('8992753123456')) {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'code': '8992753123456',
                'product_name': 'Ultra Milk Full Cream',
                'brands': 'Ultrajaya',
                'serving_size': '200 ml',
                'serving_quantity': 200,
                'nutriments': {
                  'energy-kcal_100g': 60,
                  'proteins_100g': 3.2,
                  'carbohydrates_100g': 4.8,
                  'fat_100g': 3.5,
                },
                'image_front_url': 'https://images.openfoodfacts.org/milk.jpg',
                'categories': 'Dairy, Beverages',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      // Construct service using mock http client
      // Note: Supabase call will fall back / bypass if unconfigured in unit test
      final service = BarcodeService(httpClient: mockClient);
      final result = await service.lookup('8992753123456');

      expect(result.isFound, isTrue);
      expect(result.food, isNotNull);
      expect(result.food!.name, contains('Ultra Milk Full Cream'));
      expect(result.food!.calories, equals(60));
      expect(result.food!.proteinG, equals(3.2));
      expect(result.food!.carbsG, equals(4.8));
      expect(result.food!.fatG, equals(3.5));
      expect(result.food!.source, equals('openfoodfacts'));
    });

    test('11. Returns invalid status for malformed barcode', () async {
      final service = BarcodeService();
      final result = await service.lookup('12');

      expect(result.isInvalid, isTrue);
      expect(result.isFound, isFalse);
    });

    test('12. Falls back to notFound when product does not exist in any database', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'status': 0, 'status_verbose': 'product not found'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = BarcodeService(httpClient: mockClient);
      final result = await service.lookup('9999999999999');

      expect(result.isNotFound, isTrue);
      expect(result.isFound, isFalse);
    });
  });
}
