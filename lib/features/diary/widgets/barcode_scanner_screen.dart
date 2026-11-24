import 'dart:async';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/barcode_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/meal_time_resolver.dart';
import '../../../core/widgets/calora_time_picker_sheet.dart';
import '../../../models/food.dart';
import '../../../models/scan_history_item.dart';
import '../food_diary_screen.dart';
import '../food_request_screen.dart';
import '../providers/diary_provider.dart';
import '../providers/scan_history_provider.dart';
import 'scan_history_screen.dart';

/// Full-screen Barcode Food Scanner for Calora.
/// Follows Figma specifications:
/// - Screen 1: Camera scanning with clean top bar and bottom control capsule
/// - Screen 2: Instant scan result popup with "Review Food" and "Add to Diary"
/// - Screen 3: Smooth expanded review sheet with meal pills, flame calories card,
///   macro composition, portion multipliers, and date/time selector.
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
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;

  // Scanning & lookup lifecycle state
  bool _isSearching = false;
  bool _isCooldown = false;
  bool _isNotFound = false;
  String? _errorMessage;
  String? _lastScannedBarcode;
  bool _isTorchOn = false;
  Timer? _cooldownTimer;

  // AR Live Barcode Tracking Reticle state
  Rect? _trackedBarcodeRect;
  bool _isLockedOn = false;

  // Product found & review food state
  Food? _scannedFood;
  bool _showProductFound = false;
  bool _isReviewExpanded = false;
  late String _selectedMeal;
  late DateTime _selectedDate;
  double _servings = 1.0;
  bool _isGramMode = false;
  late final TextEditingController _gramController;

  // Reticle laser beam animation
  late AnimationController _beamAnimationController;
  late Animation<double> _beamAnimation;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.date ?? DateTime.now();
    _selectedMeal = widget.meal != null && widget.meal!.trim().isNotEmpty
        ? widget.meal!
        : MealTimeResolver.resolveCurrentMeal(time: _selectedDate);

    _gramController = TextEditingController(text: '100');

    // Passing empty formats list allows ML Kit to detect ALL barcode formats:
    // EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, Code 93, Codabar, ITF, QR Code, Data Matrix.
    _scannerController = MobileScannerController(
      formats: const <BarcodeFormat>[],
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 250,
      torchEnabled: false,
      autoZoom: true,
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
  void dispose() {
    _cooldownTimer?.cancel();
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

    final screenSize = MediaQuery.sizeOf(context);

    for (final barcode in capture.barcodes) {
      // Check rawValue first, falling back to displayValue if rawValue is null or empty
      final rawValue = (barcode.rawValue?.trim().isNotEmpty == true)
          ? barcode.rawValue
          : barcode.displayValue;
      final normalized = BarcodeUtils.normalize(rawValue);

      if (normalized != null && normalized.isNotEmpty) {
        _isCooldown = true;

        // Calculate AR live mapped reticle position on screen
        final mappedRect = _calculateMappedScreenRect(
          barcode,
          capture.size,
          screenSize,
        );

        if (mounted) {
          setState(() {
            _trackedBarcodeRect = mappedRect;
            _isLockedOn = true;
          });
        }

        HapticFeedback.lightImpact();

        // Safety timer: guarantees cooldown resets within 2000ms if lookup is interrupted or aborted
        _cooldownTimer?.cancel();
        _cooldownTimer = Timer(const Duration(milliseconds: 2000), () {
          if (mounted && !_showProductFound && !_isNotFound && !_isSearching) {
            setState(() {
              _isCooldown = false;
              _isLockedOn = false;
              _trackedBarcodeRect = null;
            });
          }
        });

        // 180ms smooth spring glide & visual lock-on dwell before showing result
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted && !_showProductFound && !_isNotFound) {
            _executeBarcodeLookup(normalized);
          }
        });
        break;
      }
    }
  }

  Rect? _calculateMappedScreenRect(
    Barcode barcode,
    Size captureSize,
    Size screenSize,
  ) {
    try {
      final corners = barcode.corners;
      if (corners.isEmpty) {
        return null;
      }

      final inputSize = (barcode.size.width > 0 && barcode.size.height > 0)
          ? barcode.size
          : captureSize;

      List<Offset> mappedCorners = corners;

      if (inputSize.width > 0 && inputSize.height > 0) {
        final double imgW;
        final double imgH;
        // On portrait phones, the camera sensor buffer is typically landscape (width > height)
        if (screenSize.height > screenSize.width &&
            inputSize.width > inputSize.height) {
          imgW = inputSize.height;
          imgH = inputSize.width;
        } else {
          imgW = inputSize.width;
          imgH = inputSize.height;
        }

        final scaleX = screenSize.width / imgW;
        final scaleY = screenSize.height / imgH;
        final scale = math.max(scaleX, scaleY);

        final scaledW = imgW * scale;
        final scaledH = imgH * scale;
        final dx = (screenSize.width - scaledW) / 2;
        final dy = (screenSize.height - scaledH) / 2;

        mappedCorners = [
          for (final c in corners)
            Offset(c.dx * scale + dx, c.dy * scale + dy),
        ];
      }

      double minX = double.infinity;
      double maxX = double.negativeInfinity;
      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (final c in mappedCorners) {
        if (c.dx < minX) minX = c.dx;
        if (c.dx > maxX) maxX = c.dx;
        if (c.dy < minY) minY = c.dy;
        if (c.dy > maxY) maxY = c.dy;
      }

      if (minX.isInfinite || minY.isInfinite || maxX.isInfinite || maxY.isInfinite) {
        return null;
      }

      const padding = 18.0;
      final w = math.max((maxX - minX) + (padding * 2), 160.0);
      final h = math.max((maxY - minY) + (padding * 2), 100.0);
      final centerX = (minX + maxX) / 2;
      final centerY = (minY + maxY) / 2;

      final clampedCenter = Offset(
        centerX.clamp(w / 2 + 16, screenSize.width - w / 2 - 16),
        centerY.clamp(h / 2 + 80, screenSize.height - h / 2 - 150),
      );

      return Rect.fromCenter(
        center: clampedCenter,
        width: w.clamp(160.0, screenSize.width * 0.88),
        height: h.clamp(100.0, 240.0),
      );
    } catch (e) {
      debugPrint('Error calculating mapped screen rect: $e');
      return null;
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
        try {
          await _scannerController.stop();
        } catch (_) {}

        final foundFood = result.food!;
        final initialGrams = foundFood.portionGrams ?? 100.0;
        _gramController.text = initialGrams.round().toString();

        // Record to Scan History
        ref.read(scanHistoryProvider.notifier).addScan(
              id: foundFood.id,
              foodName: foundFood.name,
              calories: foundFood.calories,
              proteinG: foundFood.proteinG,
              carbsG: foundFood.carbsG,
              fatG: foundFood.fatG,
              scanType: ScanType.barcode,
              portionGrams: foundFood.portionGrams,
              servingLabel: foundFood.servingLabel,
              barcode: barcode,
              suggestedMeal: _selectedMeal,
            );

        setState(() {
          _isSearching = false;
          _scannedFood = foundFood;
          _showProductFound = true;
          _isReviewExpanded = false; // Starts in compact popup state (pop up.png)
          _servings = 1.0;
          _isGramMode = false;
        });
      } else if (result.isNotFound) {
        HapticFeedback.vibrate();
        try {
          await _scannerController.stop();
        } catch (_) {}
        setState(() {
          _isSearching = false;
          _isNotFound = true;
        });
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isSearching = false;
          _errorMessage = result.errorMessage ?? 'diary.networkErrorRetry'.tr();
          _isCooldown = false;
          _isLockedOn = false;
          _trackedBarcodeRect = null;
        });
        _beamAnimationController.repeat(reverse: true);
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _isSearching = false;
        _errorMessage = 'diary.networkErrorRetry'.tr();
        _isCooldown = false;
        _isLockedOn = false;
        _trackedBarcodeRect = null;
      });
      _beamAnimationController.repeat(reverse: true);
    }
  }

  void _resetScan() {
    HapticFeedback.selectionClick();
    _cooldownTimer?.cancel();
    setState(() {
      _isNotFound = false;
      _isSearching = false;
      _showProductFound = false;
      _isReviewExpanded = false;
      _scannedFood = null;
      _errorMessage = null;
      _trackedBarcodeRect = null;
      _isLockedOn = false;
      _isCooldown = false;
    });

    _beamAnimationController.repeat(reverse: true);
    try {
      _scannerController.start();
    } catch (_) {}
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

  Future<void> _pickImageFromGallery() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final capture = await _scannerController.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        _onDetect(capture);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tidak ditemukan barcode pada gambar tersebut.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF182218),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menganalisis gambar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
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

    ref.read(diaryProvider.notifier).add(
          entryFood,
          _servings,
          _selectedMeal,
          _selectedDate,
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
      date: _selectedDate,
    );
  }

  Future<void> _pickDateTime() async {
    final result = await CaloraTimePickerSheet.show(
      context,
      initialDateTime: _selectedDate,
      title: 'Atur Waktu Catat',
      includeDate: true,
      activeMeal: _selectedMeal,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedDate = result.dateTime;
        _selectedMeal = result.suggestedMeal;
      });
    }
  }

  void _showMoreOptionsMenu() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: AppColors.accent),
                title: Text(
                  'Riwayat Scan Makanan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Lihat daftar makanan yang pernah discan',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ScanHistoryScreen.show(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dialpad_rounded, color: AppColors.accent),
                title: Text(
                  'Input Barcode Manual',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Ketik nomor barcode secara manual',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showManualBarcodeSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                title: Text(
                  'Reset Scanner',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _resetScan();
                },
              ),
            ],
          ),
        );
      },
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
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
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'diary.enterBarcodeNumber'.tr(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close_rounded),
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      hintText: 'diary.barcodeHint'.tr(),
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
                      fillColor: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 20),
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
                        foregroundColor: const Color(0xFF0F1410),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'diary.searchBarcodeAction'.tr(),
                        style: GoogleFonts.inter(
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

  // ── BUILD MAIN VIEWPORT ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultFrameWidth = math.min(size.width * 0.82, 300.0);
    final defaultFrameHeight = 190.0;
    final defaultHoleRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: defaultFrameWidth,
      height: defaultFrameHeight,
    );
    final activeHoleRect = _trackedBarcodeRect ?? defaultHoleRect;

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
            tapToFocus: true,
            errorBuilder: (context, error) {
              return _buildPermissionErrorState(context, error.errorCode.name);
            },
          ),

          // ── LAYER 2 & 3: Dynamic AR Tracking Reticle & Overlay Mask ──
          if (!_isNotFound && !_showProductFound)
            TweenAnimationBuilder<Rect?>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              tween: RectTween(
                begin: defaultHoleRect,
                end: activeHoleRect,
              ),
              builder: (context, rect, child) {
                final currentRect = rect ?? defaultHoleRect;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Dynamic Dimmed Overlay with Cutout
                    CustomPaint(
                      size: Size(size.width, size.height),
                      painter: _BarcodeOverlayPainter(
                        holeRect: currentRect,
                      ),
                    ),

                    // Tracking Reticle Frame & Laser Beam
                    Positioned(
                      left: currentRect.left,
                      top: currentRect.top,
                      width: currentRect.width,
                      height: currentRect.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Neon Corner Brackets
                          CustomPaint(
                            size: Size(currentRect.width, currentRect.height),
                            painter: _CornerBracketPainter(
                              color: _isLockedOn
                                  ? const Color(0xFFC7FF47)
                                  : AppColors.accent,
                              strokeWidth: _isLockedOn ? 5.2 : 4.5,
                              cornerLength: math.min(
                                currentRect.width * 0.22,
                                32.0,
                              ),
                              radius: 14.0,
                            ),
                          ),

                          // Animated Scan Laser Beam
                          if (!_isSearching)
                            AnimatedBuilder(
                              animation: _beamAnimation,
                              builder: (context, child) {
                                final topOffset = _beamAnimation.value *
                                    (currentRect.height - 6);
                                return Positioned(
                                  top: topOffset,
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    height: 3.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.accent
                                              .withValues(alpha: 0.0),
                                          AppColors.accent
                                              .withValues(alpha: 0.95),
                                          AppColors.accent
                                              .withValues(alpha: 0.0),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Lock-on Tracking Tag
                          if (_isLockedOn)
                            Positioned(
                              bottom: -28,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F1410),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.accent,
                                      width: 0.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'BARCODE TERDETEKSI',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent,
                                          letterSpacing: 0.5,
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
                  ],
                );
              },
            ),

          // ── LAYER 4: Finding Food Loading Overlay ──
          if (_isSearching)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.40),
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
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'diary.findingFood'.tr(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── LAYER 5: Error Banner Overlay ──
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
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _resetScan,
                      child: Text(
                        'diary.retry'.tr(),
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── LAYER 6: Top App Bar (Figma scan.png) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Tutup',
                  onTap: () => Navigator.pop(context),
                ),
                Text(
                  'Barcode Food Scanner',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                _buildCircleButton(
                  icon: Icons.more_horiz_rounded,
                  tooltip: 'Pilihan Lainnya',
                  onTap: _showMoreOptionsMenu,
                ),
              ],
            ),
          ),

          // ── LAYER 7: Bottom Floating Controls Bar (Figma scan.png) ──
          if (!_isNotFound && !_showProductFound && !_isSearching)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 26,
              left: 28,
              right: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flip Camera Circle Button
                  _buildCircleButton(
                    icon: Icons.cameraswitch_rounded,
                    tooltip: 'Putar Kamera',
                    onTap: _flipCamera,
                  ),

                  // Center Floating Capsule (Camera Active Pill + Gallery Icon)
                  Container(
                    height: 52,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121612).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Active Camera Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_camera_rounded,
                                size: 18,
                                color: Color(0xFF0F1410),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Camera',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F1410),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Gallery Button
                        GestureDetector(
                          onTap: _pickImageFromGallery,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            color: Colors.transparent,
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 21,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Torch Toggle Circle Button
                  _buildCircleButton(
                    icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    tooltip: 'Flash',
                    color: _isTorchOn ? AppColors.accent : Colors.white,
                    onTap: _toggleTorch,
                  ),
                ],
              ),
            ),

          // ── LAYER 8: Product Found Bottom Sheet (Figma pop up.png & detail.png) ──
          if (_showProductFound && _scannedFood != null)
            _buildProductFoundBottomSheet(context, isDark),

          // ── LAYER 9: Not Found Overlay ──
          if (_isNotFound) _buildNotFoundOverlay(context, isDark),
        ],
      ),
    );
  }

  // ── PRODUCT FOUND SHEET (FIGMA pop up.png & detail.png) ────────────────────

  Widget _buildProductFoundBottomSheet(BuildContext context, bool isDark) {
    final food = _scannedFood!;
    final baseCalories = food.calories;
    final totalCalories = (baseCalories * _servings).round();
    final totalProtein = food.proteinG * _servings;
    final totalCarbs = food.carbsG * _servings;
    final totalFat = food.fatG * _servings;

    double? totalGrams;
    if (food.portionGrams != null) {
      totalGrams = food.portionGrams! * _servings;
    }

    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final cardBg = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F6F1);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE5EAE1);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Center Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),

                  // 2. Title Header with optional collapse icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scan Barcode',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (_isReviewExpanded)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isReviewExpanded = false);
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222C22) : const Color(0xFFECEFEA),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.north_east_rounded,
                              size: 17,
                              color: textPrimary,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _resetScan,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222C22) : const Color(0xFFECEFEA),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Food Card (Matching Figma in both popup and detail)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        // White Squircle Thumbnail
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                              ? Image.network(
                                  food.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.restaurant_rounded,
                                    color: AppColors.accent,
                                    size: 28,
                                  ),
                                )
                              : const Icon(
                                  Icons.restaurant_rounded,
                                  color: AppColors.accent,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 14),

                        // Food Name & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                food.servingLabel.isNotEmpty
                                    ? '${food.servingLabel} · ${food.calories} kcal'
                                    : '1 Porsi (${(food.portionGrams ?? 100).round()}g) · ${food.calories} kcal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── POPUP STATE (pop up.png): 2 Action Buttons ──
                  if (!_isReviewExpanded) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Review Food Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isReviewExpanded = true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF232D23)
                                    : const Color(0xFFF0F3ED),
                                foregroundColor: textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                'Review Food',
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Add to Diary Button
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _addToFoodDiary,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: const Color(0xFF0F1410),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                'Add to Diary',
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F1410),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]

                  // ── DETAIL STATE (detail.png): Full Review & Customization ──
                  else ...[
                    const SizedBox(height: 14),

                    // Meal Type Pills (Breakfast, Lunch, Dinner, Snack)
                    Row(
                      children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((m) {
                        final isSelected = m.toLowerCase() == _selectedMeal.toLowerCase();
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedMeal = m);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent
                                      : (isDark
                                          ? AppColors.darkSurfaceAlt
                                          : const Color(0xFFF3F5F1)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : (isDark ? AppColors.darkBorder : const Color(0xFFE5E9E2)),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    m,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF0F1410)
                                          : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Quick Date & Time selector pill
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: isDark ? AppColors.accent : const Color(0xFF4D8500),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Waktu Catat: ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                DateUtils.isSameDay(_selectedDate, DateTime.now())
                                    ? 'Hari Ini, ${DateFormat('HH:mm').format(_selectedDate)}'
                                    : DateFormat('dd MMM, HH:mm').format(_selectedDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Ubah Jam',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.accent : const Color(0xFF427A00),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 13,
                              color: isDark ? AppColors.accent : const Color(0xFF427A00),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Total Calories Card with Flame (Figma detail.png)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total $totalCalories kcal',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 21,
                              color: Color(0xFFFF9500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2-Column: Macro Composition & Adjust Portion (Figma detail.png)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Macro Composition
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Macro Composition',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8E95A2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFigmaMacroItem(
                                label: 'Protein',
                                dotColor: const Color(0xFFFF4757), // Red
                                grams: totalProtein,
                                progressColor: const Color(0xFFFF4757),
                                textPrimary: textPrimary,
                              ),
                              const SizedBox(height: 6),
                              _buildFigmaMacroItem(
                                label: 'Carbs',
                                dotColor: const Color(0xFFFFA502), // Yellow
                                grams: totalCarbs,
                                progressColor: const Color(0xFFFFA502),
                                textPrimary: textPrimary,
                              ),
                              const SizedBox(height: 6),
                              _buildFigmaMacroItem(
                                label: 'Fat',
                                dotColor: const Color(0xFF8C7AE6), // Purple
                                grams: totalFat,
                                progressColor: const Color(0xFF8C7AE6),
                                textPrimary: textPrimary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Right Column: Adjust Portion (Segmented Toggle)
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adjust Portion',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8E95A2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF222B22) : const Color(0xFFEAF0E7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _isGramMode = false);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: !_isGramMode ? AppColors.accent : Colors.transparent,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Serving',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: !_isGramMode ? FontWeight.w800 : FontWeight.w600,
                                              color: !_isGramMode
                                                  ? const Color(0xFF0F1410)
                                                  : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          final baseG = food.portionGrams ?? 100.0;
                                          _gramController.text = (baseG * _servings).round().toString();
                                          setState(() => _isGramMode = true);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _isGramMode ? AppColors.accent : Colors.transparent,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Gram (g)',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: _isGramMode ? FontWeight.w800 : FontWeight.w600,
                                              color: _isGramMode
                                                  ? const Color(0xFF0F1410)
                                                  : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Portion Multiplier Pills (¼, ½, 1, 1½, 2, Custom) or Gram Input
                    if (!_isGramMode) ...[
                      Row(
                        children: [
                          _buildMultiplierPill('¼', 0.25, isDark),
                          const SizedBox(width: 6),
                          _buildMultiplierPill('½', 0.5, isDark),
                          const SizedBox(width: 6),
                          _buildMultiplierPill('1', 1.0, isDark),
                          const SizedBox(width: 6),
                          _buildMultiplierPill('1 ½', 1.5, isDark),
                          const SizedBox(width: 6),
                          _buildMultiplierPill('2', 2.0, isDark),
                          const SizedBox(width: 6),
                          _buildCustomMultiplierPill(isDark),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '= ${(totalGrams ?? 100).round()} g',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8E95A2),
                          ),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _gramController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.scale_rounded, size: 18),
                                suffixText: 'gram',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF1B221B) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                              ),
                              onChanged: (text) {
                                final g = double.tryParse(text);
                                if (g != null && g > 0) {
                                  final baseG = food.portionGrams ?? 100.0;
                                  setState(() => _servings = g / baseG);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Full-width Add to Diary Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _addToFoodDiary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: const Color(0xFF0F1410),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Add to Diary',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F1410),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper macro row item for detail.png
  Widget _buildFigmaMacroItem({
    required String label,
    required Color dotColor,
    required double grams,
    required Color progressColor,
    required Color textPrimary,
  }) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        Container(
          width: 38,
          height: 4.5,
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${grams.round()}g',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplierPill(String label, double value, bool isDark) {
    final isSelected = (_servings - value).abs() < 0.05;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _servings = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                : (isDark ? const Color(0xFF222B22) : const Color(0xFFF3F5F1)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent
                  : (isDark ? const Color(0xFF2E3A2E) : const Color(0xFFE5EAE1)),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF0F1410)
                  : (isDark ? Colors.white70 : const Color(0xFF374151)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomMultiplierPill(bool isDark) {
    final standardValues = [0.25, 0.5, 1.0, 1.5, 2.0];
    final isCustom = !standardValues.any((v) => (_servings - v).abs() < 0.05);

    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.selectionClick();
          final textCtrl = TextEditingController(text: _servings.toString());
          final customVal = await showDialog<double>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Kustomisasi Porsi', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              content: TextField(
                controller: textCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Jumlah porsi (misal 2.5)'),
                autofocus: true,
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    final parsed = double.tryParse(textCtrl.text);
                    Navigator.pop(ctx, parsed);
                  },
                  child: const Text('Pilih'),
                ),
              ],
            ),
          );
          if (customVal != null && customVal > 0) {
            setState(() => _servings = customVal);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isCustom
                ? AppColors.accent
                : (isDark ? const Color(0xFF222B22) : const Color(0xFFF3F5F1)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCustom
                  ? AppColors.accent
                  : (isDark ? const Color(0xFF2E3A2E) : const Color(0xFFE5EAE1)),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            isCustom ? '${_servings}x' : 'Custom',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isCustom ? FontWeight.w800 : FontWeight.w600,
              color: isCustom
                  ? const Color(0xFF0F1410)
                  : (isDark ? Colors.white70 : const Color(0xFF374151)),
            ),
          ),
        ),
      ),
    );
  }

  // ── PRODUCT NOT FOUND OVERLAY ─────────────────────────────────────────────

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
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'diary.productNotFoundDesc'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280),
              ),
            ),
            if (_lastScannedBarcode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_rounded, size: 16, color: Color(0xFF4D7800)),
                    const SizedBox(width: 8),
                    Text(
                      _lastScannedBarcode!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white : const Color(0xFF111827),
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
                        color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'diary.scanAgain'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
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
                      style: GoogleFonts.inter(
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

  // ── PERMISSION ERROR STATE ────────────────────────────────────────────────

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
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'diary.cameraAccessNeededSubtitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'diary.allowCamera'.tr(),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
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
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
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
    );
  }
}

/// Custom painter to darken surrounding area outside the central or tracked barcode frame
class _BarcodeOverlayPainter extends CustomPainter {
  const _BarcodeOverlayPainter({
    required this.holeRect,
  });

  final Rect holeRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final hole = RRect.fromRectAndRadius(
      holeRect,
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
    return oldDelegate.holeRect != holeRect;
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
