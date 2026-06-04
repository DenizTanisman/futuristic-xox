import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'pawn_widget.dart';

/// The game board: a square grid of cells. Highlights legal target cells for the selected pawn,
/// marks the most recent move, and reports taps (spec §8).
class BoardView extends StatelessWidget {
  final Snapshot snapshot;
  final bool showValues;

  /// Classic renders X / O glyphs instead of values (spec §4.1).
  final bool classic;
  final List<int> highlightedCells;

  /// Morph hint: cells that would complete the target shape this move.
  final List<int> winningCells;
  final int? lastMoveCell;
  final void Function(int cell) onTap;
  final bool interactive;

  const BoardView({
    super.key,
    required this.snapshot,
    required this.showValues,
    required this.classic,
    required this.highlightedCells,
    this.winningCells = const [],
    required this.lastMoveCell,
    required this.onTap,
    required this.interactive,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = highlightedCells.toSet();
    final winning = winningCells.toSet();
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        const gap = 8.0;
        final cellSize = (side - gap * (snapshot.cols + 1)) / snapshot.cols;
        return Container(
          width: side,
          height: side,
          padding: const EdgeInsets.all(gap),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gridLine, width: 1.5),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.cellCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: snapshot.cols,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
            ),
            itemBuilder: (context, i) => _Cell(
              cell: snapshot.board[i],
              size: cellSize,
              showValue: showValues,
              classic: classic,
              highlighted: highlight.contains(i),
              winning: winning.contains(i),
              isLast: lastMoveCell == i,
              onTap: interactive ? () => onTap(i) : null,
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final CellView cell;
  final double size;
  final bool showValue;
  final bool classic;
  final bool highlighted;
  final bool winning;
  final bool isLast;
  final VoidCallback? onTap;

  const _Cell({
    required this.cell,
    required this.size,
    required this.showValue,
    required this.classic,
    required this.highlighted,
    required this.winning,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.place,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: winning
                ? AppColors.hint
                : isLast
                    ? AppColors.accent
                    : highlighted
                        ? AppColors.accent.withValues(alpha: 0.6)
                        : AppColors.gridLine,
            width: winning ? 2.5 : (isLast ? 2.5 : (highlighted ? 2 : 1)),
          ),
          boxShadow: winning
              ? [BoxShadow(color: AppColors.hint.withValues(alpha: 0.45), blurRadius: 12)]
              : highlighted
                  ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 10)]
                  : null,
        ),
        alignment: Alignment.center,
        child: cell.empty
            ? (winning
                ? Icon(Icons.star_rounded, color: AppColors.hint, size: size * 0.45)
                : highlighted
                    ? Icon(Icons.add, color: AppColors.accent.withValues(alpha: 0.7), size: size * 0.35)
                    : null)
            : Padding(
                padding: EdgeInsets.all(size * 0.1),
                child: PawnWidget(
                  owner: cell.owner,
                  value: cell.value,
                  showValue: showValue,
                  size: size * 0.8,
                  glyph: classic ? (cell.owner == 0 ? 'X' : 'O') : null,
                ),
              ),
      ),
    );
  }
}
