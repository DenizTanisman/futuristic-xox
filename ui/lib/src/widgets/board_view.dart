import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../theme/game_theme.dart';
import 'classic_mark.dart';
import 'pawn_widget.dart';
import 'win_line.dart';

/// The themed game board: a beveled metallic frame with a slowly sweeping rim shimmer, cells that
/// scale in with a staggered reveal, and per-cell hover/press glow. Colours come from the active
/// [GameTheme]; cell content is a futuristic disc or a stroke-drawn classic mark (spec §3.1–§3.3).
class BoardView extends StatefulWidget {
  final Snapshot snapshot;
  final bool showValues;
  final bool classic;
  final List<int> highlightedCells;
  final int? lastMoveCell;
  final bool lastWasCapture;
  final void Function(int cell) onTap;
  final bool interactive;

  const BoardView({
    super.key,
    required this.snapshot,
    required this.showValues,
    required this.classic,
    required this.highlightedCells,
    required this.lastMoveCell,
    this.lastWasCapture = false,
    required this.onTap,
    required this.interactive,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _reveal;

  /// Progressive reveal of the win line (spec §4) — starts when a win first appears.
  late final AnimationController _winLine;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: Motion.shimmer)..repeat();
    _reveal = AnimationController(vsync: this, duration: Motion.reveal)..forward();
    _winLine = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.snapshot.winningCells.isNotEmpty) _winLine.value = 1; // already-won (e.g. rebuild)
  }

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);
    // Draw the line the moment a win appears (player or AI), once.
    if (old.snapshot.winningCells.isEmpty && widget.snapshot.winningCells.isNotEmpty) {
      _winLine.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _reveal.dispose();
    _winLine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    final s = widget.snapshot;
    final highlight = widget.highlightedCells.toSet();
    const radius = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        const gap = 8.0;
        const pad = 12.0;
        final cellSize = (side - pad * 2 - gap * (s.cols - 1)) / s.cols;

        return SizedBox(
          width: side,
          height: side,
          child: Stack(
            children: [
              // Frame panel + drop shadow.
              Container(
                decoration: BoxDecoration(
                  gradient: theme.panel,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
              ),
              // Top bevel highlight (Flutter has no inset shadow — fake the bevel).
              Positioned(
                left: radius,
                right: radius,
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
              // Sweeping metallic rim.
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _shimmer,
                  builder: (context, _) => CustomPaint(
                    size: Size(side, side),
                    painter: _RimPainter(
                      t: _shimmer.value,
                      colors: (theme.frameRim as LinearGradient).colors,
                      radius: radius,
                      stroke: 2.4,
                    ),
                  ),
                ),
              ),
              // Cells.
              Padding(
                padding: const EdgeInsets.all(pad),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: s.cellCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: s.cols,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                  ),
                  itemBuilder: (context, i) {
                    final start = (i * 0.4 / s.cellCount).clamp(0.0, 0.6);
                    final anim = CurvedAnimation(
                      parent: _reveal,
                      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutBack),
                    );
                    return RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: anim,
                        builder: (context, child) => Transform.scale(
                          scale: anim.value.clamp(0.0, 1.0),
                          child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
                        ),
                        child: _Cell(
                          theme: theme,
                          cell: s.board[i],
                          size: cellSize,
                          classic: widget.classic,
                          showValue: widget.showValues,
                          highlighted: highlight.contains(i),
                          isLast: widget.lastMoveCell == i,
                          captured: widget.lastMoveCell == i && widget.lastWasCapture,
                          onTap: widget.interactive ? () => widget.onTap(i) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Win-line overlay: one continuous polyline over the winning cells (spec §0–§5). Shares
              // the cells' padded coordinate space; non-interactive.
              if (s.winningCells.isNotEmpty)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(pad),
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _winLine,
                          builder: (context, _) => CustomPaint(
                            size: Size(side - pad * 2, side - pad * 2),
                            painter: WinLinePainter(
                              path: orderWinPath(s.winningCells, s.cols),
                              cols: s.cols,
                              cellSize: cellSize,
                              gap: gap,
                              progress: _winLine.value,
                              color: theme.accent, // silver (Classic) / gold (Futuristic)
                              glow: theme.accentGlow,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One board cell: themed surface with hover/press lift + glow, holding a disc or X/O mark.
class _Cell extends StatefulWidget {
  final GameTheme theme;
  final CellView cell;
  final double size;
  final bool classic;
  final bool showValue;
  final bool highlighted;
  final bool isLast;
  final bool captured;
  final VoidCallback? onTap;

  const _Cell({
    required this.theme,
    required this.cell,
    required this.size,
    required this.classic,
    required this.showValue,
    required this.highlighted,
    required this.isLast,
    required this.captured,
    required this.onTap,
  });

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _active = false;

  void _set(bool v) {
    if (widget.onTap != null && _active != v) setState(() => _active = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final lift = _active ? -2.0 : 0.0;
    final glow = widget.highlighted || _active;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _set(true),
      onExit: (_) => _set(false),
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Motion.hover,
          transform: Matrix4.translationValues(0, lift, 0),
          decoration: BoxDecoration(
            color: theme.cell,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isLast
                  ? theme.accent
                  : glow
                      ? theme.accent.withValues(alpha: 0.7)
                      : theme.cellEmptyBorder,
              width: widget.isLast ? 2.4 : (glow ? 2 : 1),
            ),
            boxShadow: glow
                ? [BoxShadow(color: theme.accent.withValues(alpha: 0.25), blurRadius: 12)]
                : null,
          ),
          alignment: Alignment.center,
          child: _content(theme),
        ),
      ),
    );
  }

  Widget? _content(GameTheme theme) {
    final cell = widget.cell;
    if (cell.empty) return null;
    if (widget.classic) {
      return Padding(
        padding: EdgeInsets.all(widget.size * 0.16),
        child: ClassicMark(owner: cell.owner, size: widget.size * 0.68),
      );
    }
    return Padding(
      padding: EdgeInsets.all(widget.size * 0.1),
      child: PawnWidget(
        owner: cell.owner,
        value: cell.value,
        showValue: widget.showValue,
        size: widget.size * 0.8,
        captured: widget.captured,
      ),
    );
  }
}

/// Strokes the metallic frame rim with a sweep-gradient highlight that rotates with [t].
class _RimPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final double radius;
  final double stroke;

  _RimPainter({required this.t, required this.colors, required this.radius, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(stroke / 2),
      Radius.circular(radius),
    );
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
  bool shouldRepaint(_RimPainter old) => old.t != t || old.colors != colors;
}
