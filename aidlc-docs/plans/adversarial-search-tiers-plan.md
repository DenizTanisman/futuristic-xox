# Plan — Adversarial Search (top-3) + Per-Side Difficulty Tiers

> Work order: replace the single-best Hard engine with an adversarial search that returns the
> **top-3 ranked moves** (`first ≥ second ≥ third`), and add **per-side difficulty tiers** that pick
> which option (or the legacy random move) to play each turn. Crate in scope: `ai/`. Engine is frozen.

## Confirmed findings (INCEPTION §2.4 — reverse-engineering the current surface)

Re-read before construction:

- **`ai/src/hard.rs`** — `Searcher { mode, zobrist, tt, deadline, nodes, timed_out }`, `negamax`
  (alpha-beta + TT + Morph no-negation-on-same-player), `search_root` (full-width, single best),
  `hard_move` (iterative deepening + time box, discards a timed-out depth). **The root
  (`search_root` / `hard_move`) is the only place that selects among root moves** — confirmed. The
  interior `negamax`, the TT, the negation-on-turn-flip rule, and the time box are reusable as-is.
- **`ai/src/lib.rs`** — `Difficulty { Easy, Medium, Hard }`, `choose_move`, `MediumState`
  (Easy/Hard anti-streak coin) + `choose_move_medium`. All of this is the **old** selection layer to
  be removed; superseded by `SelectionPolicy` + `play_move`.
- **`ai/src/easy.rs`** — `easy_move(mode, state, &mut Rng) -> Option<Move>` is self-contained and
  takes `&mut Rng`. It is repurposed as the `rastgele()` primitive and **kept** (not deleted).
- **`ai/src/hash.rs`** — Zobrist; unchanged (out of scope; the unbounded-TT issue is separate work).
- **Engine API** — `Rng::below(n)` (uniform `[0, n)`), `Rng::new(seed)`, `Rng::next_u64`,
  `mode.ordered_moves`, `mode.legal_moves` all present and already used. `Move` is
  `Copy + PartialEq + Eq + Hash`. `INF = i32::MAX`, `WIN = 1000`.

## Owner decisions captured

- Spec/mapping confirmed.
- **No anti-streak guard** on the new selectors — the mixes provide enough variety. `play_move` stays
  stateless.

## Construction outline

1. `hard.rs` → `adversarial.rs`: keep `Searcher`/`negamax`/TT/time box; add `AdversarialChoice`;
   replace `search_root` with a **top-3 root** (top-k alpha-beta, `alpha = 3rd-best`); replace
   `hard_move` with `adversarial_search(...) -> Option<AdversarialChoice>` (single-move shortcut,
   iterative deepening keeping the last completed depth, padding per never-None invariant).
2. `lib.rs`: `SelectionPolicy { AlwaysBest, Top3Uniform, MidMix, LowMix }`; per-side label enums
   `FuturisticDifficulty`/`ClassicDifficulty` + `to_policy()` (makes `Classic + Impossible`
   unrepresentable); stateless `play_move` with **roll-first** efficiency (weaker tiers skip the
   search when the die picks `rastgele()`). Remove `Difficulty`/`MediumState`/`choose_move*`.
3. `bridge/` (§7(C) defensive — see log): minimal update so the workspace still compiles —
   `GameSession::ai_move` now takes a `SelectionPolicy` and calls `play_move`; the `MediumState`
   field is dropped. Logged because §1.2 scopes bridge out, but a non-compiling workspace is
   unacceptable and §3.2's per-side enums belong at this boundary.
4. Tests (§6.1) + CHANGELOG + ADR.

## Test stops

- §6.1 automated tests must be green (never-None, ordering, padding, regression-on-`first`, mapping,
  determinism, selection ranges, R-path), engine tests green, clippy/fmt clean — before any merge.
- 🛑 §6.2 device test is owner-run. **Caveat:** the shipping Flutter app currently runs the pure-Dart
  backend (`DartGameApi`); the native Rust AI is not wired in yet, so this Rust work is not yet
  exercised on device. The device test applies once the Rust integration (separate work) lands, or to
  a Dart mirror of these tiers (downstream).
