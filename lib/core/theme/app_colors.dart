import 'package:flutter/material.dart';

/// Calora's color system.
///
/// Design intent: warm white surfaces, sharp near-black text, one fresh lime
/// accent for energy, and a soft lavender accent for premium secondary moments.
class AppColors {
  AppColors._();

  // Brand accents
  static const Color accent = Color(0xFFB8FF3B);
  static const Color accentSoft = Color(0xFFE7FF8C);
  static const Color lavender = Color(0xFF8B7CFF);

  // Macro system
  static const Color protein = Color(0xFFFF6B57);
  static const Color carbs = Color(0xFFFFC24B);
  static const Color fat = Color(0xFF7C9CFF);

  // Semantic
  static const Color success = Color(0xFF3DDC84);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5A5F);

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF0E0F10);
  static const Color darkSurface = Color(0xFF17181A);
  static const Color darkSurfaceAlt = Color(0xFF1F2123);
  static const Color darkBorder = Color(0xFF2A2C2F);
  static const Color darkTextPrimary = Color(0xFFF5F6F5);
  static const Color darkTextSecondary = Color(0xFFA0A4A8);
  static const Color darkTextTertiary = Color(0xFF6B6F73);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFFAFAF8);
  static const Color lightGreenBg = Color(0xFFEFF5EB); // Soft pastel light-green background
  static const Color darkGreenBg = Color(0xFF101612);  // Subtle tinted dark surface
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF4F4F2);
  static const Color lightBorder = Color(0xFFECECEC);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFFAFA79C);

  // Meal-category tags
  static const Color mealBreakfast = Color(0xFF8BC34A);
  static const Color mealLunch = Color(0xFFF2B705);
  static const Color mealSnack = Color(0xFFFF8A3D);
  static const Color mealDinner = Color(0xFF8D93A6);
}
