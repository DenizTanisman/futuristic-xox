import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark (warm luxury) and Light (cream luxury) themes for the shell screens (Settings / About /
/// Issue / drawer). The entry screen and the in-game mode themes paint their own palettes and do not
/// read these (spec §2). Tokens come from the app-shell demo.
class AppThemes {
  AppThemes._();

  // Dark
  static const _dPanel = Color(0xFF120C08);
  static const _dCard = Color(0xFF1C150D);
  static const _dInk = Color(0xFFF4ECD8);
  static const _dMuted = Color(0xFF9A8A6A);
  static const _dAccent = Color(0xFFD4AF37);
  static const _dLine = Color(0x29D4AF37); // rgba(212,175,55,.16)

  // Light
  static const _lCard = Color(0xFFFFFFFF);
  static const _lInk = Color(0xFF33280F);
  static const _lMuted = Color(0xFF937F4F);
  static const _lAccent = Color(0xFFB8902C);
  static const _lLine = Color(0x2E8C6E28); // rgba(140,110,40,.18)

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scaffold: _dPanel,
        card: _dCard,
        ink: _dInk,
        muted: _dMuted,
        accent: _dAccent,
        line: _dLine,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scaffold: const Color(0xFFF1E8D2),
        card: _lCard,
        ink: _lInk,
        muted: _lMuted,
        accent: _lAccent,
        line: _lLine,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color card,
    required Color ink,
    required Color muted,
    required Color accent,
    required Color line,
  }) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      cardColor: card,
      dividerColor: line,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ).copyWith(
        primary: accent,
        surface: card,
        onSurface: ink,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      iconTheme: IconThemeData(color: muted),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink),
      ),
      listTileTheme: ListTileThemeData(iconColor: muted, textColor: ink),
      dividerTheme: DividerThemeData(color: line, space: 1),
      extensions: [LuxTokens(ink: ink, muted: muted, accent: accent, card: card, line: line)],
    );
  }
}

/// Extra luxury tokens (accent, muted, etc.) reachable via `Theme.of(context).extension<LuxTokens>()`.
class LuxTokens extends ThemeExtension<LuxTokens> {
  final Color ink;
  final Color muted;
  final Color accent;
  final Color card;
  final Color line;
  const LuxTokens({
    required this.ink,
    required this.muted,
    required this.accent,
    required this.card,
    required this.line,
  });

  static LuxTokens of(BuildContext context) =>
      Theme.of(context).extension<LuxTokens>() ??
      const LuxTokens(
        ink: Color(0xFFF4ECD8),
        muted: Color(0xFF9A8A6A),
        accent: Color(0xFFD4AF37),
        card: Color(0xFF1C150D),
        line: Color(0x29D4AF37),
      );

  @override
  LuxTokens copyWith({Color? ink, Color? muted, Color? accent, Color? card, Color? line}) =>
      LuxTokens(
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        accent: accent ?? this.accent,
        card: card ?? this.card,
        line: line ?? this.line,
      );

  @override
  LuxTokens lerp(LuxTokens? other, double t) {
    if (other == null) return this;
    return LuxTokens(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}
