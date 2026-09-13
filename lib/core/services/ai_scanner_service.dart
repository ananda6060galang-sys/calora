import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../models/food.dart';
import '../config/supabase_config.dart';

import 'package:flutter/foundation.dart';

/// Result envelope returned by the AI food scanner
class AiScanResult {
  final bool success;
  final Food? food;
  final double confidence;
  final List<String> ingredients;
  final String? model;
  final String? errorMessage;

  const AiScanResult({
    required this.success,
    this.food,
    this.confidence = 0.0,
    this.ingredients = const [],
    this.model,
    this.errorMessage,
  });
}

/// Service handling image capturing and AI food recognition via Supabase Edge Function
class AiScannerService {
  final ImagePicker _picker;
  final http.Client _httpClient;

  AiScannerService({
    ImagePicker? picker,
    http.Client? httpClient,
  })  : _picker = picker ?? ImagePicker(),
        _httpClient = httpClient ?? http.Client();

  static final Uri _scanEndpoint = Uri.parse(
    '${SupabaseConfig.url}/functions/v1/scan-food',
  );

  /// Pick an image from Camera or Gallery with automatic compression to max 1024x1024
  Future<XFile?> pickFoodImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82, // Balanced JPEG compression
      );
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Analyze the food image by sending base64 to Edge Function
  Future<AiScanResult> scanFoodImage(XFile imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      final mimeType = imageFile.name.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      final response = await _httpClient
          .post(
            _scanEndpoint,
            headers: {
              'Content-Type': 'application/json',
              'apikey': SupabaseConfig.publishableKey,
            },
            body: jsonEncode({
              'imageBase64': base64Image,
              'mimeType': mimeType,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final model = data['model']?.toString() ?? 'gemini-3.1-flash-lite';
        debugPrint('[AI Food Scanner] Successfully recognized food via model: $model');

        if (data['success'] == true && data['food'] != null) {
          final foodJson = data['food'] as Map<String, dynamic>;
          final food = Food.fromJson(foodJson);
          final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.85;
          final rawIngredients = data['ingredients'] as List<dynamic>? ?? [];
          final ingredients = rawIngredients.map((e) => e.toString()).toList();

          return AiScanResult(
            success: true,
            food: food,
            confidence: confidence,
            ingredients: ingredients,
            model: model,
          );
        } else {
          return AiScanResult(
            success: false,
            errorMessage: data['error']?.toString() ?? 'Could not recognize food',
          );
        }
      } else {
        return AiScanResult(
          success: false,
          errorMessage: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AiScanResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}
