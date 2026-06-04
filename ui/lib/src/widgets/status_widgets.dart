import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../theme/game_theme.dart';

/// Turn indicator: a pulsing glow dot in the active seat's colour + the seat label (Cinzel) and a
/// sublabel (Morph "move N of 2"). Shows a spinner while a non-human seat thinks (spec §3.7).
class TurnIndicator extends StatefulWidget {
  final int turn;
  final String label;
  final bool twoMovesPerTurn;
  final int movesLeftInTurn;
  final bool aiThinking;
  final bool isOver;

  const TurnIndicator({
    super.key,
    required this.turn,
    required this.label,
    required this.twoMovesPerTurn,
    required this.movesLeftInTurn,
    required this.aiThinking,
    required this.isOver,
  });

  @override
  State<TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<TurnIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOver) return const SizedBox(height: 30);
    final theme = GameTheme.of(context);
    final color = theme.ownerColor(widget.turn);
    final glow = theme.discGlow(widget.turn);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: glow, blurRadius: 6 + 8 * t, spreadRadius: t)],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Text(widget.label, style: theme.display(16, color: theme.ink)),
        if (widget.twoMovesPerTurn) ...[
          const SizedBox(width: 10),
          Text('move ${3 - widget.movesLeftInTurn} of 2', style: theme.label(13, color: theme.muted)),
        ],
        if (widget.aiThinking) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: theme.accent),
          ),
        ],
      ],
    );
  }
}

/// Persistent Morph target badge: the chosen shape rendered as a compact mini-grid of cells (not a
/// letter), kept vertical so it stays narrow (spec: medallion §3). Filled cells glow gold; empty
/// cells are faint. Rotation-agnostic, with an "any rotation" sublabel.
class MorphShapeBadge extends StatelessWidget {
  final MorphShape shape;
  const MorphShapeBadge({super.key, required this.shape});

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    var cells = shape.previewCells;
    var maxR = cells.map((c) => c[0]).reduce((a, b) => a > b ? a : b);
    var maxC = cells.map((c) => c[1]).reduce((a, b) => a > b ? a : b);
    // Keep it vertical (taller than wide) so the badge never eats horizontal space.
    if (maxC > maxR) {
      cells = cells.map((c) => [c[1], c[0]]).toList();
      final t = maxR;
      maxR = maxC;
      maxC = t;
    }
    final filled = cells.map((c) => c[0] * (maxC + 1) + c[1]).toSet();
    const unit = 12.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: theme.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TARGET', style: theme.label(11, color: theme.muted)),
              Text('any rotation', style: theme.label(9, color: theme.muted)),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r <= maxR; r++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var c = 0; c <= maxC; c++)
                      _miniCell(theme, filled.contains(r * (maxC + 1) + c), unit),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniCell(GameTheme theme, bool on, double unit) {
    return Container(
      width: unit,
      height: unit,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: on
            ? RadialGradient(colors: [theme.accentGlow, theme.accent], center: const Alignment(-0.3, -0.4))
            : null,
        color: on ? null : theme.muted.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(3),
        boxShadow: on ? [BoxShadow(color: theme.accent.withValues(alpha: 0.5), blurRadius: 5)] : null,
      ),
    );
  }
}

/// A brief centered intro overlay (Bonanza's own-colour count at game start, spec §4.3).
class IntroOverlay extends StatelessWidget {
  final String title;
  final Widget child;
  const IntroOverlay({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
          decoration: BoxDecoration(
            gradient: theme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.accent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.label(14, color: theme.muted)),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline transient message: red for illegal moves, accent for capture/info (spec §3.3, §8).
class InlineMessage extends StatelessWidget {
  final String? message;
  final bool isError;
  const InlineMessage({super.key, required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: message == null
          ? const SizedBox(height: 24)
          : Container(
              key: ValueKey(message),
              height: 24,
              alignment: Alignment.center,
              child: Text(
                message!,
                style: theme.label(15, color: isError ? theme.danger : theme.accent, weight: FontWeight.w700),
              ),
            ),
    );
  }
}

/// Win/lose/draw banner overlay with play-again / menu actions (spec §8).
class ResultBanner extends StatelessWidget {
  final Outcome outcome;
  final String title;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const ResultBanner({
    super.key,
    required this.outcome,
    required this.title,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    final color = switch (outcome) {
      Outcome.win0 => theme.discGlow(0),
      Outcome.win1 => theme.discGlow(1),
      _ => theme.ink,
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            gradient: theme.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 24)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.display(26, color: color)),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(onPressed: onMenu, child: Text('Menu', style: theme.label(15))),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: onPlayAgain, child: Text('Play again', style: theme.label(15, color: Colors.black))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
