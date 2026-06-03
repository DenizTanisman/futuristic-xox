# Build Plan — Futuristic XOX

Derived from the build spec (`CLAUDE.md` §14). AI-DLC: INCEPTION (spec, done) → CONSTRUCTION → OPERATIONS (v2).

## Phase 0 — Scaffold ✅
Git repo, Cargo workspace (`engine`, `ai`), `aidlc-docs/`, `CHANGELOG.md`, `README.md`, `.gitignore`,
`CLAUDE.md`.

## Phase 1 — U1 Engine (Rust) — BUILD FIRST
State model (§6), rules (§3), capture (§3.3), win-check lines + Morph shapes (§5), mode configs (§4),
pure `apply`, two-moves-per-turn for Morph. The `Mode` trait (§7.1) is the frozen merge contract.

Headless unit tests for every rule:
- capture strict-greater; equal illegal; own-cell illegal
- capture deletes pawn permanently (not back to hand)
- win-before-draw ordering
- hands-empty → draw
- Morph shapes + all rotations/mirrors; sliding-window scan on 4×4 and 5×5
- Morph two-moves-per-turn; win-after-each-move; single-move fallback when no second move

**🛑 TEST DURAĞI gate:** none required (headless, fully automatable). Completion report after.

## Phase 2 — Freeze `Mode` trait + bridge skeleton
Lock §7.1. Stub `bridge/` for `flutter_rust_bridge` (added when Flutter is available).

## Phase 3 — U2 AI (Rust) ∥ U3 UI (Flutter)
- **U2:** easy (§7.2), medium (§7.3), hard negamax+alpha-beta (§7.4), optimizations (§7.7:
  alpha-beta, move ordering, transposition table/Zobrist, iterative deepening + time box,
  symmetry, bitboard win-check, depth limit). Heuristics (§7.6) calibrated via self-play (§13.2).
  Exposes `choose_move(state, difficulty, time_budget) -> Move`.
- **U3:** screens (§8), board, pawn rail + slide animation, capture/turn/Morph indicators, banners.
  Starts against a mock AI, then wires to U2 via the bridge.
  **🛑 TEST DURAĞI:** requires Flutter SDK install + on-device play.

## Phase 4 — Integration
Full game playable per mode through the bridge. **🛑 TEST DURAĞI:** user plays each mode on device,
confirms feel/fluidity (esp. 5×5 Morph responsiveness + 60fps animations).

## Phase 5 — Polish
Heuristic calibration finalize, OWASP checklist (§9), portfolio README. Suggest GitHub push.

## Parallelism note
Once Phase 2 freezes the interface, U2 and U3 run concurrently. Flutter not yet installed in this
environment → U3 blocks on a 🛑 install stop; U1+U2 (pure Rust) proceed fully now.
