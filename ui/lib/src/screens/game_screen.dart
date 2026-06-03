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

  @override
  void initState() {
    super.initState();
    controller = _build();
  }

  GameController _build() => GameController(
        api: DartGameApi(),
        mode: widget.mode,
        rows: widget.grid,
        cols: widget.grid,
        difficulty: widget.difficulty,
        seed: DateTime.now().millisecondsSinceEpoch & 0xFFFFFF,
      );

  void _playAgain() {
    setState(() => controller = _build());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode.label} · ${widget.grid}×${widget.grid}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart',
            onPressed: _playAgain,
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final s = controller.snapshot;
            final showValues = widget.mode.valued;
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Opponent (computer) rail.
                      PawnRail(
                        owner: 1,
                        hand: s.hand1,
                        showValues: showValues,
                        active: s.turn == 1 && !s.isOver,
                      ),
                      const SizedBox(height: 12),
                      TurnIndicator(
                        turn: s.turn,
                        twoMovesPerTurn: widget.mode.twoMovesPerTurn,
                        movesLeftInTurn: s.movesLeftInTurn,
                        aiThinking: controller.aiThinking,
                        isOver: s.isOver,
                      ),
                      InlineMessage(
                        message: controller.message,
                        isError: controller.messageIsError,
                      ),
                      Expanded(
                        child: Center(
                          child: BoardView(
                            snapshot: s,
                            showValues: showValues,
                            highlightedCells: controller.highlightedCells,
                            lastMoveCell: controller.lastMoveCell,
                            interactive: controller.isHumanTurn && !controller.aiThinking,
                            onTap: controller.onCellTap,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Human rail (selectable).
                      PawnRail(
                        owner: 0,
                        hand: s.hand0,
                        showValues: showValues,
                        active: controller.isHumanTurn,
                        selectedValue: controller.selectedValue,
                        onSelect: widget.mode.valued ? controller.selectValue : null,
                      ),
                    ],
                  ),
                ),
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
}
