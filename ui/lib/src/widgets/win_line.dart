import 'package:flutter/material.dart';

/// Order the winning cells into a continuous path where each consecutive pair is adjacent, so the win
/// line draws as one unbroken stroke (spec §2).
///
/// Crucially, a shape's cells connect by exactly ONE kind of step: an **axis-frame** I/L/Z (and a
/// horizontal/vertical 3-in-a-row) is a polyomino connected by **orthogonal** steps only; a
/// **diagonal-frame** shape (and a diagonal 3-in-a-row) is a staircase connected by **diagonal** steps
/// only. Mixing the two would let the walk take a diagonal "shortcut" across an axis-aligned L
/// (e.g. drawing 10→13 instead of 10→14→13). So we try the strict orthogonal connectivity first, then
/// the strict diagonal one, and only then a permissive king-move fallback.
List<int> orderWinPath(List<int> cells, int cols) {
  if (cells.length <= 2) return List.of(cells);

  int dr(int a, int b) => (a ~/ cols - b ~/ cols).abs();
  int dc(int a, int b) => (a % cols - b % cols).abs();

  bool orthogonal(int a, int b) => a != b && dr(a, b) + dc(a, b) == 1;
  bool diagonal(int a, int b) => a != b && dr(a, b) == 1 && dc(a, b) == 1;
  bool king(int a, int b) => a != b && dr(a, b) <= 1 && dc(a, b) <= 1;

  return _walkPath(cells, orthogonal) ??
      _walkPath(cells, diagonal) ??
      _walkPath(cells, king) ??
      List.of(cells);
}

/// Walk the 4 (or 3) cells into a single simple path under [adjacent], or return null if they don't
/// form one (a node with >2 neighbours, or a dead end before all cells are covered) — so the caller
/// can fall back to a different connectivity.
List<int>? _walkPath(List<int> cells, bool Function(int, int) adjacent) {
  final neighbours = {
    for (final c in cells) c: cells.where((o) => adjacent(c, o)).toList(),
  };
  // A simple path has no node with more than two neighbours.
  if (neighbours.values.any((n) => n.length > 2)) return null;
  // Start at a degree-1 endpoint (a path has exactly two); else this connectivity doesn't fit.
  final start = cells.firstWhere((c) => neighbours[c]!.length == 1, orElse: () => -1);
  if (start == -1) return null;

  final path = <int>[start];
  final visited = {start};
  var current = start;
  while (path.length < cells.length) {
    final next = neighbours[current]!.firstWhere((n) => !visited.contains(n), orElse: () => -1);
    if (next == -1) return null; // dead end before covering all cells → not a single path here
    path.add(next);
    visited.add(next);
    current = next;
  }
  return path;
}

/// Draws the winning cells as a single continuous polyline through their centers, revealed
/// progressively (start→end) via [progress] (spec §4). Round caps/joins keep bends and zigzags smooth;
/// a blurred under-stroke adds a soft glow. Colour is side-based (silver Classic / gold Futuristic),
/// passed in by the caller. Coordinates are in the board's inner (padded) space.
class WinLinePainter extends CustomPainter {
  final List<int> path; // cells in path order
  final int cols;
  final double cellSize;
  final double gap;
  final double progress; // 0..1 reveal
  final Color color;
  final Color glow;

  WinLinePainter({
    required this.path,
    required this.cols,
    required this.cellSize,
    required this.gap,
    required this.progress,
    required this.color,
    required this.glow,
  });

  Offset _center(int index) {
    final r = index ~/ cols, c = index % cols;
    return Offset(c * (cellSize + gap) + cellSize / 2, r * (cellSize + gap) + cellSize / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2 || progress <= 0) return;

    final full = Path()..moveTo(_center(path.first).dx, _center(path.first).dy);
    for (var i = 1; i < path.length; i++) {
      final p = _center(path[i]);
      full.lineTo(p.dx, p.dy);
    }

    // Reveal only the leading fraction of the single stroke (PathMetric — like stroke-dashoffset).
    final metrics = full.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    final target = total * progress.clamp(0.0, 1.0);
    final revealed = Path();
    var acc = 0.0;
    for (final m in metrics) {
      if (acc >= target) break;
      final len = (target - acc).clamp(0.0, m.length);
      revealed.addPath(m.extractPath(0, len), Offset.zero);
      acc += m.length;
    }

    final width = (cellSize * 0.13).clamp(5.0, 12.0);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = glow.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawPath(revealed, glowPaint);

    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(revealed, mainPaint);
  }

  @override
  bool shouldRepaint(WinLinePainter old) =>
      old.progress != progress || old.path != path || old.color != color;
}
