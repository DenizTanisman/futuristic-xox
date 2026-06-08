import '../models/game_models.dart';

/// The backend contract the UI talks to (spec §11 merge contract). Two implementations exist:
///
/// - [DartGameApi] — a pure-Dart mock engine + simple AI, so the UI is fully runnable today without
///   the Rust toolchain (the "mock AI" phase, spec §10.2 / §14.4).
/// - A future `RustGameApi` — flutter_rust_bridge bindings to the `bridge::GameSession`, swapping in
///   the native engine + real AI with no UI changes (spec §2; AI runs off the UI isolate for 60fps).
abstract class GameApi {
  /// Start a new game. `seed` only affects Bonanza's randomized hands (spec §4.3). `winLen` is the
  /// line length to win for Classic (3 = "short", 4 = "long" on 4×4); ignored by other modes.
  Snapshot newGame(
      {required Mode4 mode, required int rows, required int cols, int? seed, int winLen = 3});

  /// Current state.
  Snapshot snapshot();

  /// Legal target cells for a held pawn (UI highlighting). Pass `color`+`value` of the selected
  /// hand pawn; both `null` for Classic.
  List<int> legalCells({int? color, int? value});

  /// Cells where the side to move could place a held own-colour pawn to **win immediately**
  /// (complete a line, or the Morph target shape). Used as an on-board hint (spec §8 clarity).
  List<int> completingCells();

  /// Attempt a human move. For valued modes pass the selected pawn's `color` and `value`; for
  /// Classic both are `null`. Illegal → no state change + an inline reason (spec §3.3).
  MoveResult humanMove({int? color, int? value, required int cell});

  /// Have the AI move for the side to move. May run asynchronously (native search off-isolate).
  Future<MoveResult> aiMove(Difficulty difficulty);
}
