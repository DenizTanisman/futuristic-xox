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

  /// Depth cap for the deterministic, time-box-off self-play search (see [depthCapFor]).
  final int maxDepth;

  const SelfPlayConfig({
    required this.mode,
    required this.rows,
    required this.cols,
    required this.seed,
    required this.firstColor,
    required this.firstValue,
    required this.firstCell,
    required this.maxDepth,
  });
}

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

/// Per-mode depth cap for the time-box-off self-play search (work order §5(C), logged in the plan).
/// Small boards solve fully (deterministic perfect play); larger boards are depth-limited but still
/// deterministic — the property the harness needs for reproducible scrubbing. Morph is capped low
/// because its two-move turns square the per-turn branching (≈ b²) and there is no time box to stop a
/// runaway search.
int depthCapFor(Mode4 mode, int grid) {
  switch (mode) {
    case Mode4.classic:
      return grid == 3 ? 9 : 12;
    case Mode4.original:
    case Mode4.bonanza:
      return grid == 3 ? 9 : 7;
    case Mode4.morph:
      return grid == 4 ? 6 : 4;
  }
}
