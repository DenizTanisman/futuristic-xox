import 'package:flutter/foundation.dart';

import '../audio/music_controller.dart';
import '../audio/sfx_controller.dart';
import '../game/game_api.dart';
import '../game/player_controller.dart';
import '../models/game_models.dart';

/// Localized strings the controller needs for its transient messages / result text. Injected from the
/// view so the controller stays free of hardcoded user-facing text (spec: localization).
class GameStrings {
  final String capture;
  final String noSecondMove;
  final String selectPawnFirst;
  final String draw;
  final String Function(String name) wins;

  /// The local human's label ("You") and the grammatically-correct 2nd-person win line ("You win!"),
  /// used instead of the generic 3rd-person [wins] when the human themselves wins (e.g. Turkish needs
  /// "Sen kazandın!", not "Sen kazandı!").
  final String you;
  final String youWins;

  const GameStrings({
    required this.capture,
    required this.noSecondMove,
    required this.selectPawnFirst,
    required this.draw,
    required this.wins,
    required this.you,
    required this.youWins,
  });
}

/// Drives a single game: owns the backend session, the current [Snapshot], transient UI messages,
/// and the turn loop. Each seat (0 = bottom, 1 = top) is a [PlayerController] — human or AI — so the
/// controller is agnostic to who plays: single-player, offline multiplayer, and (later) online all
/// use the same loop and only differ in the two [players] passed in.
class GameController extends ChangeNotifier {
  final GameApi api;
  final Mode4 mode;
  final int rows;
  final int cols;

  /// players[0] = bottom seat (moves first), players[1] = top seat.
  final List<PlayerController> players;

  /// Localized strings for messages / result (injected by the view).
  final GameStrings strings;

  late Snapshot snapshot;

  /// Selected hand pawn (valued modes): its colour and value. Null = nothing selected / Classic.
  int? selectedColor;
  int? selectedValue;

  /// Transient inline message (illegal move, capture, Morph fallback) shown briefly (spec §3.3, §8).
  String? message;
  bool messageIsError = false;

  /// The cell touched by the most recent applied move (placement/capture highlight).
  int? lastMoveCell;

  /// Whether the most recent applied move captured an enemy pawn (drives the capture ripple).
  bool lastWasCapture = false;

  /// True while a non-human (AI) seat is "thinking".
  bool aiThinking = false;

  bool _disposed = false;

  GameController({
    required this.api,
    required this.mode,
    required this.rows,
    required this.cols,
    required this.players,
    required this.strings,
    int? seed,
  }) {
    snapshot = api.newGame(mode: mode, rows: rows, cols: cols, seed: seed);
    // If the starting seat is non-human (future-proofing), let it play.
    Future.microtask(_runAutoPlayers);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  PlayerController get activePlayer => players[snapshot.turn];
  PlayerController playerAt(int seat) => players[seat];

  bool get isHumanTurn => activePlayer.isHuman && !snapshot.isOver;
  bool get isOver => snapshot.isOver;

  /// Banner title for the current outcome (uses player labels).
  String get resultTitle => _resultText(snapshot.outcome);

  /// Cells the currently-selected pawn (or Classic symbol) may be placed on, for highlighting.
  List<int> get highlightedCells {
    if (!isHumanTurn) return const [];
    if (mode.valued && selectedValue == null) return const [];
    return api.legalCells(
      color: mode.valued ? selectedColor : null,
      value: mode.valued ? selectedValue : null,
    );
  }

  /// Select/deselect a hand pawn by colour + value (valued modes).
  void selectPawn(int color, int value) {
    if (!isHumanTurn) return;
    if (selectedColor == color && selectedValue == value) {
      selectedColor = null;
      selectedValue = null;
    } else {
      selectedColor = color;
      selectedValue = value;
      SfxController.instance.play(SoundId.select); // Futuristic hand selection only
    }
    _clearMessage();
    notifyListeners();
  }

  Future<void> onCellTap(int cell) async {
    if (aiThinking || !isHumanTurn) return;
    if (mode.valued && selectedValue == null) {
      _setMessage(strings.selectPawnFirst, isError: true);
      return;
    }
    final result = api.humanMove(
      color: mode.valued ? selectedColor : null,
      value: mode.valued ? selectedValue : null,
      cell: cell,
    );
    if (!result.applied) {
      _setMessage(result.illegalReason ?? 'Illegal move', isError: true);
      return;
    }
    _onApplied(result);

    // Drop the selection if that pawn is no longer in the (now active) hand.
    if (mode.valued &&
        selectedValue != null &&
        !snapshot.hand(snapshot.turn).any((h) => h.color == selectedColor && h.value == selectedValue)) {
      selectedColor = null;
      selectedValue = null;
    }
    notifyListeners();

    await _runAutoPlayers();
  }

  /// Play out any consecutive non-human seats (AI) until it's a human's turn or the game ends.
  Future<void> _runAutoPlayers() async {
    if (isOver || activePlayer.isHuman) return;
    aiThinking = true;
    _safeNotify();

    while (!isOver && !activePlayer.isHuman && !_disposed) {
      final seat = activePlayer;
      final difficulty = seat is AiController ? seat.difficulty : Difficulty.medium;
      final result = await api.aiMove(difficulty);
      if (_disposed) return;
      if (!result.applied) break;
      _onApplied(result);
      _safeNotify();
    }

    aiThinking = false;
    _safeNotify();
  }

  void _onApplied(MoveResult result) {
    lastMoveCell = _firstChangedCell(snapshot, result.snapshot) ?? lastMoveCell;
    lastWasCapture = result.captured;
    snapshot = result.snapshot;

    // Audio feedback for every applied move — player AND AI (spec §2). The result fanfare layers on
    // top of the final placement; the music layer stops the ambient and resumes the lobby loop.
    SfxController.instance.play(SoundId.place);
    if (result.snapshot.isOver) {
      SfxController.instance.play(_resultSound(result.snapshot.outcome));
      MusicController.instance.endMatch();
    }

    if (result.snapshot.isOver) {
      _setMessage(_resultText(result.snapshot.outcome), isError: false);
    } else if (result.singleMoveFallback) {
      _setMessage(strings.noSecondMove, isError: false);
    } else if (result.captured) {
      _setMessage(strings.capture, isError: false);
    } else {
      _clearMessage();
    }
  }

  int? _firstChangedCell(Snapshot before, Snapshot after) {
    for (var i = 0; i < after.board.length; i++) {
      final a = before.board[i];
      final b = after.board[i];
      if (a.empty != b.empty || a.owner != b.owner || a.value != b.value) return i;
    }
    return null;
  }

  /// Result sound from the human's perspective: a human winner → win, an AI beating a human → lose,
  /// a draw → draw. With two humans (offline multiplayer) any decisive result is a win for someone.
  SoundId _resultSound(Outcome o) => switch (o) {
        Outcome.win0 => players[0].isHuman ? SoundId.win : SoundId.lose,
        Outcome.win1 => players[1].isHuman ? SoundId.win : SoundId.lose,
        Outcome.draw => SoundId.draw,
        Outcome.inProgress => SoundId.place, // unreachable (only called when over)
      };

  /// Outcome message from the winning seat's perspective (uses player labels). When the winner is the
  /// local human ("You"), use the 2nd-person line for correct grammar (e.g. TR "Sen kazandın!").
  String _resultText(Outcome o) => switch (o) {
        Outcome.win0 => _winText(0),
        Outcome.win1 => _winText(1),
        Outcome.draw => strings.draw,
        Outcome.inProgress => '',
      };

  String _winText(int seat) {
    final label = players[seat].label;
    return label == strings.you ? strings.youWins : strings.wins(label);
  }

  void _setMessage(String text, {required bool isError}) {
    message = text;
    messageIsError = isError;
  }

  void _clearMessage() {
    message = null;
    messageIsError = false;
  }
}
