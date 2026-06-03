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
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
        if (aiThinking) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
        ],
      ],
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
