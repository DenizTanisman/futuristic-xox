import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// A beveled metallic panel with a slowly sweeping rim shimmer (the §3.1 frame, reused by the board
/// and the menu/setup shells). Colours come from the active [GameTheme].
class MetallicPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const MetallicPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
  });

  @override
  State<MetallicPanel> createState() => _MetallicPanelState();
}

class _MetallicPanelState extends State<MetallicPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: Motion.shimmer)..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    return RepaintBoundary(
      child: Stack(
        children: [
          // Panel fill + drop shadow.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: theme.panel,
                borderRadius: BorderRadius.circular(widget.radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
          // Top bevel highlight (no inset shadow in Flutter).
          Positioned(
            left: widget.radius,
            right: widget.radius,
            top: 1.5,
            child: Container(
              height: 1.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.accentGlow.withValues(alpha: 0.0),
                    theme.accentGlow.withValues(alpha: 0.5),
                    theme.accentGlow.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Sweeping rim.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (context, _) => CustomPaint(
                painter: _PanelRimPainter(
                  t: _shimmer.value,
                  colors: (theme.frameRim as LinearGradient).colors,
                  radius: widget.radius,
                ),
              ),
            ),
          ),
          Padding(padding: widget.padding, child: widget.child),
        ],
      ),
    );
  }
}

class _PanelRimPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final double radius;
  _PanelRimPainter({required this.t, required this.colors, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.2;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(stroke / 2), Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        colors: [...colors, colors.first],
        transform: GradientRotation(2 * math.pi * t),
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_PanelRimPainter old) => old.t != t;
}
