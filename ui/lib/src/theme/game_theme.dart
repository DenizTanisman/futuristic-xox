import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Per-owner pawn palette for the metallic medallion (spec: medallion §1):
/// [ring] = same-hue metallic sweep (7 stops), [disc] = inner radial (3 stops),
/// [number] = metallic number fill (4 stops), [glow] = soft outer glow.
class PawnPalette {
  final List<Color> ring;
  final List<Color> disc;

  /// Number fill gradient — always the OPPOSITE brightness of [disc] so the value reads (bright on a
  /// dark disc, dark on a light disc). Never reuses the disc hue.
  final List<Color> number;

  /// Outline drawn under the number for crispness (dark under a bright number, light under a dark one).
  final Color numberStroke;
  final Color glow;
  const PawnPalette({
    required this.ring,
    required this.disc,
    required this.number,
    required this.numberStroke,
    required this.glow,
  });
}

/// All visual tokens for one identity (colours, gradients, fonts). Two instances —
/// [GameTheme.futuristic] (warm luxury) and [GameTheme.classic] (cold metallic). Widgets read from
/// the active theme via [GameTheme.of] and never hardcode colours.
class GameTheme {
  // Surfaces
  final Gradient background;
  final Gradient frameRim;
  final Gradient panel;
  final Color cell;
  final Color cellEmptyBorder;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentGlow;
  final Color danger;

  /// Per-owner medallion palette `[owner0, owner1]`.
  final List<PawnPalette> _pawns;

  /// Per-owner 3-tone gradient `[hi, mid, lo]` for the Classic X/O metallic stroke.
  final List<List<Color>> _markStops;

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
    required List<PawnPalette> pawns,
    required List<List<Color>> markStops,
  })  : _pawns = pawns,
        _markStops = markStops;

  PawnPalette pawn(int owner) => _pawns[owner & 1];
  Color discGlow(int owner) => _pawns[owner & 1].glow;
  Color ownerColor(int owner) => _pawns[owner & 1].disc[1];

  /// Classic stroke gradient `[hi, mid, lo]` for the X/O mark.
  List<Color> markStops(int owner) => _markStops[owner & 1];

  // Fixed gradient stop positions (spec §1).
  static const List<double> ringStops = [0.0, 0.12, 0.28, 0.42, 0.60, 0.78, 1.0];
  static const List<double> discStops = [0.0, 0.46, 1.0];
  static const List<double> numberStops = [0.0, 0.38, 0.64, 1.0];

  // ---- typography ----
  TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.cinzel(fontSize: size, fontWeight: weight, color: color ?? ink, letterSpacing: 1.5);

  TextStyle label(double size, {Color? color, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: weight, color: color ?? ink, letterSpacing: 0.5);

  // ---- instances ----

  /// Futuristic: seat 0 (bottom / player) = GOLD, seat 1 (top / opponent) = BORDEAUX (spec §2).
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
    pawns: [
      // owner 0 — GOLD (light disc → DARK bronze number)
      PawnPalette(
        ring: [
          Color(0xFF6B4F12),
          Color(0xFFF6E6A8),
          Color(0xFFC79A3A),
          Color(0xFFFFF3C8),
          Color(0xFF8A6A1D),
          Color(0xFFF6E6A8),
          Color(0xFF6B4F12),
        ],
        disc: [Color(0xFFE9C659), Color(0xFFD4AF37), Color(0xFF7A5D16)],
        number: [Color(0xFF5A4410), Color(0xFF3A2A08), Color(0xFF2E2106), Color(0xFF241A05)],
        numberStroke: Color(0x59FFF0C8), // light rim, rgba(255,240,200,.35)
        glow: Color(0xFFF6E6A8),
      ),
      // owner 1 — BORDEAUX (dark disc → BRIGHT number)
      PawnPalette(
        ring: [
          Color(0xFF3C0C14),
          Color(0xFFE87A8E),
          Color(0xFF9B2335),
          Color(0xFFFFC0CB),
          Color(0xFF5E121D),
          Color(0xFFE87A8E),
          Color(0xFF3C0C14),
        ],
        disc: [Color(0xFFB83247), Color(0xFF9B2335), Color(0xFF4A0E17)],
        number: [Color(0xFFFFF0F3), Color(0xFFFFC2CD), Color(0xFFF57E92), Color(0xFFD8556B)],
        numberStroke: Color(0x9E120703), // dark, rgba(18,7,3,.62)
        glow: Color(0xFFE87A8E),
      ),
    ],
    markStops: [
      [Color(0xFFD8556B), Color(0xFF9B2335), Color(0xFF5E121D)],
      [Color(0xFFF6E6A8), Color(0xFFC79A3A), Color(0xFF8A6A1D)],
    ],
  );

  /// Classic: owner 0 = silver (X), owner 1 = dark gold (O).
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
    pawns: [
      PawnPalette(
        ring: [
          Color(0xFF3A3F4B),
          Color(0xFFFFFFFF),
          Color(0xFFAAB0BE),
          Color(0xFFFFFFFF),
          Color(0xFF6E7585),
          Color(0xFFEEF1F6),
          Color(0xFF3A3F4B),
        ],
        disc: [Color(0xFFFFFFFF), Color(0xFFC8CDD8), Color(0xFF878D9C)],
        number: [Color(0xFF2A2F3A), Color(0xFF1E222B), Color(0xFF14171E), Color(0xFF0C0E13)],
        numberStroke: Color(0x59FFFFFF),
        glow: Color(0xFFEEF1F6),
      ),
      PawnPalette(
        ring: [
          Color(0xFF7E611A),
          Color(0xFFF3DD8C),
          Color(0xFFC79A3A),
          Color(0xFFF3DD8C),
          Color(0xFF7E611A),
          Color(0xFFF3DD8C),
          Color(0xFF7E611A),
        ],
        disc: [Color(0xFFF3DD8C), Color(0xFFC79A3A), Color(0xFF7E611A)],
        number: [Color(0xFF4A3610), Color(0xFF3A2A08), Color(0xFF2E2106), Color(0xFF241A05)],
        numberStroke: Color(0x59FFF0C8),
        glow: Color(0xFFF3DD8C),
      ),
    ],
    markStops: [
      [Color(0xFFFFFFFF), Color(0xFFC8CDD8), Color(0xFF878D9C)],
      [Color(0xFFF3DD8C), Color(0xFFC79A3A), Color(0xFF7E611A)],
    ],
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

/// Motion timings (spec §1).
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
