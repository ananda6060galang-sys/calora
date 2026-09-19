import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../../models/food.dart';
import '../../../models/mock_data.dart';
import '../food_diary_screen.dart';
import '../food_request_sheet.dart';

/// Full-screen Barcode Scanner matching Calora's AI Food Scanner visual language.
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
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  String? _cameraError;
  int _flashIndex = 0; // 0: off, 1: torch/on, 2: auto
  bool _isScanning = true;
  bool _isNotFound = false;

  late AnimationController _beamAnimationController;
  late Animation<double> _beamAnimation;

  @override
  void initState() {
    super.initState();
    _beamAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _beamAnimation = CurvedAnimation(
      parent: _beamAnimationController,
      curve: Curves.easeInOut,
    );
    _beamAnimationController.repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      if (appCameras.isNotEmpty) {
        _cameras = appCameras;
      } else {
        _cameras = await availableCameras();
      }
      if (_cameras.isNotEmpty) {
        await _setupCameraController(_cameras[_selectedCameraIndex]);
      } else {
        if (mounted) {
          setState(() {
            _cameraError = 'No camera found on this device';
          });
        }
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _cameraError = e.toString();
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final controller = CameraController(
      description,
      kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      debugPrint('Camera controller init error: $e');
      if (mounted) {
        setState(() {
          _cameraError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _beamAnimationController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    setState(() {
      _flashIndex = (_flashIndex + 1) % 3;
    });

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      if (_flashIndex == 1) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      } else if (_flashIndex == 2) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      } else {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (_) {}
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isCameraInitialized = false;
    });
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  void _onBarcodeDetected(Food food) {
    if (!mounted) return;
    _beamAnimationController.stop();

    // If popped back to AddFoodSheet, return the food
    if (Navigator.canPop(context)) {
      Navigator.pop(context, food);
    } else {
      // Standalone flow: Open AddFoodSheet with initialFood
      FoodDiaryScreen.openAddFoodSheet(
        context,
        ref,
        meal: widget.meal,
        date: widget.date,
        initialFood: food,
      );
    }
  }

  void _simulateDetection({bool success = true}) {
    if (!success) {
      setState(() {
        _isNotFound = true;
        _isScanning = false;
      });
      _beamAnimationController.stop();
      return;
    }

    // Pick a packaged item from demo foods
    final sampleFood = demoFoods.firstWhere(
      (f) =>
          f.name.toLowerCase().contains('yogurt') ||
          f.name.toLowerCase().contains('chicken'),
      orElse: () => demoFoods.first,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'diary.barcodeSimulated'.tr(args: ['899276100234']),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1600),
      ),
    );

    _onBarcodeDetected(sampleFood);
  }

  void _resetScan() {
    setState(() {
      _isNotFound = false;
      _isScanning = true;
    });
    _beamAnimationController.repeat(reverse: true);
  }

  void _showMoreMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (menuCtx) {
        final isDark = Theme.of(menuCtx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(menuCtx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.accent,
                ),
                title: Text(
                  'diary.simulateBarcodeFound'.tr(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.locale.languageCode == 'id'
                      ? 'Simulasi menemukan makanan kemasan via barcode.'
                      : 'Simulate finding packaged food via barcode.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(menuCtx);
                  _simulateDetection(success: true);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.warning,
                ),
                title: Text(
                  'diary.simulateBarcodeNotFound'.tr(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.locale.languageCode == 'id'
                      ? 'Simulasi barcode tidak ditemukan di database.'
                      : 'Simulate barcode not found in database.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(menuCtx);
                  _simulateDetection(success: false);
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(
                  'diary.scanAgain'.tr(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(menuCtx);
                  _resetScan();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive barcode frame dimensions
    final frameWidth = math.min(size.width * 0.78, 310.0);
    final frameHeight = math.min(size.height * 0.24, 190.0);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── LAYER 1: Camera Preview ──
          if (_isCameraInitialized && _cameraController != null)
            RepaintBoundary(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? size.width,
                    height: _cameraController!.value.previewSize?.width ?? size.height,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            _buildCameraViewportPlaceholder(),

          // ── LAYER 2: Dimmed Mask & Barcode Viewport ──
          if (!_isNotFound)
            CustomPaint(
              size: Size(size.width, size.height),
              painter: _BarcodeOverlayPainter(
                frameWidth: frameWidth,
                frameHeight: frameHeight,
              ),
            ),

          // ── LAYER 3: Barcode Guide Frame & Beam ──
          if (!_isNotFound)
            Center(
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: Stack(
                  children: [
                    // Outer border with Calora accent corner brackets
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: Size(frameWidth, frameHeight),
                      painter: _CornerBracketPainter(
                        color: AppColors.accent,
                        strokeWidth: 3.5,
                        cornerLength: 22.0,
                        radius: 16.0,
                      ),
                    ),

                    // Subtle horizontal scanning beam
                    if (_isScanning)
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
                                    color: AppColors.accent.withValues(alpha: 0.5),
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
          if (!_isNotFound)
            Positioned(
              left: 24,
              right: 24,
              top: (size.height / 2) + (frameHeight / 2) + 24,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
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
                        Text(
                          'diary.alignBarcode'.tr(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'diary.scanningBarcode'.tr(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

          // ── LAYER 5: Not Found State Overlay ──
          if (_isNotFound) _buildNotFoundOverlay(context, isDark),

          // ── LAYER 6: Permission / Error Overlay ──
          if (_cameraError != null && !_isCameraInitialized)
            _buildPermissionErrorState(context),

          // ── LAYER 7: Top App Bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                Text(
                  'diary.scanBarcode'.tr(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                _buildCircleButton(
                  icon: _flashIndex == 1
                      ? Icons.flash_on_rounded
                      : (_flashIndex == 2
                          ? Icons.flash_auto_rounded
                          : Icons.flash_off_rounded),
                  color: _flashIndex > 0 ? AppColors.accent : Colors.white,
                  onTap: _toggleFlash,
                ),
                const SizedBox(width: 10),
                _buildCircleButton(
                  icon: Icons.cameraswitch_rounded,
                  onTap: _flipCamera,
                ),
                const SizedBox(width: 10),
                _buildCircleButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _showMoreMenu(context),
                ),
              ],
            ),
          ),

          // ── LAYER 8: Bottom Capture Action Button ──
          if (!_isNotFound)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 28,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _simulateDetection(success: true),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF0F1410),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildCameraViewportPlaceholder() {
    return Container(
      color: const Color(0xFF111417),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'diary.scanningBarcode'.tr(),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundOverlay(BuildContext context, bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
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
              'diary.foodNotFoundSubtitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'diary.scanAgain'.tr(),
                      style: GoogleFonts.plusJakartaSans(
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
                      final sheetRef = ref;
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => FoodRequestSheet(ref: sheetRef),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF0F1410),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'diary.requestFood'.tr(),
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

  Widget _buildPermissionErrorState(BuildContext context) {
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
              onPressed: _initCamera,
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
          ],
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
