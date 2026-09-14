import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color bg;
    late final Color fg;
    Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.accent;
        fg = const Color(0xFF0F1410);
        break;
      case AppButtonVariant.secondary:
        bg = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        );
        break;
      case AppButtonVariant.danger:
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
        break;
    }

    final child = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: fg),
              ),
            ],
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: 54,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: border,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
