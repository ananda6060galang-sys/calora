import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/barcode_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/food.dart';
import '../food_diary_screen.dart';
import '../food_request_screen.dart';
import '../providers/diary_provider.dart';

/// Full-screen Barcode Food Scanner for Calora.
/// Supports automated detection for EAN-13, EAN-8, UPC-A.
/// Follows 4-tier product lookup:
/// 1. Calora Foods database
/// 2. Open Food Facts
/// 3. USDA FoodData Central
/// 4. Food Request fallback (prefilled barcode)
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({
    super.key,
    this.meal,
    this.date,
  });

  final String? meal;
  final DateTime? date;

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final MobileScannerController _scannerController;

  // Scanning & lookup lifecycle state
  bool _isSearching = false;
  bool _isCooldown = false;
  bool _isNotFound = false;
  String? _errorMessage;
  String? _lastScannedBarcode;
  bool _isTorchOn = false;

  // Product found & review food state
  Food? _scannedFood;
  bool _showProductFound = false;
  bool _isReviewExpanded = false;
  late String _selectedMeal;
  double _servings = 1.0;
  bool _isGramMode = false;
  late final TextEditingController _gramController;

  // Reticle laser beam animation
  late AnimationController _beamAnimationController;
  late Animation<double> _beamAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selectedMeal = widget.meal != null && widget.meal!.trim().isNotEmpty
        ? widget.meal!
        : getDefaultMealType(DateTime.now());

    _gramController = TextEditingController(text: '100');

    _scannerController = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
      ],
      detectionSpeed: DetectionSpeed.normal,
      torchEnabled: false,
    );

    _beamAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _beamAnimation = CurvedAnimation(
      parent: _beamAnimationController,
      curve: Curves.easeInOut,
    );
    _beamAnimationController.repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scannerController.stop();
    } else if (state == AppLifecycleState.resumed &&
        !_showProductFound &&
        !_isNotFound &&
        !_isSearching) {
      _scannerController.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _beamAnimationController.dispose();
    _gramController.dispose();
    super.dispose();
  }

  // ── SCANNING & DETECTION HANDLER ──────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_isSearching || _isCooldown || _showProductFound || _isNotFound) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      final normalized = BarcodeUtils.normalize(rawValue);

      if (normalized != null) {
        _isCooldown = true;
        _executeBarcodeLookup(normalized);
        break;
      }
    }
  }

  Future<void> _executeBarcodeLookup(String barcode) async {
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isSearching = true;
      _isNotFound = false;
      _errorMessage = null;
      _lastScannedBarcode = barcode;
    });

    _beamAnimationController.stop();

    try {
      final result = await ref.read(barcodeServiceProvider).lookup(barcode);

      if (!mounted) return;

      if (result.isFound && result.food != null) {
        HapticFeedback.mediumImpact();
        _scannerController.stop();

        final foundFood = result.food!;
        final initialGrams = foundFood.portionGrams ?? 100.0;
        _gramController.text = initialGrams.round().toString();

        setState(() {
          _isSearching = false;
          _scannedFood = foundFood;
          _showProductFound = true;
          _servings = 1.0;
          _isGramMode = false;
        });
      } else if (result.isNotFound) {
        HapticFeedback.vibrate();
        _scannerController.stop();
        setState(() {
          _isSearching = false;
          _isNotFound = true;
        });
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isSearching = false;
          _errorMessage = result.errorMessage ?? 'diary.networkErrorRetry'.tr();
        });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _isSearching = false;
        _errorMessage = 'diary.networkErrorRetry'.tr();
      });
    }
  }

  void _resetScan() {
    HapticFeedback.selectionClick();
    setState(() {
      _isNotFound = false;
      _isSearching = false;
      _showProductFound = false;
      _isReviewExpanded = false;
      _scannedFood = null;
      _errorMessage = null;
    });

    _beamAnimationController.repeat(reverse: true);
    _scannerController.start();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _isCooldown = false;
    });
  }

  Future<void> _toggleTorch() async {
    HapticFeedback.selectionClick();
    await _scannerController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  Future<void> _flipCamera() async {
    HapticFeedback.selectionClick();
    await _scannerController.switchCamera();
  }

  // ── ADD TO FOOD DIARY ─────────────────────────────────────────────────────

  void _addToFoodDiary() {
    if (_scannedFood == null) return;

    HapticFeedback.mediumImpact();
    final food = _scannedFood!;

    final calculatedCalories = (food.calories * _servings).round();

    double? totalGrams;
    if (food.portionGrams != null) {
      totalGrams = food.portionGrams! * _servings;
    }

    final entryFood = food.copyWith(
      calories: food.calories,
      proteinG: food.proteinG,
      carbsG: food.carbsG,
      fatG: food.fatG,
      portionGrams: food.portionGrams,
    );

    final targetDate = widget.date ?? DateTime.now();

    ref.read(diaryProvider.notifier).add(
          entryFood,
          _servings,
          _selectedMeal,
          targetDate,
          portionGrams: totalGrams,
        );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, entryFood);
    }

    FoodDiaryScreen.showFoodLoggedFeedback(
      context,
      ref,
      foodName: entryFood.name,
      meal: _selectedMeal,
      entryCalories: calculatedCalories,
      date: targetDate,
    );
  }

  // ── MANUAL BARCODE ENTRY SHEET ────────────────────────────────────────────

  void _showManualBarcodeSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            final hasInput = textController.text.trim().length >= 4;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                14,
                24,
                math.max(MediaQuery.of(ctx).padding.bottom, 16.0) + bottomInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.dialpad_rounded,
                          color: Color(0xFF4D7800),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'diary.manualBarcode'.tr(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'diary.enterBarcodeNumber'.tr(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(sheetCtx),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      hintText: 'diary.barcodeHint'.tr(),
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        letterSpacing: 0,
                        color: isDark
                            ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
                            : const Color(0xFF9CA3AF),
                      ),
                      prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                      suffixIcon: textController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                textController.clear();
                                setSheetState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceAlt
                          : const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'diary.quickPresets'.tr(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF6B7280),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip(
                        label: 'Nutella (OFF)',
                        code: '3017620422003',
                        isDark: isDark,
                        onTap: () {
                          textController.text = '3017620422003';
                          setSheetState(() {});
                        },
                      ),
                      _buildPresetChip(
                        label: 'Coca Cola (OFF)',
                        code: '5449000000996',
                        isDark: isDark,
                        onTap: () {
                          textController.text = '5449000000996';
                          setSheetState(() {});
                        },
                      ),
                      _buildPresetChip(
                        label: 'Indomie (OFF)',
                        code: '089686010955',
                        isDark: isDark,
                        onTap: () {
                          textController.text = '089686010955';
                          setSheetState(() {});
                        },
                      ),
                      _buildPresetChip(
                        label: 'Greek Yogurt (Calora)',
                        code: '899276100234',
                        isDark: isDark,
                        onTap: () {
                          textController.text = '899276100234';
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: hasInput
                          ? () {
                              final query = textController.text.trim();
                              Navigator.pop(sheetCtx);
                              _executeBarcodeLookup(query);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: isDark
                            ? Colors.white12
                            : const Color(0xFFE5E7EB),
                        foregroundColor: const Color(0xFF0F1410),
                        disabledForegroundColor: isDark
                            ? Colors.white38
                            : const Color(0xFF9CA3AF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'diary.searchBarcodeAction'.tr(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip({
    required String label,
    required String code,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.barcode_reader,
                size: 14,
                color: Color(0xFF4D7800),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD MAIN VIEWPORT ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final frameWidth = math.min(size.width * 0.80, 310.0);
    final frameHeight = (frameWidth / 1.65).clamp(160.0, 195.0);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── LAYER 1: MobileScanner Camera ──
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return _buildPermissionErrorState(context, error.errorCode.name);
            },
          ),

          // ── LAYER 2: Dimmed Overlay Mask ──
          if (!_isNotFound && !_showProductFound)
            CustomPaint(
              size: Size(size.width, size.height),
              painter: _BarcodeOverlayPainter(
                frameWidth: frameWidth,
                frameHeight: frameHeight,
              ),
            ),

          // ── LAYER 3: Barcode Guide Frame & Beam ──
          if (!_isNotFound && !_showProductFound)
            Center(
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 1.2,
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: Size(frameWidth, frameHeight),
                      painter: _CornerBracketPainter(
                        color: AppColors.accent,
                        strokeWidth: 3.5,
                        cornerLength: 24.0,
                        radius: 16.0,
                      ),
                    ),
                    if (!_isSearching)
                      AnimatedBuilder(
                        animation: _beamAnimation,
                        builder: (context, child) {
                          final topOffset =
                              _beamAnimation.value * (frameHeight - 4);
                          return Positioned(
                            top: topOffset,
                            left: 8,
                            right: 8,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withValues(alpha: 0.0),
                                    AppColors.accent.withValues(alpha: 0.95),
                                    AppColors.accent.withValues(alpha: 0.0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.accent.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

          // ── LAYER 4: Helper Instructions Below Frame ──
          if (!_isNotFound && !_showProductFound && !_isSearching)
            Positioned(
              left: 20,
              right: 20,
              top: (size.height / 2) + (frameHeight / 2) + 20,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'diary.alignBarcode'.tr(),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showManualBarcodeSheet(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.dialpad_rounded,
                              color: AppColors.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'diary.manualBarcode'.tr(),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── LAYER 5: Finding Food Loading Overlay ──
          if (_isSearching)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'diary.findingFood'.tr(),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── LAYER 6: Error Banner Overlay ──
          if (_errorMessage != null && !_isSearching)
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 40,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _resetScan,
                      child: Text(
                        'diary.retry'.tr(),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── LAYER 7: Top App Bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'diary.scanBarcode'.tr(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildCircleButton(
                  icon: Icons.dialpad_rounded,
                  tooltip: 'diary.manualBarcode'.tr(),
                  onTap: () => _showManualBarcodeSheet(context),
                ),
                const SizedBox(width: 8),
                _buildCircleButton(
                  icon: _isTorchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  tooltip: 'Flash',
                  color: _isTorchOn ? AppColors.accent : Colors.white,
                  onTap: _toggleTorch,
                ),
                const SizedBox(width: 8),
                _buildCircleButton(
                  icon: Icons.cameraswitch_rounded,
                  tooltip: 'Flip Camera',
                  onTap: _flipCamera,
                ),
              ],
            ),
          ),

          // ── LAYER 8: Product Found Card Sheet ──
          if (_showProductFound && _scannedFood != null)
            _buildProductFoundBottomSheet(context, isDark),

          // ── LAYER 9: Not Found Overlay ──
          if (_isNotFound) _buildNotFoundOverlay(context, isDark),
        ],
      ),
    );
  }

  // ── PRODUCT FOUND & REVIEW FOOD SHEET (SECTIONS 7, 8, 9, 10) ──────────────

  Widget _buildProductFoundBottomSheet(BuildContext context, bool isDark) {
    final food = _scannedFood!;
    final baseCalories = food.calories;
    final totalCalories = (baseCalories * _servings).round();
    final totalProtein = food.proteinG * _servings;
    final totalCarbs = food.carbsG * _servings;
    final totalFat = food.fatG * _servings;

    final sourceDisplay = food.source == 'calora'
        ? 'Calora Food Database'
        : (food.source == 'openfoodfacts'
            ? 'Open Food Facts'
            : (food.source == 'usda' ? 'USDA FoodData Central' : 'Calora'));

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Product Info Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceAlt
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                        ? Image.network(
                            food.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: AppColors.accent,
                                size: 28,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.accent,
                              size: 28,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (food.brand != null && food.brand!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            food.brand!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sourceDisplay,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4D7800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                food.servingLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Calories Highlight Box
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceAlt
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KALORI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$totalCalories',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'kcal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkElevated : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        _isGramMode
                            ? '${(_servings * (food.portionGrams ?? 100)).round()} g'
                            : '${_servings == _servings.roundToDouble() ? _servings.toInt() : _servings} porsi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── SECTION 9: MACRO BREAKDOWN (VISUAL COMPARISON) ──────────
              Text(
                'diary.macroBreakdown'.tr(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              _buildMacroBreakdownBars(
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat,
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // ── SECTION 8: REVIEW FOOD (PORTION & MEAL SELECTION) ───────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilihan Waktu Makan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isReviewExpanded = !_isReviewExpanded;
                      });
                    },
                    icon: Icon(
                      _isReviewExpanded
                          ? Icons.expand_less_rounded
                          : Icons.tune_rounded,
                      size: 16,
                      color: const Color(0xFF4D7800),
                    ),
                    label: Text(
                      _isReviewExpanded ? 'Tutup Atur' : 'diary.reviewFood'.tr(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4D7800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Meal selector chips
              Row(
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((m) {
                  final isSelected =
                      m.toLowerCase() == _selectedMeal.toLowerCase();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMeal = m);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : (isDark
                                    ? AppColors.darkSurfaceAlt
                                    : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            m,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF0F1410)
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : const Color(0xFF4B5563)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_isReviewExpanded) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'diary.adjustPortion'.tr(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceAlt
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _buildUnitToggleTab('Porsi', !_isGramMode, isDark,
                              () {
                            setState(() => _isGramMode = false);
                          }),
                          _buildUnitToggleTab('Gram', _isGramMode, isDark, () {
                            final baseGrams = food.portionGrams ?? 100.0;
                            _gramController.text =
                                (baseGrams * _servings).round().toString();
                            setState(() => _isGramMode = true);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (!_isGramMode) ...[
                  Row(
                    children: [0.5, 1.0, 1.5, 2.0].map((val) {
                      final isSel = _servings == val;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => _servings = val);
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSel
                                  ? AppColors.accent.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              side: BorderSide(
                                color: isSel
                                    ? AppColors.accent
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : const Color(0xFFE5E7EB)),
                                width: isSel ? 1.5 : 1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              '${val}x',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? (isDark
                                        ? AppColors.accent
                                        : const Color(0xFF355E00))
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF374151)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _gramController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            suffixText: 'g',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurfaceAlt
                                : const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (text) {
                            final g = double.tryParse(text);
                            if (g != null && g > 0) {
                              final baseG = food.portionGrams ?? 100.0;
                              setState(() {
                                _servings = g / baseG;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetScan,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E7EB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Scan Lagi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _addToFoodDiary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: const Color(0xFF0F1410),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'diary.addToDiary'.tr(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitToggleTab(
      String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkElevated : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF111827))
                : (isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  // ── MACRO BREAKDOWN BARS (SECTION 9) ──────────────────────────────────────

  Widget _buildMacroBreakdownBars({
    required double protein,
    required double carbs,
    required double fat,
    required bool isDark,
  }) {
    final maxMacro = math.max(protein, math.max(carbs, fat));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          _buildMacroRow(
            label: 'Protein',
            grams: protein,
            color: AppColors.protein,
            factor: maxMacro > 0 ? (protein / maxMacro).clamp(0.08, 1.0) : 0.08,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildMacroRow(
            label: 'Carbs',
            grams: carbs,
            color: AppColors.carbs,
            factor: maxMacro > 0 ? (carbs / maxMacro).clamp(0.08, 1.0) : 0.08,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildMacroRow(
            label: 'Fat',
            grams: fat,
            color: AppColors.fat,
            factor: maxMacro > 0 ? (fat / maxMacro).clamp(0.08, 1.0) : 0.08,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow({
    required String label,
    required double grams,
    required Color color,
    required double factor,
    required bool isDark,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: constraints.maxWidth * factor,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          child: Text(
            '${grams.toStringAsFixed(1)}g',
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // ── PRODUCT NOT FOUND OVERLAY (SECTION 11) ────────────────────────────────

  Widget _buildNotFoundOverlay(BuildContext context, bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/notfound.webp',
              height: 96,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.warning,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'diary.foodNotFound'.tr(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'diary.productNotFoundDesc'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF6B7280),
              ),
            ),
            if (_lastScannedBarcode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceAlt
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_rounded,
                      size: 16,
                      color: Color(0xFF4D7800),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _lastScannedBarcode!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color:
                            isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetScan,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE5E7EB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'diary.scanAgain'.tr(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final barcodeToPass = _lastScannedBarcode;
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FoodRequestScreen(
                            initialBarcode: barcodeToPass,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF0F1410),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'diary.requestThisFood'.tr(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── PERMISSION & ERROR STATE ──────────────────────────────────────────────

  Widget _buildPermissionErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'diary.cameraAccessNeeded'.tr(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'diary.cameraAccessNeededSubtitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => _scannerController.start(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF0F1410),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'diary.allowCamera'.tr(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showManualBarcodeSheet(context),
              child: Text(
                'diary.manualBarcode'.tr(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color color = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Custom painter to darken surrounding area outside the central barcode frame
class _BarcodeOverlayPainter extends CustomPainter {
  const _BarcodeOverlayPainter({
    required this.frameWidth,
    required this.frameHeight,
  });

  final double frameWidth;
  final double frameHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;
    final hole = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameWidth, frameHeight),
      const Radius.circular(16),
    );

    final path = Path()
      ..addRect(rect)
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BarcodeOverlayPainter oldDelegate) {
    return oldDelegate.frameWidth != frameWidth ||
        oldDelegate.frameHeight != frameHeight;
  }
}

/// Custom painter for the 4 corner bracket accents
class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - cornerLength, 0)
        ..lineTo(w - radius, 0)
        ..quadraticBezierTo(w, 0, w, radius)
        ..lineTo(w, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - cornerLength)
        ..lineTo(0, h - radius)
        ..quadraticBezierTo(0, h, radius, h)
        ..lineTo(cornerLength, h),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - cornerLength, h)
        ..lineTo(w - radius, h)
        ..quadraticBezierTo(w, h, w, h - radius)
        ..lineTo(w, h - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) => false;
}
