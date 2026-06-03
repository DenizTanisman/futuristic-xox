import 'package:flutter/foundation.dart';

import '../game/game_api.dart';
import '../models/game_models.dart';

/// Drives a single game: owns the backend session, the current [Snapshot], transient UI messages,
/// and the human↔AI turn orchestration. Human is player 0; the AI is player 1.
///
/// Backend-agnostic: it talks only to [GameApi], so swapping the Dart mock for the native Rust
/// backend needs no controller changes (spec §11).
class GameController extends ChangeNotifier {
  final GameApi api;
  final Mode4 mode;
  final int rows;
  final int cols;
  final Difficulty difficulty;

  late Snapshot snapshot;

  /// Selected hand pawn (valued modes): its colour and value. Null = nothing selected / Classic.
  /// Colour matters in Bonanza, where the human may hold pawns of either colour (spec §4.3).
  int? selectedColor;
  int? selectedValue;

  /// Transient inline message (illegal move, capture, Morph fallback) shown briefly (spec §3.3, §8).
  String? message;
  bool messageIsError = false;

  /// The cell touched by the most recent applied move (drives placement/capture highlight).
  int? lastMoveCell;

  /// True while the AI is "thinking" (search running) — disables input, shows an indicator.
  bool aiThinking = false;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  GameController({
    required this.api,
    required this.mode,
    required this.rows,
    required this.cols,
    required this.difficulty,
    int? seed,
  }) {
    snapshot = api.newGame(mode: mode, rows: rows, cols: cols, seed: seed);
  }

  bool get isHumanTurn => snapshot.turn == 0 && !snapshot.isOver;
  bool get isOver => snapshot.isOver;

  /// Cells the currently-selected pawn (or Classic symbol) may be placed on, for highlighting.
  List<int> get highlightedCells {
    if (!isHumanTurn) return const [];
    if (mode.valued && selectedValue == null) return const [];
    return api.legalCells(color: mode.valued ? selectedColor : null, value: mode.valued ? selectedValue : null);
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

    // If the selected pawn is no longer in hand, clear the selection.
    if (mode.valued &&
        selectedValue != null &&
        !snapshot.hand0.any((h) => h.color == selectedColor && h.value == selectedValue)) {
      selectedColor = null;
      selectedValue = null;
    }
    notifyListeners();

    await _runAiIfNeeded();
  }

  Future<void> _runAiIfNeeded() async {
    if (isOver || snapshot.turn != 1) return;
    aiThinking = true;
    _safeNotify();

    // Morph gives the AI up to two moves; keep playing until the turn returns to the human or the
    // game ends.
    while (snapshot.turn == 1 && !snapshot.isOver && !_disposed) {
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
    // The backend result doesn't echo the cell, so diff the board to find what changed (board is
    // tiny). This drives the placement/capture highlight for both human and AI moves.
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

  String _resultText(Outcome o) => switch (o) {
        Outcome.win0 => 'You win!',
        Outcome.win1 => 'Computer wins',
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
