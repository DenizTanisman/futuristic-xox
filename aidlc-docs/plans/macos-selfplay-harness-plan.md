# Plan — macOS Self-Play Test Harness (perfect-play review)

> Dev-only macOS desktop screen to watch a game under deterministic best-play. The human makes only
> the first move; from then on both sides play the adversarial **first** option to a win/draw. The
> whole game is recorded for prev/next/replay scrubbing; a background producer runs to terminal
> independent of the viewer. No win/lose banner; board persists until reset. Never in release builds.
>
> Built in a worktree off `feat/adversarial-search-difficulty-tiers` on branch
> `feat/macos-selfplay-harness`. `main` untouched.

## Confirmed findings (§2.5)

- **No Rust bridge in the Flutter app.** `flutter_rust_bridge` is not wired (only the comment in
  `pubspec.yaml`); the app talks to the pure-Dart `DartGameApi` via the `GameApi` interface. The
  work order's §1.2 names the Rust API (`adversarial_search` / `play_move` / `bridge`), but those are
  unreachable from Flutter. **Decision (§5(C)):** the harness consumes `DartGameApi` — which on this
  branch already mirrors the adversarial top-3 search + `SelectionPolicy` + `play_move`. "Perfect
  play / AlwaysBest" = the search's `first` option, exposed by a new dev-only `selfPlayStep`.
- **`DartGameApi` search is time-boxed (450 ms), hence not reproducible across machines.** The work
  order requires `time_ms: 0` + a `max_depth` cap for deterministic, reproducible records (stable
  scrubbing + the determinism test). **Decision (§5(C)):** add a dev-only, deterministic
  `selfPlayStep(maxDepth)` to `DartGameApi` that runs the existing search with the **time box off**
  (huge budget → never trips) and a depth cap, then commits the `first` move. The shipping `aiMove`
  keeps its 450 ms box unchanged — real play behaviour is not altered. `_adversarialSearch` /
  `_searchRootTop3` are parametrized by `(budgetMs, maxDepth)`; `aiMove`'s path passes the existing
  defaults.
- **`BoardView` renders any `Snapshot` read-only.** Ctor:
  `BoardView({snapshot, showValues, classic, highlightedCells, lastMoveCell, lastWasCapture, onTap,
  interactive})`. The harness passes `interactive: false`, `onTap: (_) {}`, and the per-ply snapshot —
  full fidelity with the real game. `lastMoveCell` is derived by diffing consecutive snapshots.
- **Per-ply TT is freed after each search** (a fresh `_tt.clear()` per `_adversarialSearch`), so the
  unbounded-TT issue does not accumulate across a recorded game; only a single deep search is at risk,
  bounded by the per-mode `max_depth` cap below.
- **`ui/macos` does not exist** → scaffold with `flutter create --platforms=macos .`.

## §5(C) defensive decisions (logged)

- **Backend:** harness uses `DartGameApi` (Rust bridge unavailable). Wiring Rust is separate Step-2
  work, explicitly out of scope here.
- **Determinism:** `selfPlayStep` runs time-box-off (`budgetMs = _kNoTimeBox`, a value the wall clock
  never reaches) + a per-mode `max_depth` cap → reproducible records. Caps (depth-limited best, not
  literally game-theoretic perfect on large boards, but deterministic — the property the harness needs):
  - Classic 3×3 → 9 (full solve), Classic 4×4 → 12
  - Original / Bonanza 3×3 → 9, 4×4 → 7
  - Morph 4×4 → 6, Morph 5×5 → 4  (b² per turn; capped low so a no-time-box search stays tractable)
- **Morph shape pick:** `DartGameApi.newGame` derives the shape from the seed (`Random(seed).nextInt(3)`,
  order i/l/z = 0/1/2). The harness picks I/L/Z by searching seeds `0..` for one whose `morphShape`
  matches, then uses that seed — no backend change, fully reproducible (Morph hands are seed-independent).
- **Off-thread:** the producer runs a fresh `DartGameApi` inside an `Isolate`, streaming each `Ply`
  snapshot back over a `SendPort`; the UI stays responsive during deep 5×5 searches. The driver logic
  is unit-tested on the main isolate (no isolate needed for tests).
- **Release-gating:** reachable only behind `kDebugMode`; never added to production navigation.

## Producer / viewer decoupling (core behaviour, §2.3)

- Producer (isolate): from the post-first-move state, loop `selfPlayStep(cap)` → append `Ply` →
  stream back, until terminal. Runs to the end regardless of the viewer.
- Viewer (UI): holds `viewIndex`. Auto-advances ~600 ms/ply up to the latest produced ply while
  `autoPlay`. Touching prev/next sets `autoPlay = false` (manual scrub); the producer keeps filling.
- Replay: `viewIndex = 0`, `autoPlay = true`, reuse the record (no recompute). Reset/leave: clear.
- Test env: **no win/lose banner**; board persists until reset/leave.

## Test stops

- §4.1 automated (Dart, no macOS): driver-to-terminal per mode/grid; determinism (same setup → same
  record twice); scrub logic (clamp, prev/next, auto-advance freeze, replay-no-recompute, reset);
  first-move legality; Bonanza seed reproducibility; Morph shape mapping. `flutter analyze` clean.
- 🛑 §4.2 functional (owner, macOS): the setup flow, auto-play, scrub-freezes-autoplay, replay, reset,
  no banner, Bonanza/Morph reproducibility — owner-run on macOS. (Desktop CPU ≫ phone, so this
  validates correctness/flow/look, not on-phone 450 ms strength — stated in the harness header.)
