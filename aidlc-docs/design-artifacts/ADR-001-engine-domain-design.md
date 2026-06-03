# ADR-001 — Engine Domain Design (U1)

Status: Accepted · Date: 2026-06-03 · Scope: `engine/` crate (Unit 1)

## Context
The engine is the pure, platform-independent core (spec §2, §6, §7.1). It must be unit-testable
headless, reusable for the v2 server, and expose the frozen `Mode` trait that Units 2 (AI) and 3 (UI)
build against.

## Decisions

### D1 — State model matches spec §6 verbatim
`Pawn { owner: u8, value: u8 }`, `GameState { board, hands, turn, moves_left_in_turn, cols, rows }`,
`Move { value: Option<u8>, cell }`. The spec's `enum Result` is named **`GameResult`** in code to avoid
shadowing `std::result::Result`; semantics are identical (`Win(u8) | Draw`).

### D2 — `apply` is pure (spec §6)
`apply(&self, &GameState, &Move) -> GameState` clones, never mutates input. This structurally prevents
the classic "forgot to undo the move" search bug.

### D3 — Turn advancement & Morph two-moves-per-turn
`moves_left_in_turn` starts at the mode's moves-per-turn (1 for line modes, 2 for Morph). `apply`
decrements it and flips `turn` only when it reaches 0 (spec §6, §4.4).
**Single-move fallback (spec §4.4):** if, mid-turn, the same player has no legal second move, `apply`
consumes the remaining move and flips the turn. The UI detects this (turn flipped after one Morph move)
to show its message.

### D4 — `is_terminal` = win-before-draw, unified draw rule (spec §3.4)
Check for a completed line/shape first → `Win(owner)`. Otherwise, if the side to move has **no legal
move**, return `Draw`. For line modes "no legal move" coincides with "both hands empty"; this single
rule also covers the rare board-full-no-capture case. Only the player who just moved can complete a
line/shape (you place only your own pawns; captures only remove enemy pawns), so a full-board scan that
returns the first owned line/shape is correct.

### D5 — Capture (spec §3.3)
Empty → any hand value. Enemy cell → only a **strictly greater** value (captures, enemy pawn deleted
permanently, not returned to hand). Equal/own → illegal. Captured pawns are overwritten in `apply`.

### D6 — Win lines & Morph shapes precomputed at construction
- **Line modes:** all length-3 segments (h/v/both diagonals) via a sliding window; same code for 3×3,
  4×4, 5×5 (spec §3.4 — "3 in a row, all grids").
- **Morph:** base shapes `I, L, Z` defined once as relative cells (spec §5); derive 4 rotations + mirror,
  dedupe, then slide over every valid placement. Straight I included in all 4 orientations; the pure
  corner-to-corner diagonal is **excluded** (it is a line, not the I tetromino). Final chosen sets are
  logged in `design-artifacts/morph-shapes.md` during implementation.

### D7 — Mode structs
- `LineMode { valued: bool }` covers **Classic** (`valued=false`: symbols, no values/capture, moves =
  empty cells) and **Original/Bonanza** (`valued=true`: one shared impl, valued + capture). Bonanza is
  Original with a randomized initial hand (spec §4.3) — same engine, different start state only.
- `MorphMode` reuses valued move/capture/apply; win/heuristic use shape completion; two moves per turn.

### D8 — Deterministic RNG in-crate
A small seedable SplitMix64 PRNG (`rng.rs`) — no external deps — powers Bonanza hand randomization and
(later) the Easy AI, so tests are reproducible by seed.

### D9 — Heuristic & ordering live in the engine, tunable in U2
`heuristic` and `ordered_moves` ship with the spec §7.6 starting weights as named constants; U2
recalibrates via self-play (open item §13.2). Engine ordering is static (captures via MVV-LVA, then
completing moves, then center); U2 layers killer/history on top.

## Consequences
- Pure functions + precomputed line/shape tables → fast, deterministic, fully headless-testable.
- AI (U2) depends only on `Mode` + `GameState`; UI (U3) depends only on `apply`/`legal_moves`/
  `is_terminal` + the AI's `choose_move`.
- `GameResult` naming is the only deviation from the literal spec; behavior is identical.
