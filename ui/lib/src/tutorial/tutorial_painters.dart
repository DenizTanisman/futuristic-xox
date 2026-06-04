import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tutorial_step.dart';

// Classic mark identity — constant in both themes (spec §1).
const _silver = [Color(0xFFFFFFFF), Color(0xFFC8CDD8), Color(0xFF7D8392)];
const _gold = [Color(0xFFE8C87A), Color(0xFFC79A3A), Color(0xFF8A6A1D)];

/// An animated Classic mark (X or O) with a stroke-draw on mount (spec §1, §6).
class TutorialMark extends StatefulWidget {
  final Mark mark;
  final double size;
  final bool animate;
  const TutorialMark({super.key, required this.mark, required this.size, this.animate = true});

  @override
  State<TutorialMark> createState() => _TutorialMarkState();
}

class _TutorialMarkState extends State<TutorialMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
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
    // Subtle pop with the stroke-draw.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final scale = 0.85 + 0.15 * Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0));
          return Transform.scale(
            scale: scale,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: MarkPainter(mark: widget.mark, progress: _c.value),
            ),
          );
        },
      ),
    );
  }
}

/// Draws an X (two sequential silver strokes) or an O (dark-gold arc), revealed by [progress] 0→1.
class MarkPainter extends CustomPainter {
  final Mark mark;
  final double progress;
  MarkPainter({required this.mark, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Offset.zero & size;
    final stroke = size.width * 0.13;
    final colors = mark == Mark.x ? _silver : _gold;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    final pad = stroke * 0.7;
    if (mark == Mark.x) {
      // Second stroke starts after the first (~at half progress).
      final aS = Offset(pad, pad), aE = Offset(size.width - pad, size.height - pad);
      final bS = Offset(size.width - pad, pad), bE = Offset(pad, size.height - pad);
      final t1 = (progress / 0.5).clamp(0.0, 1.0);
      canvas.drawLine(aS, Offset.lerp(aS, aE, t1)!, paint);
      final t2 = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      if (t2 > 0) canvas.drawLine(bS, Offset.lerp(bS, bE, t2)!, paint);
    } else {
      final r = size.width / 2 - pad;
      final arcRect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
      canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(MarkPainter old) => old.progress != progress || old.mark != mark;
}

/// An animated bright-silver win line drawn across cells (spec §1, §6).
class TutorialWinLine extends StatefulWidget {
  /// Centres of the cells the line passes through (board-space, same size as the painter area).
  final Offset start;
  final Offset end;

  /// Line colour: silver for Classic, gold for Futuristic.
  final Color color;
  const TutorialWinLine({
    super.key,
    required this.start,
    required this.end,
    this.color = const Color(0xFFFFFFFF),
  });

  @override
  State<TutorialWinLine> createState() => _TutorialWinLineState();
}

class _TutorialWinLineState extends State<TutorialWinLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _WinLinePainter(start: widget.start, end: widget.end, progress: _c.value, color: widget.color),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _WinLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  final Color color;
  _WinLinePainter({required this.start, required this.end, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final tip = Offset.lerp(start, end, Curves.easeOut.transform(progress))!;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawLine(start, tip, glow);
    canvas.drawLine(start, tip, line);
  }

  @override
  bool shouldRepaint(_WinLinePainter old) => old.progress != progress || old.color != color;
}
