import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// A Classic X or O drawn with an animated metallic stroke (spec §3.5):
/// X = two silver diagonals drawn in sequence; O = a dark-gold ring drawn around. The stroke uses a
/// metallic gradient from the active [GameTheme]'s owner palette.
class ClassicMark extends StatefulWidget {
  final int owner; // 0 = X (silver), 1 = O (dark gold)
  final double size;
  final bool animate;

  const ClassicMark({super.key, required this.owner, required this.size, this.animate = true});

  @override
  State<ClassicMark> createState() => _ClassicMarkState();
}

class _ClassicMarkState extends State<ClassicMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Motion.markDraw);
    if (widget.animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    final stops = theme.markStops(widget.owner); // [hi, mid, lo]
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _MarkPainter(
            isX: widget.owner == 0,
            progress: Curves.easeInOut.transform(_c.value),
            stops: stops,
            glow: theme.discGlow(widget.owner),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final bool isX;
  final double progress;
  final List<Color> stops;
  final Color glow;

  _MarkPainter({required this.isX, required this.progress, required this.stops, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Offset.zero & size;
    final stroke = size.width * 0.13;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [stops[0], stops[1], stops[2]],
      ).createShader(rect);
    // Soft metallic glow underlay.
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = glow.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final pad = stroke * 0.6;
    if (isX) {
      // Two diagonals: line 1 over 0..0.5, line 2 over 0.5..1.
      final aStart = Offset(pad, pad);
      final aEnd = Offset(size.width - pad, size.height - pad);
      final bStart = Offset(size.width - pad, pad);
      final bEnd = Offset(pad, size.height - pad);
      final t1 = (progress / 0.5).clamp(0.0, 1.0);
      final t2 = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final l1 = Offset.lerp(aStart, aEnd, t1)!;
      canvas.drawLine(aStart, l1, glowPaint);
      canvas.drawLine(aStart, l1, paint);
      if (t2 > 0) {
        final l2 = Offset.lerp(bStart, bEnd, t2)!;
        canvas.drawLine(bStart, l2, glowPaint);
        canvas.drawLine(bStart, l2, paint);
      }
    } else {
      // Ring drawn as an arc sweeping from -90°.
      final r = (size.width / 2) - pad;
      final center = size.center(Offset.zero);
      final arcRect = Rect.fromCircle(center: center, radius: r);
      final sweep = 2 * math.pi * progress;
      canvas.drawArc(arcRect, -math.pi / 2, sweep, false, glowPaint);
      canvas.drawArc(arcRect, -math.pi / 2, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.progress != progress || old.isX != isX;
}
