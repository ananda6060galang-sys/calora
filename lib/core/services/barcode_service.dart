import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/food.dart';
import '../../models/indonesian_foods_data.dart';
import '../../models/mock_data.dart';
import '../config/supabase_config.dart';

/// Status of the barcode lookup operation.
enum BarcodeLookupStatus {
  found,
  notFound,
  invalid,
  error,
}

/// Result of looking up a barcode across Calora, Open Food Facts, and USDA.
class BarcodeLookupResult {
  const BarcodeLookupResult({
    required this.status,
    required this.barcode,
    this.food,
    this.source,
    this.errorMessage,
  });

  final BarcodeLookupStatus status;
  final String barcode;
  final Food? food;
  final String? source;
  final String? errorMessage;

  bool get isFound => status == BarcodeLookupStatus.found && food != null;
  bool get isNotFound => status == BarcodeLookupStatus.notFound;
  bool get isInvalid => status == BarcodeLookupStatus.invalid;
  bool get isError => status == BarcodeLookupStatus.error;

  factory BarcodeLookupResult.found(Food food, {required String barcode, String? source}) {
    return BarcodeLookupResult(
      status: BarcodeLookupStatus.found,
      barcode: barcode,
      food: food,
      source: source ?? food.source,
    );
  }

  factory BarcodeLookupResult.notFound({required String barcode}) {
    return BarcodeLookupResult(
      status: BarcodeLookupStatus.notFound,
      barcode: barcode,
    );
  }

  factory BarcodeLookupResult.invalid({required String barcode, String? reason}) {
    return BarcodeLookupResult(
      status: BarcodeLookupStatus.invalid,
      barcode: barcode,
      errorMessage: reason ?? 'Invalid barcode number',
    );
  }

  factory BarcodeLookupResult.error({required String barcode, required String message}) {
    return BarcodeLookupResult(
      status: BarcodeLookupStatus.error,
      barcode: barcode,
      errorMessage: message,
    );
  }
}

/// Normalizes and cleans raw barcode input while preserving leading zeros.
class BarcodeUtils {
  BarcodeUtils._();

  /// Normalizes a raw barcode:
  /// - Trims leading and trailing whitespace
  /// - Strips non-digit formatting characters if any
  /// - Preserves leading zeros (e.g., UPC-A '089686010955')
  /// - Validates reasonable length (7 to 14 digits for standard barcodes)
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 14) {
      return null;
    }
    return digitsOnly;
  }
}

/// Service that executes product lookup in the exact priority order:
/// 1. Calora Foods database
/// 2. Open Food Facts
/// 3. USDA FoodData Central (via Edge Function)
/// 4. Food Request fallback (signaled via notFound status)
class BarcodeService {
  BarcodeService({
    SupabaseClient? supabaseClient,
    http.Client? httpClient,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _http = httpClient ?? http.Client();

  final SupabaseClient _supabase;
  final http.Client _http;

  Uri get _edgeFunctionUri =>
      Uri.parse('${SupabaseConfig.url}/functions/v1/fatsecret-food');

  Map<String, String> _buildEdgeFunctionHeaders() {
    final session = _supabase.auth.currentSession;
    final accessToken = session?.accessToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': SupabaseConfig.publishableKey,
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  /// Looks up a product by raw or normalized barcode.
  Future<BarcodeLookupResult> lookup(String rawBarcode) async {
    final normalized = BarcodeUtils.normalize(rawBarcode);
    if (normalized == null) {
      return BarcodeLookupResult.invalid(
        barcode: rawBarcode.trim(),
        reason: 'Invalid barcode format',
      );
    }

    try {
      // ── PRIORITY 1: Calora Foods database ──
      final caloraFood = await _queryCaloraDatabase(normalized);
      if (caloraFood != null) {
        return BarcodeLookupResult.found(
          caloraFood,
          barcode: normalized,
          source: 'calora',
        );
      }

      // ── PRIORITY 2: Open Food Facts API ──
      final offFood = await _queryOpenFoodFacts(normalized);
      if (offFood != null) {
        return BarcodeLookupResult.found(
          offFood,
          barcode: normalized,
          source: 'openfoodfacts',
        );
      }

      // ── PRIORITY 3: USDA FoodData Central ──
      final usdaFood = await _queryUsda(normalized);
      if (usdaFood != null) {
        return BarcodeLookupResult.found(
          usdaFood,
          barcode: normalized,
          source: 'usda',
        );
      }

      // ── PRIORITY 4: Not Found ──
      return BarcodeLookupResult.notFound(barcode: normalized);
    } catch (e) {
      debugPrint('Barcode lookup error: $e');
      return BarcodeLookupResult.error(
        barcode: normalized,
        message: 'We could not load this product. Try again.',
      );
    }
  }

  /// Queries Supabase public.foods by barcode, with local catalog fallback.
  Future<Food?> _queryCaloraDatabase(String barcode) async {
    try {
      final response = await _supabase
          .from('foods')
          .select('*, food_categories(name)')
          .eq('barcode', barcode)
          .maybeSingle();

      if (response != null) {
        return Food.fromSupabase(response);
      }
    } catch (e) {
      debugPrint('Calora DB barcode query note: $e');
    }

    // Check in-memory local Indonesian & demo catalog
    try {
      final allLocal = [...indonesianFoods, ...demoFoods];
      final matched = allLocal.firstWhere(
        (f) => f.barcode == barcode,
        orElse: () => const Food(
          id: '',
          name: '',
          servingLabel: '',
          calories: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
        ),
      );
      if (matched.id.isNotEmpty) {
        return matched.copyWith(source: 'calora');
      }
    } catch (_) {}

    return null;
  }

  /// Queries Open Food Facts public JSON API.
  Future<Food?> _queryOpenFoodFacts(String barcode) async {
    final candidateBarcodes = [barcode];
    // If it's a 12-digit UPC-A, also try with leading zero (EAN-13 format)
    if (barcode.length == 12) {
      candidateBarcodes.add('0$barcode');
    }

    for (final code in candidateBarcodes) {
      try {
        final uri = Uri.parse(
          'https://world.openfoodfacts.org/api/v2/product/$code.json',
        );
        final res = await _http.get(
          uri,
          headers: {
            'User-Agent':
                'Calora - Flutter Nutrition App - Version 1.0 (calora.nutrition@gmail.com)',
          },
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final status = data['status'];
          final product = data['product'];

          if (status == 1 && product is Map<String, dynamic>) {
            final parsedFood = _parseOpenFoodFactsProduct(code, product);
            if (parsedFood != null) {
              return parsedFood;
            }
          }
        }
      } catch (e) {
        debugPrint('Open Food Facts lookup error for $code: $e');
      }
    }

    return null;
  }

  /// Parses an Open Food Facts product payload into Calora's Food model.
  Food? _parseOpenFoodFactsProduct(
    String barcode,
    Map<String, dynamic> product,
  ) {
    // 1. Product Name & Brand
    final rawName = (product['product_name'] ??
            product['product_name_en'] ??
            product['product_name_id'] ??
            '')
        .toString()
        .trim();

    if (rawName.isEmpty) return null;

    final rawBrand = (product['brands'] ?? product['brand_owner'] ?? '')
        .toString()
        .trim();
    final displayName = rawBrand.isNotEmpty &&
            !rawName.toLowerCase().contains(rawBrand.toLowerCase())
        ? '$rawBrand $rawName'
        : rawName;

    // 2. Nutriments
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    // Calories (energy-kcal)
    double? caloriesVal;
    if (nutriments['energy-kcal_100g'] != null) {
      caloriesVal = (nutriments['energy-kcal_100g'] as num).toDouble();
    } else if (nutriments['energy-kcal'] != null) {
      caloriesVal = (nutriments['energy-kcal'] as num).toDouble();
    } else if (nutriments['energy-kcal_serving'] != null) {
      caloriesVal = (nutriments['energy-kcal_serving'] as num).toDouble();
    } else if (nutriments['energy_100g'] != null) {
      // kJ to kcal conversion: 1 kcal = 4.184 kJ
      caloriesVal = (nutriments['energy_100g'] as num).toDouble() / 4.184;
    }

    final calories = (caloriesVal ?? 0.0).round();

    // Protein, Carbs, Fat
    final proteinG = (nutriments['proteins_100g'] as num?)?.toDouble() ??
        (nutriments['proteins'] as num?)?.toDouble() ??
        (nutriments['proteins_serving'] as num?)?.toDouble() ??
        0.0;

    final carbsG = (nutriments['carbohydrates_100g'] as num?)?.toDouble() ??
        (nutriments['carbohydrates'] as num?)?.toDouble() ??
        (nutriments['carbohydrates_serving'] as num?)?.toDouble() ??
        0.0;

    final fatG = (nutriments['fat_100g'] as num?)?.toDouble() ??
        (nutriments['fat'] as num?)?.toDouble() ??
        (nutriments['fat_serving'] as num?)?.toDouble() ??
        0.0;

    // 3. Serving & Portion Size
    final rawServingSize = (product['serving_size'] ?? '').toString().trim();
    final servingQuantity =
        (product['serving_quantity'] as num?)?.toDouble();

    double portionGrams = 100.0;
    if (servingQuantity != null && servingQuantity > 0) {
      portionGrams = servingQuantity;
    } else if (rawServingSize.isNotEmpty) {
      final gramMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:g|ml)\b', caseSensitive: false)
          .firstMatch(rawServingSize);
      if (gramMatch != null) {
        final parsed = double.tryParse(gramMatch.group(1)!);
        if (parsed != null && parsed > 0) {
          portionGrams = parsed;
        }
      }
    }

    final servingLabel = rawServingSize.isNotEmpty
        ? rawServingSize
        : '${portionGrams.round()} g';

    // 4. Product Image
    final imageUrl = (product['image_front_url'] ??
            product['image_url'] ??
            product['image_small_url'])
        ?.toString();

    // 5. Category
    final categories = (product['categories'] ?? '').toString();
    String category = 'Packaged Food';
    if (categories.toLowerCase().contains('beverage') ||
        categories.toLowerCase().contains('drink')) {
      category = 'Beverages';
    } else if (categories.toLowerCase().contains('dairy') ||
        categories.toLowerCase().contains('milk') ||
        categories.toLowerCase().contains('yogurt')) {
      category = 'Dairy';
    } else if (categories.toLowerCase().contains('snack')) {
      category = 'Snack';
    }

    final foodId = 'off_$barcode';

    return Food(
      id: foodId,
      name: displayName,
      servingLabel: servingLabel,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      portionGrams: portionGrams,
      category: category,
      source: 'openfoodfacts',
      barcode: barcode,
      brand: rawBrand.isNotEmpty ? rawBrand : null,
      imageUrl: imageUrl,
      servings: [
        FoodServing(
          servingId: foodId,
          servingDescription: servingLabel,
          calories: calories,
          proteinG: proteinG,
          carbsG: carbsG,
          fatG: fatG,
          metricServingAmount: portionGrams,
          metricServingUnit: 'g',
          numberOfUnits: 1.0,
        ),
      ],
    );
  }

  /// Queries USDA FoodData Central via Supabase Edge Function fatsecret-food.
  Future<Food?> _queryUsda(String barcode) async {
    try {
      final response = await _http
          .post(
            _edgeFunctionUri,
            headers: _buildEdgeFunctionHeaders(),
            body: jsonEncode({
              'action': 'barcode',
              'barcode': barcode,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawFood = data['food'] as Map<String, dynamic>?;
        if (rawFood != null) {
          final food = Food.fromJson(rawFood);
          return food.copyWith(
            source: 'usda',
            barcode: barcode,
          );
        }
      }
    } catch (e) {
      debugPrint('USDA Edge Function barcode query note: $e');
    }

    return null;
  }
}

/// Riverpod provider for BarcodeService.
final barcodeServiceProvider = Provider<BarcodeService>((ref) {
  return BarcodeService();
});

