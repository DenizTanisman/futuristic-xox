import '../models/game_models.dart';

/// The backend contract the UI talks to (spec §11 merge contract). Two implementations exist:
///
/// - [DartGameApi] — a pure-Dart mock engine + simple AI, so the UI is fully runnable today without
///   the Rust toolchain (the "mock AI" phase, spec §10.2 / §14.4).
/// - A future `RustGameApi` — flutter_rust_bridge bindings to the `bridge::GameSession`, swapping in
///   the native engine + real AI with no UI changes (spec §2; AI runs off the UI isolate for 60fps).
abstract class GameApi {
  /// Start a new game. `seed` only affects Bonanza's randomized hands (spec §4.3).
  Snapshot newGame({required Mode4 mode, required int rows, required int cols, int? seed});

  /// Current state.
  Snapshot snapshot();

  /// Legal target cells for a held pawn value (UI highlighting). Pass `null` for Classic.
  List<int> legalCells(int? value);

  /// Attempt a human move. Illegal → no state change + an inline reason (spec §3.3).
  MoveResult humanMove({int? value, required int cell});

  /// Have the AI move for the side to move. May run asynchronously (native search off-isolate).
  Future<MoveResult> aiMove(Difficulty difficulty);
}
