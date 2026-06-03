import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../theme/app_theme.dart';

/// Turn indicator + Morph "move 1 of 2 / 2 of 2" + an AI-thinking hint (spec §8).
class TurnIndicator extends StatelessWidget {
  final int turn;
  final bool twoMovesPerTurn;
  final int movesLeftInTurn;
  final bool aiThinking;
  final bool isOver;

  const TurnIndicator({
    super.key,
    required this.turn,
    required this.twoMovesPerTurn,
    required this.movesLeftInTurn,
    required this.aiThinking,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    if (isOver) return const SizedBox.shrink();
    final isHuman = turn == 0;
    final who = isHuman ? 'Your turn' : 'Computer';
    final color = AppColors.owner(turn);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: AppColors.ownerGlow(turn), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 8),
        Text(who, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        if (twoMovesPerTurn) ...[
          const SizedBox(width: 10),
          Text(
            'move ${3 - movesLeftInTurn} of 2',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
        if (aiThinking) ...[
          const SizedBox(width: 10),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
        ],
      ],
    );
  }
}

/// Persistent Morph target badge: the chosen shape as a letter + a small 4-cell picture, so players
/// know what to build (spec §4.4, §5).
class MorphShapeBadge extends StatelessWidget {
  final MorphShape shape;
  const MorphShapeBadge({super.key, required this.shape});

  @override
  Widget build(BuildContext context) {
    final cells = shape.previewCells;
    final maxR = cells.map((c) => c[0]).reduce((a, b) => a > b ? a : b);
    final maxC = cells.map((c) => c[1]).reduce((a, b) => a > b ? a : b);
    final filled = cells.map((c) => c[0] * (maxC + 1) + c[1]).toSet();
    const unit = 11.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Target', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(width: 8),
          Text(
            shape.letter,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r <= maxR; r++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var c = 0; c <= maxC; c++)
                      Container(
                        width: unit,
                        height: unit,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: filled.contains(r * (maxC + 1) + c)
                              ? AppColors.accent
                              : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A brief centered intro overlay (e.g. Bonanza's own-colour count at game start, spec §4.3).
class IntroOverlay extends StatelessWidget {
  final String title;
  final Widget child;
  const IntroOverlay({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, letterSpacing: 1.5)),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline transient message: red for illegal moves, gold for capture/info (spec §3.3, §8).
class InlineMessage extends StatelessWidget {
  final String? message;
  final bool isError;
  const InlineMessage({super.key, required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(
                  color: isError ? AppColors.danger : AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

/// Win/lose/draw banner overlay with a play-again / menu action (spec §8).
class ResultBanner extends StatelessWidget {
  final Outcome outcome;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const ResultBanner({
    super.key,
    required this.outcome,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final (title, color) = switch (outcome) {
      Outcome.win0 => ('You win!', AppColors.playerAGlow),
      Outcome.win1 => ('Computer wins', AppColors.playerBGlow),
      Outcome.draw => ('Draw', AppColors.textPrimary),
      Outcome.inProgress => ('', AppColors.textPrimary),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppTheme.screen,
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 24)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(onPressed: onMenu, child: const Text('Menu')),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: onPlayAgain, child: const Text('Play again')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
