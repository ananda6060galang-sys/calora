import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../../models/food.dart';
import '../providers/ai_scanner_provider.dart';
import '../providers/diary_provider.dart';

/// Full-screen in-app AI Food Scanner screen closely matching the Figma reference design.
class AiScannerSheet extends ConsumerStatefulWidget {
  const AiScannerSheet({
    super.key,
    this.initialMeal,
    required this.date,
  });

  final String? initialMeal;
  final DateTime date;

  @override
  ConsumerState<AiScannerSheet> createState() => _AiScannerSheetState();
}

class _AiScannerSheetState extends ConsumerState<AiScannerSheet>
    with SingleTickerProviderStateMixin {
  late String _selectedMeal;
  late TextEditingController _nameController;
  late TextEditingController _portionController;
  late TextEditingController _calController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  bool _isCameraMode = true;
  int _flashIndex = 0; // 0: off, 1: torch/on, 2: auto
  double _flipAngle = 0.0;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  String? _cameraError;

  late AnimationController _beamAnimationController;
  late Animation<double> _beamAnimation;

  @override
  void initState() {
    super.initState();
    _selectedMeal = (widget.initialMeal != null && widget.initialMeal!.trim().isNotEmpty)
        ? widget.initialMeal!
        : 'Lunch';

    _nameController = TextEditingController();
    _portionController = TextEditingController();
    _calController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();

    _beamAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _beamAnimation = CurvedAnimation(
      parent: _beamAnimationController,
      curve: Curves.easeInOut,
    );

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
    _nameController.dispose();
    _portionController.dispose();
    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _syncControllersWithFood(Food food) {
    _nameController.text = food.name;
    final portionStr = (food.portionGrams ?? 100).round().toString();
    _portionController.text = portionStr;
    _calController.text = food.calories.toString();
    _proteinController.text = (food.proteinG % 1 == 0)
        ? food.proteinG.toInt().toString()
        : food.proteinG.toStringAsFixed(1);
    _carbsController.text = (food.carbsG % 1 == 0)
        ? food.carbsG.toInt().toString()
        : food.carbsG.toStringAsFixed(1);
    _fatController.text = (food.fatG % 1 == 0)
        ? food.fatG.toInt().toString()
        : food.fatG.toStringAsFixed(1);
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // Fallback to ImagePicker if camera controller is not available
      ref.read(aiScannerProvider.notifier).captureAndScan(ImageSource.camera);
      return;
    }

    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      await ref.read(aiScannerProvider.notifier).scanXFile(photo);
    } catch (e) {
      debugPrint('Error taking picture with camera controller: $e');
      ref.read(aiScannerProvider.notifier).captureAndScan(ImageSource.camera);
    }
  }

  void _triggerCapture() {
    final state = ref.read(aiScannerProvider);
    if (state.status == AiScannerStatus.analyzing) return;

    if (_isCameraMode) {
      _takePicture();
    } else {
      ref.read(aiScannerProvider.notifier).captureAndScan(ImageSource.gallery);
    }
  }

  Future<void> _toggleFlash() async {
    setState(() {
      _flashIndex = (_flashIndex + 1) % 3;
    });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final mode = _flashIndex == 1
            ? FlashMode.torch
            : (_flashIndex == 2 ? FlashMode.auto : FlashMode.off);
        await _cameraController!.setFlashMode(mode);
      } catch (e) {
        debugPrint('Flash set error: $e');
      }
    }
  }

  Future<void> _toggleFlip() async {
    if (_cameras.length < 2) return;

    setState(() {
      _flipAngle += math.pi;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _isCameraInitialized = false;
    });

    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // =======================================================
              // [DEMO / MOCK CONTROLS] - 0 Token Gemini
              // Easy to delete when testing is finished.
              // =======================================================
              StatefulBuilder(
                builder: (context, setMenuState) {
                  final isMock =
                      ref.read(aiScannerProvider.notifier).isMockMode;
                  return SwitchListTile(
                    secondary: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.accent,
                    ),
                    title: Text(
                      context.locale.languageCode == 'id'
                          ? 'Mode Hemat Token (Mock)'
                          : 'Token Saver Mode (Mock)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      context.locale.languageCode == 'id'
                          ? 'Ambil foto makanan tanpa memakai token Gemini (0 token).'
                          : 'Snap food photos without using Gemini tokens (0 tokens).',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    value: isMock,
                    activeThumbColor: AppColors.accent,
                    onChanged: (val) {
                      ref.read(aiScannerProvider.notifier).toggleMockMode(val);
                      setMenuState(() {});
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  context.locale.languageCode == 'id'
                      ? 'Lihat Contoh Hasil Scan (0 Token)'
                      : 'Preview Sample Scan (0 Tokens)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  context.locale.languageCode == 'id'
                      ? 'Buka layar Food Details langsung tanpa scan.'
                      : 'Open Food Details directly without scanning.',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(aiScannerProvider.notifier).loadMockScanResult();
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.tips_and_updates_outlined),
                title: Text(
                  context.locale.languageCode == 'id'
                      ? 'Tips Pemindaian Makanan'
                      : 'Food Scanning Tips',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  context.locale.languageCode == 'id'
                      ? 'Posisikan seluruh piring di dalam bingkai dengan pencahayaan yang cukup.'
                      : 'Place the entire food plate inside the frame with clear lighting.',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded),
                title: Text(
                  context.locale.languageCode == 'id'
                      ? 'Reset Pemindai'
                      : 'Reset Scanner',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  ref.read(aiScannerProvider.notifier).reset();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _logToDiary(Food baseFood) {
    final name = baseFood.name.isNotEmpty
        ? baseFood.name
        : (_nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'Food');
    final portionGrams = baseFood.portionGrams ??
        double.tryParse(_portionController.text.trim()) ??
        100.0;
    final calories = baseFood.calories;
    final protein = baseFood.proteinG;
    final carbs = baseFood.carbsG;
    final fat = baseFood.fatG;

    final finalFood = Food(
      id: baseFood.id,
      name: name,
      servingLabel: '1 serving (${portionGrams.round()}g)',
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      category: _selectedMeal,
      portionGrams: portionGrams,
      source: 'ai_scan',
    );

    ref.read(diaryProvider.notifier).add(
          finalFood,
          1.0,
          _selectedMeal,
          widget.date,
          portionGrams: portionGrams,
        );

    ref.read(aiScannerProvider.notifier).reset();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${finalFood.name} added to $_selectedMeal!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiScannerState>(aiScannerProvider, (previous, next) {
      // Manage beam animation ticker based on analyzing state
      if (next.status == AiScannerStatus.analyzing) {
        if (!_beamAnimationController.isAnimating) {
          _beamAnimationController.repeat(reverse: true);
        }
      } else {
        if (_beamAnimationController.isAnimating) {
          _beamAnimationController.stop();
        }
      }

      // Manage camera preview and controller sync on success/idle
      if (next.status == AiScannerStatus.success) {
        try {
          _cameraController?.pausePreview();
        } catch (_) {}

        if (next.recognizedFood != null &&
            (previous == null ||
             previous.recognizedFood != next.recognizedFood ||
             previous.status != AiScannerStatus.success)) {
          _syncControllersWithFood(next.recognizedFood!);
        }
      } else if (next.status == AiScannerStatus.idle) {
        try {
          _cameraController?.resumePreview();
        } catch (_) {}
      }
    });

    final scannerState = ref.watch(aiScannerProvider);
    final size = MediaQuery.sizeOf(context);
    final frameSize = math.min(size.width * 0.76, 320.0);

    if (scannerState.status == AiScannerStatus.success &&
        scannerState.recognizedFood != null) {
      return _buildFoodDetailsView(scannerState);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── LAYER 1: Dominant Full-Screen Background ──
          if (scannerState.capturedFile != null)
            kIsWeb
                ? Image.network(
                    scannerState.capturedFile!.path,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Image.file(
                    File(scannerState.capturedFile!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
          else if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? size.width,
                  height: _cameraController!.value.previewSize?.width ?? size.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            _buildCameraViewportPlaceholder(),

          // Dark vignette overlay on top & bottom for high contrast controls
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.50),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.70),
                  ],
                  stops: const [0.0, 0.20, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // ── LAYER 2: Four-Corner Scanning Frame ──
          Align(
            alignment: const Alignment(0.0, -0.20),
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(frameSize, frameSize),
                    painter: const _CornerBracketsPainter(
                      color: Colors.white,
                      strokeWidth: 5.5,
                      cornerLength: 44.0,
                      cornerRadius: 16.0,
                    ),
                  ),
                  if (scannerState.status == AiScannerStatus.analyzing)
                    AnimatedBuilder(
                      animation: _beamAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: (frameSize - 4) * _beamAnimation.value,
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.0),
                                  AppColors.accent,
                                  AppColors.accent.withValues(alpha: 0.0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
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

          // ── LAYER 3: Top Navigation Bar ──
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    _buildTopCircleButton(
                      icon: Icons.close_rounded,
                      onTap: () {
                        ref.read(aiScannerProvider.notifier).reset();
                        Navigator.of(context).pop();
                      },
                    ),

                    // Centered title
                    Text(
                      'AI Scanner',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),

                    // Options / more button
                    _buildTopCircleButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: _showMoreMenu,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── LAYER 4: Bottom Camera / Gallery Switcher & Controls ──
          if (scannerState.status != AiScannerStatus.success)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Camera / Gallery switcher pill placed higher up
                      _buildModeSwitcher(),
                      const SizedBox(height: 60),

                      // Capture controls row (Flash - Shutter - Flip)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Flash control
                            _buildSideControlButton(
                              child: Icon(
                                _flashIndex == 1
                                    ? Icons.flash_on_rounded
                                    : (_flashIndex == 2
                                        ? Icons.flash_auto_rounded
                                        : Icons.flash_off_rounded),
                                color: _flashIndex > 0
                                    ? AppColors.accent
                                    : Colors.white,
                                size: 22,
                              ),
                              onTap: _toggleFlash,
                            ),

                            // Large Circular Shutter button
                            _buildShutterButton(
                              isAnalyzing: scannerState.status == AiScannerStatus.analyzing,
                              onTap: _triggerCapture,
                            ),

                            // Camera flip control
                            _buildSideControlButton(
                              child: AnimatedRotation(
                                turns: _flipAngle / (2 * math.pi),
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOutBack,
                                child: const Icon(
                                  Icons.cached_rounded,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              onTap: _toggleFlip,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── LAYER 5: Status Overlays ──
          if (scannerState.status == AiScannerStatus.analyzing)
            _buildAnalyzingOverlay(),

          if (scannerState.status == AiScannerStatus.error)
            _buildErrorOverlay(scannerState),
        ],
      ),
    );
  }

  // ── Sub-widgets & Painters ─────────────────────────────────

  Widget _buildCameraViewportPlaceholder() {
    return Container(
      color: const Color(0xFF0C0E11),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.15,
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _ViewportGridPainter(),
            ),
          ),
          if (_cameraError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white54,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.locale.languageCode == 'id'
                        ? 'Memuat kamera perangkat...'
                        : 'Loading device camera...',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF0E0F10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      context.locale.languageCode == 'id'
                          ? 'Coba Sambungkan Kamera'
                          : 'Retry Camera',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      setState(() {
                        _cameraError = null;
                        _isCameraInitialized = false;
                      });
                      _initCamera();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Camera Tab
          GestureDetector(
            onTap: () {
              if (!_isCameraMode) {
                setState(() => _isCameraMode = true);
                ref.read(aiScannerProvider.notifier).reset();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: _isCameraMode
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 7)
                  : const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: _isCameraMode ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 18,
                    color: _isCameraMode
                        ? const Color(0xFF0E0F10)
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                  if (_isCameraMode) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Camera',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0E0F10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),

          // Gallery Tab
          GestureDetector(
            onTap: () {
              if (_isCameraMode) {
                setState(() => _isCameraMode = false);
              }
              // Immediately pick when tapped on gallery icon
              ref
                  .read(aiScannerProvider.notifier)
                  .captureAndScan(ImageSource.gallery);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: !_isCameraMode
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 7)
                  : const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: !_isCameraMode ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 19,
                    color: !_isCameraMode
                        ? const Color(0xFF0E0F10)
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                  if (!_isCameraMode) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Gallery',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0E0F10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShutterButton({
    required bool isAnalyzing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isAnalyzing ? null : onTap,
      child: Container(
        height: 84,
        width: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4.5,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF16181B),
          ),
          alignment: Alignment.center,
          child: isAnalyzing
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 3,
                  ),
                )
              : SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const CustomPaint(
                        size: Size(38, 38),
                        painter: _CornerBracketsPainter(
                          color: Colors.white,
                          strokeWidth: 2.8,
                          cornerLength: 8.5,
                          cornerRadius: 4.5,
                        ),
                      ),
                      Icon(
                        _isCameraMode
                            ? Icons.camera_alt_rounded
                            : Icons.add_photo_alternate_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSideControlButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Align(
      alignment: const Alignment(0.0, 0.46),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141619).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.8,
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'diary.analyzingFood'.tr(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.locale.languageCode == 'id'
                        ? 'Menganalisis nutrisi & porsi dengan AI...'
                        : 'Estimating nutrients & portion with AI...',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(AiScannerState state) {
    return Align(
      alignment: const Alignment(0.0, 0.46),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1414).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
            const SizedBox(height: 10),
            Text(
              'diary.somethingWentWrong'.tr(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.errorMessage ?? 'diary.scanError'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF0E0F10),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () => ref.read(aiScannerProvider.notifier).reset(),
              child: Text(
                'diary.retry'.tr(),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodDetailsView(AiScannerState scannerState) {
    final food = scannerState.recognizedFood!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final confidencePct = (scannerState.confidence * 100).round();

    final totalMacros = food.proteinG + food.fatG + food.carbsG;
    final proteinProgress = totalMacros > 0
        ? (food.proteinG / totalMacros).clamp(0.15, 0.90)
        : 0.33;
    final fatProgress = totalMacros > 0
        ? (food.fatG / totalMacros).clamp(0.15, 0.90)
        : 0.33;
    final carbsProgress = totalMacros > 0
        ? (food.carbsG / totalMacros).clamp(0.15, 0.90)
        : 0.33;

    final mealLabel = (food.category.trim().isNotEmpty &&
            ['Breakfast', 'Lunch', 'Dinner', 'Snack'].any((m) =>
                m.toLowerCase() == food.category.trim().toLowerCase()))
        ? food.category.toUpperCase()
        : _selectedMeal.toUpperCase();
    final portionLabel = '${(food.portionGrams ?? 100).round()} G';

    final content = Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFE5E7EB),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── 1. Full-bleed food image occupying upper portion ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.54,
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (scannerState.capturedFile != null)
                    kIsWeb
                        ? Image.network(
                            scannerState.capturedFile!.path,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(scannerState.capturedFile!.path),
                            fit: BoxFit.cover,
                          )
                  else
                    Container(
                      color: const Color(0xFF1E2124),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white38,
                        size: 64,
                      ),
                    ),

                  // Subtle top gradient for high contrast buttons
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.50),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. Bottom Food Details Sheet ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: size.height * 0.58,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Center Drag Handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Category & Portion Pills Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPillTag(mealLabel, isDark),
                          const SizedBox(width: 10),
                          _buildPillTag(portionLabel, isDark),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Large Food Name
                      Text(
                        food.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Total Calories Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F7EC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE5EFE0),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'diary.totalKcal'.tr(args: [food.calories.toString()]),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '🔥',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Macro Cards (Protein, Fat, Carbs)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMacroCard(
                              label: 'Protein',
                              grams: food.proteinG,
                              progress: proteinProgress,
                              color: const Color(0xFF8AC926),
                              trackColor: isDark
                                  ? const Color(0xFF8AC926).withValues(alpha: 0.20)
                                  : const Color(0xFFE5F7CB),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMacroCard(
                              label: 'Fat',
                              grams: food.fatG,
                              progress: fatProgress,
                              color: const Color(0xFF00B4D8),
                              trackColor: isDark
                                  ? const Color(0xFF00B4D8).withValues(alpha: 0.20)
                                  : const Color(0xFFDDF3F8),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMacroCard(
                              label: 'Carbs',
                              grams: food.carbsG,
                              progress: carbsProgress,
                              color: const Color(0xFFFF5722),
                              trackColor: isDark
                                  ? const Color(0xFFFF5722).withValues(alpha: 0.20)
                                  : const Color(0xFFFFE7E0),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Subtle AI Estimate & Confidence Caption
                      Text(
                        '✦ ${'diary.aiEstimateNote'.tr(args: [confidencePct.toString()])}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bottom Actions: Update Details & Add Meal
                      Row(
                        children: [
                          // Update Details Button
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppColors.darkSurfaceAlt
                                      : const Color(0xFFF1F3F5),
                                  foregroundColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                    side: BorderSide(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : const Color(0xFFE5E7EB),
                                      width: 1.0,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => _showUpdateDetailsSheet(food),
                                child: Text(
                                  'diary.updateDetails'.tr(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Add Meal Button
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: const Color(0xFF0E0F10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => _logToDiary(food),
                                child: Text(
                                  'diary.addMeal'.tr(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0E0F10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Top Navigation Overlay ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Circular White Back Button
                    _buildTopWhiteButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => ref.read(aiScannerProvider.notifier).reset(),
                    ),

                    // Title: Food Details
                    Text(
                      'diary.foodDetails'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        shadows: const [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),

                    // Circular White Close Button
                    _buildTopWhiteButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildTopWhiteButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: const Color(0xFF1E293B),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPillTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? Colors.white70 : const Color(0xFF374151),
        ),
      ),
    );
  }



  Widget _buildMacroCard({
    required String label,
    required double grams,
    required double progress,
    required Color color,
    required Color trackColor,
    required bool isDark,
  }) {
    final displayGrams = grams.round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF6F8F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFEEF2E8),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 66,
            height: 66,
            child: CustomPaint(
              painter: _MacroRingPainter(
                progress: progress,
                trackColor: trackColor,
                progressColor: color,
                strokeWidth: 4.8,
              ),
              child: Center(
                child: Text(
                  '${displayGrams}g',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateDetailsSheet(Food food) {
    _syncControllersWithFood(food);
    final meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    String sheetMeal = _selectedMeal;
    if (food.category.trim().isNotEmpty &&
        meals.any((m) => m.toLowerCase() == food.category.trim().toLowerCase())) {
      sheetMeal = meals.firstWhere(
          (m) => m.toLowerCase() == food.category.trim().toLowerCase());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetInnerContext, setSheetState) {
            final isDark = Theme.of(sheetInnerContext).brightness == Brightness.dark;
            final sheetHeight = MediaQuery.sizeOf(sheetInnerContext).height * 0.85;

            return RepaintBoundary(
              child: Container(
                height: sheetHeight,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // Static Header: Drag handle & Title Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBorder : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'diary.updateDetails'.tr(),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => Navigator.of(sheetContext).pop(),
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dedicated Scrollable Form Area with Keyboard Avoidance
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            20,
                            4,
                            20,
                            24 + MediaQuery.viewInsetsOf(sheetInnerContext).bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Meal Type Chips
                              Row(
                                children: meals.map((m) {
                                  final isSel = m.toLowerCase() == sheetMeal.toLowerCase();
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: GestureDetector(
                                        onTap: () {
                                          setSheetState(() => sheetMeal = m);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? AppColors.accent
                                                : (isDark
                                                    ? AppColors.darkSurfaceAlt
                                                    : AppColors.lightSurfaceAlt),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSel
                                                  ? AppColors.accent
                                                  : (isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.lightBorder),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            m,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight:
                                                  isSel ? FontWeight.w700 : FontWeight.w500,
                                              color: isSel
                                                  ? const Color(0xFF0E0F10)
                                                  : (isDark
                                                      ? AppColors.darkTextSecondary
                                                      : AppColors.lightTextSecondary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Food Name
                              _buildInputField(
                                label: 'diary.foodRequest.foodNameLabel'.tr(),
                                controller: _nameController,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),

                              // Portion & Calories Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      label: '${'diary.serving'.tr()} (g)',
                                      controller: _portionController,
                                      isDark: isDark,
                                      isNumber: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Calories (kcal)',
                                      controller: _calController,
                                      isDark: isDark,
                                      isNumber: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Macros Row: Protein, Carbs, Fat
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Protein (g)',
                                      controller: _proteinController,
                                      isDark: isDark,
                                      isNumber: true,
                                      accentColor: AppColors.protein,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Carbs (g)',
                                      controller: _carbsController,
                                      isDark: isDark,
                                      isNumber: true,
                                      accentColor: AppColors.carbs,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Fat (g)',
                                      controller: _fatController,
                                      isDark: isDark,
                                      isNumber: true,
                                      accentColor: AppColors.fat,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Disclaimer box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceAlt
                                      : AppColors.lightSurfaceAlt,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'diary.aiEstimateDisclaimer'.tr(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          height: 1.35,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Apply Changes Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: const Color(0xFF0E0F10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    final name = _nameController.text.trim();
                                    final portion = double.tryParse(_portionController.text.trim());
                                    final cal = int.tryParse(_calController.text.trim());
                                    final pro = double.tryParse(_proteinController.text.trim());
                                    final carbs = double.tryParse(_carbsController.text.trim());
                                    final fat = double.tryParse(_fatController.text.trim());

                                    setState(() {
                                      _selectedMeal = sheetMeal;
                                    });

                                    ref.read(aiScannerProvider.notifier).updateFood(
                                      name: name.isNotEmpty ? name : null,
                                      portionGrams: portion,
                                      calories: cal,
                                      proteinG: pro,
                                      carbsG: carbs,
                                      fatG: fat,
                                      category: sheetMeal,
                                    );

                                    Navigator.of(sheetContext).pop();
                                  },
                                  child: Text(
                                    sheetInnerContext.locale.languageCode == 'id'
                                        ? 'Terapkan Perubahan'
                                        : 'Apply Changes',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0E0F10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    bool isNumber = false,
    Color? accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: accentColor ??
                (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          scrollPadding: const EdgeInsets.only(bottom: 80.0, top: 20.0),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the 4 separate L-shaped corner brackets matching Figma.
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  const _CornerBracketsPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = strokeWidth + 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final l = cornerLength;

    // Top-Left corner
    final tlPath = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(l, 0);

    // Top-Right corner
    final trPath = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, l);

    // Bottom-Left corner
    final blPath = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(l, h);

    // Bottom-Right corner
    final brPath = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - l);

    final paths = [tlPath, trPath, blPath, brPath];
    for (final path in paths) {
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle grid pattern for camera viewfinder backdrop when no image is loaded.
class _ViewportGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    // Center crosshair
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 16, cy), Offset(cx + 16, cy), paint);
    canvas.drawLine(Offset(cx, cy - 16), Offset(cx, cy + 16), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular progress ring painter for macro cards matching the reference design.
class _MacroRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _MacroRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 4.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress.clamp(0.05, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.trackColor != trackColor;
}
