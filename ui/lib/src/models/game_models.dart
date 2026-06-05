/// UI-facing game model types. These mirror the Rust `bridge` crate's view structs (`Snapshot`,
/// `MoveResult`, `Outcome`, spec §7.1/§11) so the pure-Dart mock backend and the future
/// flutter_rust_bridge backend are interchangeable behind `GameApi`.
library;

/// The four playable modes (spec §4).
enum Mode4 { classic, original, bonanza, morph }

extension Mode4X on Mode4 {
  String get label => switch (this) {
        Mode4.classic => 'Classic',
        Mode4.original => 'Original',
        Mode4.bonanza => 'Bonanza',
        Mode4.morph => 'Morph',
      };

  /// Whether pawns carry values and can capture (spec §3.3). Classic does not.
  bool get valued => this != Mode4.classic;

  /// Two moves per turn (spec §4.4).
  bool get twoMovesPerTurn => this == Mode4.morph;

  /// Allowed grid sizes (as side length) for this mode (spec §8).
  List<int> get grids => this == Mode4.morph ? const [4, 5] : const [3, 4];
}

enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };
}

/// Terminal status of a game (mirrors `bridge::Outcome`).
enum Outcome { inProgress, win0, win1, draw }

/// The three Morph target shapes (spec §5). In Morph, one is chosen at game start and shown to the
/// players; the win is to complete that shape in any rotation / mirror / position.
enum MorphShape { i, l, z }

extension MorphShapeX on MorphShape {
  String get letter => switch (this) {
        MorphShape.i => 'I',
        MorphShape.l => 'L',
        MorphShape.z => 'Z',
      };

  /// Relative `(row, col)` cells of the shape in its base orientation, for a small preview.
  List<List<int>> get previewCells => switch (this) {
        MorphShape.i => const [
            [0, 0],
            [0, 1],
            [0, 2],
            [0, 3]
          ],
        MorphShape.l => const [
            [0, 0],
            [1, 0],
            [2, 0],
            [2, 1]
          ],
        MorphShape.z => const [
            [0, 1],
            [0, 2],
            [1, 0],
            [1, 1]
          ],
      };
}

/// A single board cell view.
class CellView {
  final int owner;
  final int value;
  final bool empty;
  const CellView({required this.owner, required this.value, required this.empty});

  const CellView.empty()
      : owner = 0,
        value = 0,
        empty = true;
}

/// A pawn held in hand. `color` is the pawn's owner-colour once placed — equal to the holding player
/// in every mode EXCEPT Bonanza, where a player may hold opponent-coloured pawns (spec §4.3).
class HandPawnView {
  final int color;
  final int value;
  const HandPawnView({required this.color, required this.value});
}

/// A flat, immutable view of the full game state for rendering (mirrors `bridge::Snapshot`).
class Snapshot {
  final int rows;
  final int cols;
  final List<CellView> board;
  final List<HandPawnView> hand0;
  final List<HandPawnView> hand1;
  final int turn;

  /// 1 normally; for Morph, 2 then 1 within a turn (spec §8 "move 1 of 2 / 2 of 2").
  final int movesLeftInTurn;
  final Outcome outcome;

  /// Bonanza only: how many of player 0's pawns are their own colour (shown briefly at start).
  final int? bonanzaOwnCount;

  /// Morph only: the chosen target shape (shown at start).
  final MorphShape? morphShape;

  /// The cells of the winning group when [outcome] is a win (3-in-a-row, or the 4-cell Morph shape);
  /// empty otherwise. Unordered — order into a path with `orderWinPath` for the win-line overlay.
  final List<int> winningCells;

  const Snapshot({
    required this.rows,
    required this.cols,
    required this.board,
    required this.hand0,
    required this.hand1,
    required this.turn,
    required this.movesLeftInTurn,
    required this.outcome,
    this.bonanzaOwnCount,
    this.morphShape,
    this.winningCells = const [],
  });

  int get cellCount => rows * cols;
  List<HandPawnView> hand(int player) => player == 0 ? hand0 : hand1;
  bool get isOver => outcome != Outcome.inProgress;
}

/// Result of attempting a move (mirrors `bridge::MoveResult`).
class MoveResult {
  final bool applied;
  final bool captured;
  final bool singleMoveFallback;
  final String? illegalReason;
  final Snapshot snapshot;

  const MoveResult({
    required this.applied,
    required this.captured,
    required this.singleMoveFallback,
    required this.illegalReason,
    required this.snapshot,
  });
}
