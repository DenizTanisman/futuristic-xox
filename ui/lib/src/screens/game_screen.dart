import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../audio/music_controller.dart';
import '../audio/sfx_controller.dart';
import '../controllers/game_controller.dart';
import '../game/dart_game_api.dart';
import '../game/player_controller.dart';
import '../models/game_models.dart';
import '../theme/game_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/pawn_rail.dart';
import '../widgets/status_widgets.dart';

/// The main game screen (spec §8.4): board, both pawn rails (seat 0 at the bottom), turn/Morph
/// indicators, inline messages, and the win/lose/draw banner. Seats are [PlayerController]s, so the
/// same screen serves single-player (vs AI) and offline multiplayer (two humans). All text is
/// localized; the controller is created with localized labels + a [GameStrings] bundle.
class GameScreen extends StatefulWidget {
  final Mode4 mode;
  final int grid;
  final Difficulty difficulty;

  /// Line length to win for Classic (3 = "short", 4 = "long" on 4×4); ignored by other modes.
  final int winLen;

  /// Offline multiplayer: both seats are human (no AI). When false, seat 1 is the AI.
  final bool multiplayer;

  const GameScreen({
    super.key,
    required this.mode,
    required this.grid,
    required this.difficulty,
    this.winLen = 3,
    this.multiplayer = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController? controller;
  bool _showIntro = false;
  Timer? _introTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controller once, here, where AppLocalizations is available so player labels and
    // messages start localized. (A later locale switch relabels the next game, not the live one.)
    controller ??= _build();
  }

  GameController _build() {
    final l = AppLocalizations.of(context)!;
    final players = widget.multiplayer
        ? [HumanController(l.player1), HumanController(l.player2)]
        : [HumanController(l.playerYou), AiController(widget.difficulty, label: l.playerComputer)];
    final c = GameController(
      api: DartGameApi(),
      mode: widget.mode,
      rows: widget.grid,
      cols: widget.grid,
      winLen: widget.winLen,
      players: players,
      strings: GameStrings(
        capture: l.captureMsg,
        noSecondMove: l.noSecondMove,
        selectPawnFirst: l.selectPawnFirst,
        draw: l.resultDraw,
        wins: (name) => l.resultWins(name),
        you: l.playerYou,
        youWins: l.resultYouWin,
      ),
      seed: DateTime.now().millisecondsSinceEpoch & 0xFFFFFF,
    );
    _introTimer?.cancel();
    if (widget.mode == Mode4.bonanza && c.snapshot.bonanzaOwnCount != null) {
      _showIntro = true;
      _introTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showIntro = false);
      });
    } else {
      _showIntro = false;
    }
    // A match begins: the start cue (SFX) + the music transition (fade lobby out, quiet ambient in).
    SfxController.instance.play(SoundId.matchStart);
    MusicController.instance.startMatch();
    return c;
  }

  void _playAgain() {
    setState(() {
      controller?.dispose();
      controller = _build();
    });
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    controller?.dispose();
    // Leaving the match (back to the menus) → resume the lobby music loop.
    MusicController.instance.enterLobby();
    super.dispose();
  }

  String _modeName(AppLocalizations l) => switch (widget.mode) {
        Mode4.classic => l.modeClassic,
        Mode4.original => l.modeOriginal,
        Mode4.bonanza => l.modeBonanza,
        Mode4.morph => l.modeMorph,
      };

  @override
  Widget build(BuildContext context) {
    final showValues = widget.mode.valued;
    final classic = widget.mode == Mode4.classic;
    final theme = classic ? GameTheme.classic : GameTheme.futuristic;
    final l = AppLocalizations.of(context)!;
    final c = controller!;
    return GameThemeProvider(
      theme: theme,
      child: Container(
        decoration: BoxDecoration(gradient: theme.background),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              '${_modeName(l)} · ${widget.grid}×${widget.grid}',
              style: theme.display(18, color: theme.ink),
            ),
            iconTheme: IconThemeData(color: theme.muted),
            leading: IconButton(
              icon: const BackButtonIcon(),
              onPressed: () {
                SfxController.instance.play(SoundId.menuBack);
                Navigator.of(context).maybePop();
              },
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), tooltip: l.restart, onPressed: _playAgain),
            ],
          ),
          body: SafeArea(
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) {
                final s = c.snapshot;
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (!classic) ...[
                            PawnRail(
                              owner: 1,
                              label: c.playerAt(1).label,
                              hand: s.hand1,
                              showValues: showValues,
                              classic: classic,
                              active: s.turn == 1 && !s.isOver,
                              selectedColor: s.turn == 1 ? c.selectedColor : null,
                              selectedValue: s.turn == 1 ? c.selectedValue : null,
                              onSelect: widget.mode.valued && c.isHumanTurn && s.turn == 1
                                  ? c.selectPawn
                                  : null,
                            ),
                            const SizedBox(height: 10),
                          ],
                          TurnIndicator(
                            turn: s.turn,
                            label: c.activePlayer.label,
                            moveText: widget.mode.twoMovesPerTurn ? l.moveOfTwo(3 - s.movesLeftInTurn) : null,
                            aiThinking: c.aiThinking,
                            isOver: s.isOver,
                          ),
                          if (s.morphShape != null) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: MorphShapeBadge(
                                shape: s.morphShape!,
                                targetLabel: l.target,
                                anyRotationLabel: l.anyRotation,
                              ),
                            ),
                          ],
                          InlineMessage(message: c.message, isError: c.messageIsError),
                          Expanded(
                            child: Center(
                              child: BoardView(
                                snapshot: s,
                                showValues: showValues,
                                classic: classic,
                                highlightedCells: c.highlightedCells,
                                lastMoveCell: c.lastMoveCell,
                                lastWasCapture: c.lastWasCapture,
                                interactive: c.isHumanTurn && !c.aiThinking,
                                onTap: c.onCellTap,
                              ),
                            ),
                          ),
                          if (!classic) ...[
                            const SizedBox(height: 10),
                            PawnRail(
                              owner: 0,
                              label: c.playerAt(0).label,
                              hand: s.hand0,
                              showValues: showValues,
                              classic: classic,
                              active: s.turn == 0 && !s.isOver,
                              selectedColor: s.turn == 0 ? c.selectedColor : null,
                              selectedValue: s.turn == 0 ? c.selectedValue : null,
                              onSelect: widget.mode.valued && c.isHumanTurn && s.turn == 0
                                  ? c.selectPawn
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_showIntro && s.bonanzaOwnCount != null)
                      Positioned.fill(child: _bonanzaIntro(context, l, s.bonanzaOwnCount!, s.hand0.length)),
                    if (s.isOver)
                      Positioned.fill(
                        child: ResultBanner(
                          outcome: s.outcome,
                          title: c.resultTitle,
                          menuLabel: l.menuButton,
                          playAgainLabel: l.playAgain,
                          onPlayAgain: _playAgain,
                          onMenu: () {
                            SfxController.instance.play(SoundId.menuBack);
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _bonanzaIntro(BuildContext context, AppLocalizations l, int ownCount, int total) {
    final theme = GameTheme.of(context);
    return IntroOverlay(
      title: l.yourHand,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$ownCount', style: theme.display(44, color: theme.accent)),
          const SizedBox(height: 6),
          Text(
            l.bonanzaHandLine(ownCount, total, total - ownCount),
            textAlign: TextAlign.center,
            style: theme.label(15, color: theme.ink),
          ),
        ],
      ),
    );
  }
}
