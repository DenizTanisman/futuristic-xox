import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../game/dart_game_api.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/pawn_rail.dart';
import '../widgets/status_widgets.dart';

/// The main game screen (spec §8.4): board, both pawn rails (human at the bottom), turn/Morph
/// indicators, inline messages, and the win/lose/draw banner.
class GameScreen extends StatefulWidget {
  final Mode4 mode;
  final int grid;
  final Difficulty difficulty;

  const GameScreen({
    super.key,
    required this.mode,
    required this.grid,
    required this.difficulty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController controller;
  bool _showIntro = false;
  Timer? _introTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    controller = GameController(
      api: DartGameApi(),
      mode: widget.mode,
      rows: widget.grid,
      cols: widget.grid,
      difficulty: widget.difficulty,
      seed: DateTime.now().millisecondsSinceEpoch & 0xFFFFFF,
    );
    // Bonanza shows its own-colour count briefly at the start (spec §4.3).
    _introTimer?.cancel();
    if (widget.mode == Mode4.bonanza && controller.snapshot.bonanzaOwnCount != null) {
      _showIntro = true;
      _introTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showIntro = false);
      });
    } else {
      _showIntro = false;
    }
  }

  void _playAgain() {
    setState(() {
      controller.dispose();
      _start();
    });
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showValues = widget.mode.valued;
    final classic = widget.mode == Mode4.classic;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode.label} · ${widget.grid}×${widget.grid}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Restart', onPressed: _playAgain),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final s = controller.snapshot;
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      PawnRail(
                        owner: 1,
                        hand: s.hand1,
                        showValues: showValues,
                        classic: classic,
                        active: s.turn == 1 && !s.isOver,
                      ),
                      const SizedBox(height: 10),
                      TurnIndicator(
                        turn: s.turn,
                        twoMovesPerTurn: widget.mode.twoMovesPerTurn,
                        movesLeftInTurn: s.movesLeftInTurn,
                        aiThinking: controller.aiThinking,
                        isOver: s.isOver,
                      ),
                      if (s.morphShape != null) ...[
                        const SizedBox(height: 8),
                        Center(child: MorphShapeBadge(shape: s.morphShape!)),
                      ],
                      InlineMessage(message: controller.message, isError: controller.messageIsError),
                      Expanded(
                        child: Center(
                          child: BoardView(
                            snapshot: s,
                            showValues: showValues,
                            classic: classic,
                            highlightedCells: controller.highlightedCells,
                            winningCells: controller.completingCells,
                            lastMoveCell: controller.lastMoveCell,
                            interactive: controller.isHumanTurn && !controller.aiThinking,
                            onTap: controller.onCellTap,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PawnRail(
                        owner: 0,
                        hand: s.hand0,
                        showValues: showValues,
                        classic: classic,
                        active: controller.isHumanTurn,
                        selectedColor: controller.selectedColor,
                        selectedValue: controller.selectedValue,
                        onSelect: widget.mode.valued ? controller.selectPawn : null,
                      ),
                    ],
                  ),
                ),
                if (_showIntro && s.bonanzaOwnCount != null)
                  Positioned.fill(child: _bonanzaIntro(s.bonanzaOwnCount!, s.hand0.length)),
                if (s.isOver)
                  Positioned.fill(
                    child: ResultBanner(
                      outcome: s.outcome,
                      onPlayAgain: _playAgain,
                      onMenu: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bonanzaIntro(int ownCount, int total) {
    return IntroOverlay(
      title: 'YOUR HAND',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$ownCount',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 44,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'of your $total pawns are your own colour\n(${total - ownCount} are your opponent\'s)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
