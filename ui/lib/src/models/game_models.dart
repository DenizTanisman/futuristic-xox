/// UI-facing game model types. These mirror the Rust `bridge` crate's view structs (`Snapshot`,
/// `MoveResult`, `Outcome`, spec §7.1/§11) so the pure-Dart mock backend and the future
/// flutter_rust_bridge backend are interchangeable behind `GameApi`.

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

/// A flat, immutable view of the full game state for rendering (mirrors `bridge::Snapshot`).
class Snapshot {
  final int rows;
  final int cols;
  final List<CellView> board;
  final List<int> hand0;
  final List<int> hand1;
  final int turn;

  /// 1 normally; for Morph, 2 then 1 within a turn (spec §8 "move 1 of 2 / 2 of 2").
  final int movesLeftInTurn;
  final Outcome outcome;

  const Snapshot({
    required this.rows,
    required this.cols,
    required this.board,
    required this.hand0,
    required this.hand1,
    required this.turn,
    required this.movesLeftInTurn,
    required this.outcome,
  });

  int get cellCount => rows * cols;
  List<int> hand(int player) => player == 0 ? hand0 : hand1;
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
