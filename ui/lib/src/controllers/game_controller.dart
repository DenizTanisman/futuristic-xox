import 'package:flutter/foundation.dart';

import '../game/game_api.dart';
import '../game/player_controller.dart';
import '../models/game_models.dart';

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

  late Snapshot snapshot;

  /// Selected hand pawn (valued modes): its colour and value. Null = nothing selected / Classic.
  int? selectedColor;
  int? selectedValue;

  /// Transient inline message (illegal move, capture, Morph fallback) shown briefly (spec §3.3, §8).
  String? message;
  bool messageIsError = false;

  /// The cell touched by the most recent applied move (placement/capture highlight).
  int? lastMoveCell;

  /// True while a non-human (AI) seat is "thinking".
  bool aiThinking = false;

  bool _disposed = false;

  GameController({
    required this.api,
    required this.mode,
    required this.rows,
    required this.cols,
    required this.players,
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
    }
    _clearMessage();
    notifyListeners();
  }

  Future<void> onCellTap(int cell) async {
    if (aiThinking || !isHumanTurn) return;
    if (mode.valued && selectedValue == null) {
      _setMessage('Select a pawn first', isError: true);
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
    snapshot = result.snapshot;

    if (result.snapshot.isOver) {
      _setMessage(_resultText(result.snapshot.outcome), isError: false);
    } else if (result.singleMoveFallback) {
      _setMessage('No second move available — turn passes', isError: false);
    } else if (result.captured) {
      _setMessage('Capture!', isError: false);
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

  /// Outcome message from the winning seat's perspective (uses player labels).
  String _resultText(Outcome o) => switch (o) {
        Outcome.win0 => '${players[0].label} wins!',
        Outcome.win1 => '${players[1].label} wins!',
        Outcome.draw => 'Draw',
        Outcome.inProgress => '',
      };

  void _setMessage(String text, {required bool isError}) {
    message = text;
    messageIsError = isError;
  }

  void _clearMessage() {
    message = null;
    messageIsError = false;
  }
}
