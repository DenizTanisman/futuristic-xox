import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// A glossy 3D-ish disc pawn coloured by the active [GameTheme]: bordeaux/gold (futuristic) or
/// silver/dark-gold (classic). Shows its value (futuristic) or a glyph (classic rail). On placement
/// it pops in with an elastic overshoot and emits a one-shot ring ripple (spec §3.4); a capture
/// tints the ripple in the danger colour (spec §3.6).
class PawnWidget extends StatelessWidget {
  final int owner;
  final int value;
  final bool showValue;
  final double size;
  final bool selected;

  /// Optional glyph instead of the value (Classic rail tokens: 'X' / 'O').
  final String? glyph;

  /// Whether to play the pop-in + ripple (off for static rail tokens).
  final bool animateIn;

  /// True if this placement captured an enemy pawn (ripple turns red).
  final bool captured;

  const PawnWidget({
    super.key,
    required this.owner,
    required this.value,
    required this.showValue,
    required this.size,
    this.selected = false,
    this.glyph,
    this.animateIn = true,
    this.captured = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    final stops = theme.discStops(owner);
    final glow = theme.discGlow(owner);
    final label = glyph ?? (showValue ? '$value' : null);

    final disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [stops[0], stops[1], stops[2]],
          stops: const [0.0, 0.55, 1.0],
          center: const Alignment(-0.32, -0.34),
          radius: 0.95,
        ),
        border: Border.all(
          color: selected ? theme.accent : glow.withValues(alpha: 0.5),
          width: selected ? 3 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.06),
          ),
          BoxShadow(
            color: glow.withValues(alpha: selected ? 0.6 : 0.35),
            blurRadius: selected ? 16 : 9,
            spreadRadius: selected ? 1 : 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: label == null
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(size * 0.18),
                child: Text(
                  label,
                  style: theme.label(size * 0.5, color: theme.ink, weight: FontWeight.w700),
                ),
              ),
            ),
    );

    if (!animateIn) return disc;

    final popIn = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Motion.pawnPop,
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: (0.4 + 0.6 * t).clamp(0.0, 1.18), child: child),
      child: disc,
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _Ripple(size: size, color: captured ? theme.danger : glow),
        popIn,
      ],
    );
  }
}

/// A single expanding-and-fading ring, played once on mount.
class _Ripple extends StatelessWidget {
  final double size;
  final Color color;
  const _Ripple({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Motion.ripple,
      curve: Curves.easeOut,
      builder: (context, t, _) {
        if (t >= 1.0) return const SizedBox.shrink();
        return CustomPaint(
          size: Size.square(size * 1.7),
          painter: _RipplePainter(t: t, color: color, base: size * 0.5),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double t;
  final Color color;
  final double base;
  _RipplePainter({required this.t, required this.color, required this.base});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = base + (size.width / 2 - base) * t;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (1 - t) + 0.5
      ..color = color.withValues(alpha: (1 - t) * 0.6);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}
