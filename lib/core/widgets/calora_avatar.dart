import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Centralized, reusable avatar widget for Calora.
///
/// Renders remote network avatar from Supabase Storage when [avatarUrl] is present.
/// Gracefully falls back to Calora's signature lime initial letter badge if [avatarUrl]
/// is null, empty, or fails to load.
class CaloraAvatar extends StatelessWidget {
  const CaloraAvatar({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    this.size = 44,
    this.isDark,
    this.border,
    this.showBorder = false,
    this.isUploading = false,
  });

  final String? avatarUrl;
  final String displayName;
  final double size;
  final bool? isDark;
  final BoxBorder? border;
  final bool showBorder;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final hasValidUrl = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final defaultBorder = Border.all(
      color: effectiveIsDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: 1.0,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveIsDark
            ? AppColors.darkSurfaceAlt
            : const Color(0xFFE9F2E2),
        border: showBorder ? (border ?? defaultBorder) : null,
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            hasValidUrl
                ? Image.network(
                    avatarUrl!.trim(),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildFallback(effectiveIsDark, isLoading: true);
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Gracefully fall back to signature Calora avatar badge on broken URL / network error
                      return _buildFallback(effectiveIsDark);
                    },
                  )
                : _buildFallback(effectiveIsDark),
            if (isUploading)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(bool isDark, {bool isLoading = false}) {
    final cleanName = displayName.trim();
    final initialLetter =
        cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'C';

    return Container(
      width: size,
      height: size,
      color: AppColors.accent,
      alignment: Alignment.center,
      child: isLoading
          ? SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F1410)),
              ),
            )
          : Text(
              initialLetter,
              style: GoogleFonts.inter(
                fontSize: size * 0.40,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F1410),
              ),
            ),
    );
  }
}
