// Dev-only self-play test harness — data types (spec: macOS self-play harness work order §2.4).
//
// NOTE: this whole `dev/` subtree is reachable only behind `kDebugMode`; it is never wired into
// production navigation and must not ship in release builds.
library;

import '../../models/game_models.dart';

/// A fully specified self-play setup: enough to rebuild the exact same recorded game deterministically
/// (same mode/grid/seed/first move/depth → identical record, because the search runs time-box-off).
/// All fields are primitives/enums so the config is trivially sendable to a producer isolate.
class SelfPlayConfig {
  final Mode4 mode;
  final int rows;
  final int cols;

  /// Bonanza: randomizes the dealt hands. Morph: selects the target shape. Ignored by Classic/Original.
  final int seed;

  /// The human's single first move. `firstColor`/`firstValue` are null for Classic (symbols).
  final int? firstColor;
  final int? firstValue;
  final int firstCell;

  /// Per-move time box in ms (0 = off → deterministic depth-only search, used by tests). The live
  /// harness uses [kSelfPlayTimeMs]; a full-depth "perfect" search is infeasible past tiny boards
  /// (Original 4×4 depth 6 ≈ 70 s), so the harness time-boxes each move.
  final int timeMs;

  /// Safety depth cap; with a time box set high so the clock governs.
  final int maxDepth;

  const SelfPlayConfig({
    required this.mode,
    required this.rows,
    required this.cols,
    required this.seed,
    required this.firstColor,
    required this.firstValue,
    required this.firstCell,
    this.timeMs = kSelfPlayTimeMs,
    this.maxDepth = 64,
  });
}

/// The harness per-move time box: 2 seconds (work order follow-up — dev_test gets a 2 s limit).
const int kSelfPlayTimeMs = 2000;

/// One recorded position: the board state to render plus the cell that just changed (for the
/// last-move highlight) and whether that move was a capture. Sendable across isolates (plain fields).
class SelfPlayFrame {
  final Snapshot snapshot;

  /// The cell of the move that produced this frame; null only for the very first frame's predecessor.
  final int? lastMoveCell;
  final bool lastWasCapture;

  const SelfPlayFrame({
    required this.snapshot,
    this.lastMoveCell,
    this.lastWasCapture = false,
  });
}

