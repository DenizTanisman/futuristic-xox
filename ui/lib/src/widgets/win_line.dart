import 'package:flutter/material.dart';

/// Order the winning cells into a continuous path where each consecutive pair is adjacent (a side or
/// diagonal neighbour), so the win line draws as one unbroken stroke (spec §2).
///
/// 3-in-a-row groups are already collinear; Morph's I/L/Z come from `morph_winner` as an unordered set.
/// Both are simple paths with exactly two degree-1 endpoints, so a short adjacency walk from an
/// endpoint orders them uniformly — straight (I), one bend (L), or zigzag (Z), axis or diagonal frame.
List<int> orderWinPath(List<int> cells, int cols) {
  if (cells.length <= 2) return List.of(cells);

  bool adjacent(int a, int b) {
    if (a == b) return false;
    final dr = (a ~/ cols - b ~/ cols).abs();
    final dc = (a % cols - b % cols).abs();
    return dr <= 1 && dc <= 1;
  }

  final neighbours = {
    for (final c in cells) c: cells.where((o) => adjacent(c, o)).toList(),
  };
  // Start at a degree-1 endpoint (a true path has exactly two); fall back to the first cell.
  final start = cells.firstWhere((c) => neighbours[c]!.length == 1, orElse: () => cells.first);

  final path = <int>[start];
  final visited = {start};
  var current = start;
  while (path.length < cells.length) {
    final next = neighbours[current]!.firstWhere((n) => !visited.contains(n), orElse: () => -1);
    if (next == -1) break;
    path.add(next);
    visited.add(next);
    current = next;
  }
  // Defensive: if the walk didn't cover everything (not expected for I/L/Z), append the rest.
  for (final c in cells) {
    if (!visited.contains(c)) path.add(c);
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
