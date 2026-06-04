import 'package:flutter/material.dart';

/// Futuristic XOX palette (spec §3.1): bordeaux (player A) vs dark luxury gold (player B), on a deep
/// near-black backdrop for a polished, premium feel.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0E0B10);
  static const Color surface = Color(0xFF1A151E);
  static const Color surfaceHigh = Color(0xFF241D2A);

  /// Player A — bordeaux.
  static const Color playerA = Color(0xFF7B1E33);
  static const Color playerAGlow = Color(0xFFB23A52);

  /// Player B — dark luxury gold.
  static const Color playerB = Color(0xFFB8902E);
  static const Color playerBGlow = Color(0xFFE6C158);

  static const Color accent = Color(0xFFE6C158);
  static const Color textPrimary = Color(0xFFF3EEF6);
  static const Color textMuted = Color(0xFF9B91A3);
  static const Color danger = Color(0xFFD9544D);
  static const Color hint = Color(0xFF4CC38A); // "complete the shape here" highlight
  static const Color gridLine = Color(0xFF3A3040);

  /// Owner → primary colour.
  static Color owner(int owner) => owner == 0 ? playerA : playerB;

  /// Owner → glow/highlight colour.
  static Color ownerGlow(int owner) => owner == 0 ? playerAGlow : playerBGlow;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        surface: AppColors.surface,
        secondary: AppColors.playerA,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  /// Standard animation durations (spec §8: fluid 60fps placement, capture, rail slide).
  static const Duration place = Duration(milliseconds: 220);
  static const Duration capture = Duration(milliseconds: 300);
  static const Duration railSlide = Duration(milliseconds: 280);
  static const Duration screen = Duration(milliseconds: 350);
}
