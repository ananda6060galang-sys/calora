import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Defaults to light — the warm cream premium look is Calora's flagship
/// mode as of the mobile redesign. Dark mode remains available in Settings.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
