import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/meal_time_resolver.dart';
import '../../../models/scan_history_item.dart';
import '../food_diary_screen.dart';
import '../providers/diary_provider.dart';
import '../providers/scan_history_provider.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ScanHistoryScreen(),
      ),
    );
  }

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: AI Scan, 2: Barcode

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = ref.watch(scanHistoryProvider);
    final notifier = ref.read(scanHistoryProvider.notifier);

    final filteredList = history.where((item) {
      if (_selectedFilterIndex == 1) return item.scanType == ScanType.ai;
      if (_selectedFilterIndex == 2) return item.scanType == ScanType.barcode;
      return true;
    }).toList();

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE5E9E2);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: textPrimary,
          ),
        ),
        title: Text(
          'Riwayat Scan Makanan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (history.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearAll(context),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.danger),
              label: Text(
                'Hapus Semua',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (Semua, AI Scan, Barcode)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(0, 'Semua (${history.length})', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, 'Scan AI', isDark, icon: Icons.camera_alt_outlined),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, 'Barcode', isDark, icon: Icons.qr_code_scanner_rounded),
                ],
              ),
            ),
          ),

          // Main List Content
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(isDark, textPrimary, textSecondary)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildHistoryCard(
                        item: item,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onDelete: () {
                          HapticFeedback.lightImpact();
                          notifier.deleteScan(item.id);
                        },
                        onLogToDiary: () => _logItemToDiary(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, bool isDark, {IconData? icon}) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilterIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.accent : const Color(0xFF18261B))
              : (isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEAEFE7)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? (isDark ? const Color(0xFF0F1410) : Colors.white)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFF0F1410) : Colors.white)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required ScanHistoryItem item,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onDelete,
    required VoidCallback onLogToDiary,
  }) {
    final formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(item.scannedAt);
    final isAi = item.scanType == ScanType.ai;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image / Icon Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 56,
              height: 56,
              color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEDF2E8),
              child: _buildThumbnail(item.imagePath, isAi, isDark),
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge & Timestamp Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isAi
                            ? const Color(0xFF388E3C).withValues(alpha: 0.15)
                            : const Color(0xFF0288D1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAi ? Icons.camera_alt_rounded : Icons.qr_code_2_rounded,
                            size: 11,
                            color: isAi ? const Color(0xFF388E3C) : const Color(0xFF0288D1),
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            isAi ? 'Scan AI' : 'Barcode',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isAi ? const Color(0xFF388E3C) : const Color(0xFF0288D1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formattedTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Food Name
                Text(
                  item.foodName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Calories & Macros
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      '${item.calories} kcal',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.accent : const Color(0xFF2E6312),
                      ),
                    ),
                    Text(
                      '· P: ${item.proteinG.round()}g',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8AC926),
                      ),
                    ),
                    Text(
                      '· C: ${item.carbsG.round()}g',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF5722),
                      ),
                    ),
                    Text(
                      '· F: ${item.fatG.round()}g',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00B4D8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions Column (Log to Diary & Delete)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onLogToDiary,
                tooltip: 'Catat ke Food Diary',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: const Color(0xFF0F1410),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Hapus dari Riwayat',
                style: IconButton.styleFrom(
                  foregroundColor: textSecondary,
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String? imagePath, bool isAi, bool isDark) {
    if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _defaultIcon(isAi, isDark),
        );
      }
    }
    return _defaultIcon(isAi, isDark);
  }

  Widget _defaultIcon(bool isAi, bool isDark) {
    return Center(
      child: Icon(
        isAi ? Icons.restaurant_rounded : Icons.qr_code_scanner_rounded,
        size: 26,
        color: isDark ? AppColors.accent.withValues(alpha: 0.6) : const Color(0xFF5BA300),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEAF5E5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.history_rounded,
                size: 36,
                color: isDark ? AppColors.accent : const Color(0xFF5BA300),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Riwayat Scan',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Makanan yang kamu scan dengan kamera AI atau Barcode akan otomatis tersimpan di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logItemToDiary(ScanHistoryItem item) {
    HapticFeedback.mediumImpact();
    final food = item.toFood();
    final meal = MealTimeResolver.resolveCurrentMeal(requestedMeal: item.suggestedMeal);
    final now = DateTime.now();

    ref.read(diaryProvider.notifier).add(
          food,
          1.0,
          meal,
          now,
          portionGrams: item.portionGrams,
        );

    FoodDiaryScreen.showFoodLoggedFeedback(
      context,
      ref,
      foodName: food.name,
      meal: meal,
      entryCalories: food.calories,
      date: now,
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus Semua Riwayat?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Semua daftar makanan yang pernah kamu scan akan dihapus dari riwayat perangkat ini.',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(scanHistoryProvider.notifier).clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
