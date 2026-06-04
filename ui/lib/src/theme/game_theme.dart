import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All visual tokens for one identity (colours, gradients, fonts). Two instances exist —
/// [GameTheme.futuristic] (warm luxury) and [GameTheme.classic] (cold metallic). Widgets read from
/// the active theme via [GameTheme.of] and never hardcode colours, so the shared board renders either
/// look (spec: UI Themes feature §1–§2).
class GameTheme {
  // Surfaces
  final Gradient background;
  final Gradient frameRim; // thin metallic rim around the board frame
  final Gradient panel; // frame panel fill
  final Color cell;
  final Color cellEmptyBorder;
  final Color ink;
  final Color muted;
  final Color accent; // gold (fut) / steel-hi (classic)
  final Color accentGlow;
  final Color danger;

  /// Per-owner disc gradient stops `[highlight, base, low]` and glow colour.
  final List<List<Color>> _discStops;
  final List<Color> _discGlow;

  const GameTheme({
    required this.background,
    required this.frameRim,
    required this.panel,
    required this.cell,
    required this.cellEmptyBorder,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentGlow,
    required this.danger,
    required List<List<Color>> discStops,
    required List<Color> discGlow,
  })  : _discStops = discStops,
        _discGlow = discGlow;

  List<Color> discStops(int owner) => _discStops[owner & 1];
  Color discGlow(int owner) => _discGlow[owner & 1];
  Color ownerColor(int owner) => _discStops[owner & 1][1];

  // ---- typography ----
  TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.cinzel(fontSize: size, fontWeight: weight, color: color ?? ink, letterSpacing: 1.5);

  TextStyle label(double size, {Color? color, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: weight, color: color ?? ink, letterSpacing: 0.5);

  // ---- instances ----

  static const GameTheme futuristic = GameTheme(
    background: RadialGradient(
      center: Alignment(-0.15, -0.35),
      radius: 1.25,
      colors: [Color(0xFF241813), Color(0xFF120C08), Color(0xFF070504)],
      stops: [0.0, 0.55, 1.0],
    ),
    frameRim: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF8A6A1D),
        Color(0xFFF6E6A8),
        Color(0xFFC79A3A),
        Color(0xFF4A3712),
        Color(0xFFF6E6A8),
        Color(0xFF8A6A1D),
      ],
    ),
    panel: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1B130C), Color(0xFF0E0A06)],
    ),
    cell: Color(0xFF15100B),
    cellEmptyBorder: Color(0xFF3A2E1A),
    ink: Color(0xFFF4ECD8),
    muted: Color(0xFF9A8A6A),
    accent: Color(0xFFD4AF37),
    accentGlow: Color(0xFFF6E6A8),
    danger: Color(0xFFD8556B),
    discStops: [
      [Color(0xFFD8556B), Color(0xFF9B2335), Color(0xFF5E121D)], // owner 0 — bordeaux
      [Color(0xFFF6E6A8), Color(0xFFC79A3A), Color(0xFF8A6A1D)], // owner 1 — gold
    ],
    discGlow: [Color(0xFFD8556B), Color(0xFFD4AF37)],
  );

  static const GameTheme classic = GameTheme(
    background: RadialGradient(
      center: Alignment(-0.15, -0.35),
      radius: 1.25,
      colors: [Color(0xFF1C2029), Color(0xFF0E1016), Color(0xFF06070A)],
      stops: [0.0, 0.55, 1.0],
    ),
    frameRim: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF3A3F4B),
        Color(0xFFEEF1F6),
        Color(0xFFAAB0BE),
        Color(0xFF3A3F4B),
        Color(0xFFEEF1F6),
        Color(0xFF6E7585),
      ],
    ),
    panel: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF161A22), Color(0xFF0B0D12)],
    ),
    cell: Color(0xFF0F1118),
    cellEmptyBorder: Color(0xFF2A2F3A),
    ink: Color(0xFFE7EBF2),
    muted: Color(0xFF7E8696),
    accent: Color(0xFFEEF1F6),
    accentGlow: Color(0xFFAAB0BE),
    danger: Color(0xFFD9544D),
    discStops: [
      [Color(0xFFFFFFFF), Color(0xFFC8CDD8), Color(0xFF878D9C)], // owner 0 — silver (X)
      [Color(0xFFF3DD8C), Color(0xFFC79A3A), Color(0xFF7E611A)], // owner 1 — dark gold (O)
    ],
    discGlow: [Color(0xFFEEF1F6), Color(0xFFF3DD8C)],
  );

  // ---- inherited access ----
  static GameTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_GameThemeScope>();
    return scope?.theme ?? futuristic;
  }
}

/// Provides the active [GameTheme] to the subtree.
class GameThemeProvider extends StatelessWidget {
  final GameTheme theme;
  final Widget child;
  const GameThemeProvider({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) => _GameThemeScope(theme: theme, child: child);
}

class _GameThemeScope extends InheritedWidget {
  final GameTheme theme;
  const _GameThemeScope({required this.theme, required super.child});

  @override
  bool updateShouldNotify(_GameThemeScope old) => old.theme != theme;
}

/// Motion timings (spec §1). Centralized so all themed widgets share the same feel.
class Motion {
  Motion._();
  static const Duration reveal = Duration(milliseconds: 500);
  static const Duration pawnPop = Duration(milliseconds: 420);
  static const Duration markDraw = Duration(milliseconds: 450);
  static const Duration capture = Duration(milliseconds: 300);
  static const Duration ripple = Duration(milliseconds: 600);
  static const Duration shimmer = Duration(milliseconds: 6200);
  static const Duration railSlide = Duration(milliseconds: 280);
  static const Duration hover = Duration(milliseconds: 180);
}
