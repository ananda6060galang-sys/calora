import 'package:flutter/material.dart';

/// Soft, low-opacity shadows — used sparingly, only on surfaces that sit on
/// top of the cream background (stat cards, entry cards). Dark mode relies
/// on borders instead, since shadows barely read on near-black surfaces.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(bool isDark) {
    if (isDark) return const [];
    return [
      BoxShadow(
        color: const Color(0xFF1E1B18).withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }
}
