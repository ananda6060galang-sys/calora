import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ai_scanner_service.dart';
import '../../../models/food.dart';

final aiScannerServiceProvider = Provider<AiScannerService>(
  (ref) => AiScannerService(),
);

enum AiScannerStatus {
  idle,
  capturing,
  analyzing,
  success,
  error,
}

class AiScannerState {
  final AiScannerStatus status;
  final Food? recognizedFood;
  final XFile? capturedFile;
  final double confidence;
  final List<String> ingredients;
  final String? model;
  final String? errorMessage;

  const AiScannerState({
    this.status = AiScannerStatus.idle,
    this.recognizedFood,
    this.capturedFile,
    this.confidence = 0.0,
    this.ingredients = const [],
    this.model,
    this.errorMessage,
  });

  AiScannerState copyWith({
    AiScannerStatus? status,
    Food? recognizedFood,
    XFile? capturedFile,
    double? confidence,
    List<String>? ingredients,
    String? model,
    String? errorMessage,
  }) {
    return AiScannerState(
      status: status ?? this.status,
      recognizedFood: recognizedFood ?? this.recognizedFood,
      capturedFile: capturedFile ?? this.capturedFile,
      confidence: confidence ?? this.confidence,
      ingredients: ingredients ?? this.ingredients,
      model: model ?? this.model,
      errorMessage: errorMessage,
    );
  }
}

class AiScannerNotifier extends StateNotifier<AiScannerState> {
  AiScannerNotifier(this._service) : super(const AiScannerState());

  final AiScannerService _service;

  // ==========================================
  // [DEMO / MOCK MODE] - 0 Token Gemini
  // Easy to delete when testing is finished.
  // ==========================================
  bool isMockMode = false;

  void toggleMockMode(bool value) {
    isMockMode = value;
  }

  void loadMockScanResult([XFile? file]) {
    state = state.copyWith(
      status: AiScannerStatus.success,
      capturedFile: file,
      recognizedFood: const Food(
        id: 'mock_demo_food',
        name: 'Nasi Goreng Spesial',
        servingLabel: '1 porsi (260g)',
        calories: 450,
        proteinG: 22.0,
        carbsG: 58.0,
        fatG: 14.0,
        portionGrams: 260.0,
        category: 'Lunch',
      ),
      confidence: 0.94,
      ingredients: ['Nasi Putih', 'Telur Ayam', 'Daging Ayam', 'Kecap Manis', 'Bawang'],
      model: 'demo-local-mock (0 token)',
    );
  }

  Future<void> captureAndScan(ImageSource source) async {
    state = state.copyWith(status: AiScannerStatus.capturing, errorMessage: null);

    final file = await _service.pickFoodImage(source);
    if (file == null) {
      // User cancelled picking
      state = state.copyWith(status: AiScannerStatus.idle);
      return;
    }

    state = state.copyWith(
      status: AiScannerStatus.analyzing,
      capturedFile: file,
    );

    if (isMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
      loadMockScanResult(file);
      return;
    }

    final result = await _service.scanFoodImage(file);

    if (result.success && result.food != null) {
      state = state.copyWith(
        status: AiScannerStatus.success,
        recognizedFood: result.food,
        confidence: result.confidence,
        ingredients: result.ingredients,
        model: result.model,
      );
    } else {
      state = state.copyWith(
        status: AiScannerStatus.error,
        errorMessage: result.errorMessage ?? 'diary.scanError',
      );
    }
  }

  Future<void> scanXFile(XFile file) async {
    state = state.copyWith(
      status: AiScannerStatus.analyzing,
      capturedFile: file,
      errorMessage: null,
    );

    if (isMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
      loadMockScanResult(file);
      return;
    }

    final result = await _service.scanFoodImage(file);

    if (result.success && result.food != null) {
      state = state.copyWith(
        status: AiScannerStatus.success,
        recognizedFood: result.food,
        confidence: result.confidence,
        ingredients: result.ingredients,
        model: result.model,
      );
    } else {
      state = state.copyWith(
        status: AiScannerStatus.error,
        errorMessage: result.errorMessage ?? 'diary.scanError',
      );
    }
  }

  void updateFood({
    String? name,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? portionGrams,
    String? category,
  }) {
    if (state.recognizedFood == null) return;
    final current = state.recognizedFood!;
    final updated = current.copyWith(
      name: name ?? current.name,
      calories: calories ?? current.calories,
      proteinG: proteinG ?? current.proteinG,
      carbsG: carbsG ?? current.carbsG,
      fatG: fatG ?? current.fatG,
      portionGrams: portionGrams ?? current.portionGrams,
      category: category ?? current.category,
      servingLabel: portionGrams != null
          ? '1 serving (${portionGrams.round()}g)'
          : current.servingLabel,
    );
    state = state.copyWith(recognizedFood: updated);
  }

  void reset() {
    state = const AiScannerState();
  }
}

final aiScannerProvider =
    StateNotifierProvider<AiScannerNotifier, AiScannerState>(
  (ref) => AiScannerNotifier(ref.watch(aiScannerServiceProvider)),
);
