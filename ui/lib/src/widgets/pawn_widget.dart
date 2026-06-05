import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/game_theme.dart';

/// A metallic **medallion** pawn (spec: medallion §1): a thin same-hue metallic ring (sweep gradient)
/// around a colored inner disc (radial gradient) inset by ~7% of the diameter, with a metallic number
/// drawn as a dark-stroke pass + gradient-fill pass for crisp legibility at any size. On placement it
/// pops in with an elastic overshoot and emits a one-shot ripple (red on capture).
class PawnWidget extends StatelessWidget {
  final int owner;
  final int value;
  final bool showValue;
  final double size;
  final bool selected;

  /// Optional glyph instead of the value (e.g. legacy X/O); usually null for valued discs.
  final String? glyph;

  /// Whether to play the pop-in + ripple (off for static rail chips).
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
    final p = theme.pawn(owner);
    final label = glyph ?? (showValue ? '$value' : null);
    final inset = size * 0.07; // ring thickness ≈ 7% of the diameter

    final medallion = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: 220 * math.pi / 180,
          endAngle: 220 * math.pi / 180 + 2 * math.pi,
          colors: p.ring,
          stops: GameTheme.ringStops,
        ),
        border: selected ? Border.all(color: theme.accentGlow, width: 2.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.06),
          ),
          BoxShadow(
            color: p.glow.withValues(alpha: selected ? 0.6 : 0.32),
            blurRadius: selected ? 18 : 9,
            spreadRadius: selected ? 3 : 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: p.disc,
              stops: GameTheme.discStops,
              center: const Alignment(-0.3, -0.45),
              radius: 0.95,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Bevel: no inset shadow in Flutter, so fake it with a top-light/bottom-dark overlay.
              const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF), Color(0x2A000000)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              if (label != null)
                _MetalNumber(label: label, size: size, colors: p.number, strokeColor: p.numberStroke),
            ],
          ),
        ),
      ),
    );

    if (!animateIn) return medallion;

    final popIn = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Motion.pawnPop,
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: (0.4 + 0.6 * t).clamp(0.0, 1.18), child: child),
      child: medallion,
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _Ripple(size: size, color: captured ? theme.danger : p.glow),
        popIn,
      ],
    );
  }
}

/// A metallic number: a dark stroke pass under a gradient-fill pass (crisp at small sizes, spec §1).
class _MetalNumber extends StatelessWidget {
  final String label;
  final double size;
  final List<Color> colors;
  final Color strokeColor;
  const _MetalNumber({
    required this.label,
    required this.size,
    required this.colors,
    required this.strokeColor,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.54;
    final strokeWidth = (fontSize * 0.06).clamp(0.9, 3.2);
    final base = GoogleFonts.rajdhani(fontSize: fontSize, fontWeight: FontWeight.w700, height: 1.0);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = strokeColor;

    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: GameTheme.numberStops,
    ).createShader(Rect.fromLTWH(0, 0, fontSize, fontSize * 1.2));

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(label, style: base.copyWith(foreground: strokePaint)),
          Text(
            label,
            style: base.copyWith(
              foreground: Paint()..shader = fillShader,
              shadows: const [Shadow(color: Color(0x99000000), blurRadius: 2, offset: Offset(0, 1))],
            ),
          ),
        ],
      ),
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
